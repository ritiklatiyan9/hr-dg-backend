-- Fixed aggregate tools, with the same per-employee intersection as attendance.
CREATE FUNCTION app.analytics_workload(tool text,date_from date,date_to date) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE org uuid:=app.org_id();site uuid:=app.site_id();tz text;eligible uuid[];result jsonb;source_key text;
BEGIN
 source_key:=CASE tool WHEN 'tasks' THEN 'tasks.view' WHEN 'dwr' THEN 'dwr_review.view' ELSE NULL END;
 IF source_key IS NULL OR NOT app.has_site(site) OR NOT app.allowed('analytics.view') OR NOT app.allowed(source_key) THEN
  RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';END IF;
 SELECT timezone INTO tz FROM app.sites WHERE organization_id=org AND id=site;
 IF date_from IS NULL OR date_to IS NULL OR date_to<date_from OR date_to-date_from>365 OR date_to>(now() AT TIME ZONE tz)::date THEN
  RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='22023';END IF;
 SELECT coalesce(array_agg(e.id),'{}') INTO eligible FROM app.employees e WHERE e.organization_id=org AND app.allowed('analytics.view',e.id) AND app.allowed(source_key,e.id)
  AND (tool<>'dwr' OR app.allowed('attendance.view',e.id) OR app.allowed('my_attendance.view',e.id));
 IF tool='tasks' THEN
  SELECT jsonb_build_object('total',count(*),'pending',count(*) FILTER(WHERE status<>'done'),'overdue',count(*) FILTER(WHERE status<>'done' AND deadline<now())) INTO result
  FROM app.work_tasks WHERE organization_id=org AND site_id=site AND employee_id=ANY(eligible)
   AND deadline>=date_from::timestamp AT TIME ZONE tz AND deadline<(date_to+1)::timestamp AT TIME ZONE tz;
 ELSE
  WITH expected AS (
   SELECT r.employee_id,r.work_date FROM app.shift_rosters r JOIN app.dwr_settings cfg ON cfg.organization_id=org AND cfg.site_id=site
   WHERE r.organization_id=org AND r.site_id=site AND r.employee_id=ANY(eligible) AND r.work_date BETWEEN date_from AND date_to
    AND ((r.work_date+cfg.deadline_day_offset)+cfg.deadline) AT TIME ZONE tz<now()
  ) SELECT jsonb_build_object('expected',count(*),'submitted',count(*) FILTER(WHERE d.status IN('submitted','approved')),
   'overdue',count(*) FILTER(WHERE d.id IS NULL OR d.status NOT IN('submitted','approved'))) INTO result
  FROM expected e LEFT JOIN app.dwr_reports d ON d.organization_id=org AND d.site_id=site AND d.employee_id=e.employee_id AND d.work_date=e.work_date;
 END IF;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION app.analytics_workload(text,date,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.analytics_workload(text,date,date) TO hr_runtime;
