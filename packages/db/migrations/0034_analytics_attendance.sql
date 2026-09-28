-- A narrow aggregate boundary avoids re-evaluating recursive permissions for
-- every raw sample. Runtime remains non-owner/non-BYPASSRLS. This function
-- returns no employee rows; it intersects both permissions once per employee,
-- binds every relation to the verified transaction's organization/site, and
-- accepts dates only. No dynamic SQL or caller-provided actor/site exists.
CREATE FUNCTION app.analytics_attendance(date_from date,date_to date) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE org uuid:=app.org_id(); site uuid:=app.site_id(); tz text; lo timestamptz; hi timestamptz;
 eligible uuid[]; roster jsonb; hours jsonb; pending int;
BEGIN
 IF NOT app.has_site(site) OR NOT app.allowed('analytics.view') OR NOT app.allowed('attendance.view') THEN
  RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT timezone INTO tz FROM app.sites WHERE organization_id=org AND id=site;
 IF date_from IS NULL OR date_to IS NULL OR date_to<date_from OR date_to-date_from>365 OR date_to>(now() AT TIME ZONE tz)::date THEN
  RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='22023'; END IF;
 lo:=date_from::timestamp AT TIME ZONE tz;hi:=(date_to+1)::timestamp AT TIME ZONE tz;
 SELECT coalesce(array_agg(e.id),'{}') INTO eligible FROM app.employees e
 WHERE e.organization_id=org AND app.allowed('analytics.view',e.id) AND app.allowed('attendance.view',e.id);
 WITH shifts AS MATERIALIZED (
  SELECT r.* FROM app.shift_rosters r WHERE r.organization_id=org AND r.site_id=site
   AND r.work_date BETWEEN date_from AND date_to AND r.employee_id=ANY(eligible)
 ), observed AS MATERIALIZED (
  SELECT s.*,p.rules FROM app.duty_sessions s JOIN app.operation_policies p
   ON p.organization_id=org AND p.site_id=site AND p.version=s.policy_version
  WHERE s.organization_id=org AND s.site_id=site AND s.opened_at>=lo AND s.opened_at<hi AND s.employee_id=ANY(eligible)
 ), paired AS (
  SELECT r.id,r.starts_at,r.ends_at,min(s.opened_at) first_in,max(s.closed_at) last_out,
   min((s.rules->>'lateGraceMinutes')::int) late_grace,min((s.rules->>'earlyGraceMinutes')::int) early_grace
  FROM shifts r LEFT JOIN observed s ON s.employee_id=r.employee_id AND (s.opened_at AT TIME ZONE tz)::date=r.work_date
  GROUP BY r.id,r.starts_at,r.ends_at
 ) SELECT jsonb_build_object('rostered',count(*),'observed',count(*) FILTER(WHERE first_in IS NOT NULL),
  'unobserved',count(*) FILTER(WHERE first_in IS NULL),'late',count(*) FILTER(WHERE first_in>starts_at+late_grace*interval '1 minute'),
  'early',count(*) FILTER(WHERE last_out<ends_at-early_grace*interval '1 minute')) INTO roster FROM paired;
 WITH candidates AS MATERIALIZED (
  SELECT DISTINCT s.duty_id FROM app.duty_segments s WHERE s.organization_id=org AND s.site_id=site
   AND s.ends_at>lo AND s.starts_at<hi AND s.employee_id=ANY(eligible)
 ), latest AS MATERIALIZED (
  SELECT c.duty_id,(SELECT max(s.revision) FROM app.duty_segments s WHERE s.organization_id=org AND s.site_id=site AND s.duty_id=c.duty_id) revision FROM candidates c
 ), sums AS (
  SELECT s.kind,floor(sum(extract(epoch FROM least(s.ends_at,hi)-greatest(s.starts_at,lo))))::text seconds
  FROM app.duty_segments s JOIN latest l USING(duty_id,revision)
  WHERE s.organization_id=org AND s.site_id=site AND s.employee_id=ANY(eligible) AND s.ends_at>lo AND s.starts_at<hi GROUP BY s.kind
 ) SELECT coalesce(jsonb_agg(to_jsonb(sums)),'[]') INTO hours FROM sums;
 SELECT count(*) INTO pending FROM app.event_verifications v JOIN app.duty_events e
  ON e.organization_id=org AND e.site_id=site AND e.id=v.event_id
  WHERE v.organization_id=org AND v.site_id=site AND v.employee_id=ANY(eligible)
   AND v.status='pending_verification' AND e.received_at>=lo AND e.received_at<hi;
 RETURN jsonb_build_object('roster',roster,'hours',hours,'pending',pending);
END $$;
REVOKE ALL ON FUNCTION app.analytics_attendance(date,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.analytics_attendance(date,date) TO hr_runtime;
