-- Dashboard attendance explains itself: who is rostered but not checked in,
-- open sessions whose exit was never recorded, and live location sharing
-- (employee_tracking.view only), which is location evidence, not attendance.
CREATE OR REPLACE FUNCTION app.dashboard_facts() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE org uuid:=app.org_id(); site uuid:=app.site_id(); tz text; today date;
 lo timestamptz; hi timestamptz; since timestamptz; staff uuid[];
 ppl uuid[]; att uuid[]; lv uuid[]; tk uuid[]; dw uuid[]; trk uuid[]; seen uuid[]; stale int;
 people jsonb; attendance jsonb; leave jsonb; tasks jsonb; dwr jsonb; location jsonb;
BEGIN
 IF site IS NULL OR NOT app.has_site(site) THEN
  RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT timezone INTO tz FROM app.sites WHERE organization_id=org AND id=site;
 today:=(now() AT TIME ZONE tz)::date;
 lo:=today::timestamp AT TIME ZONE tz; hi:=(today+1)::timestamp AT TIME ZONE tz;
 since:=(today-13)::timestamp AT TIME ZONE tz;
 -- Every record-level decision requires a site assignment, so this is a superset.
 SELECT coalesce(array_agg(DISTINCT employee_id),'{}') INTO staff
  FROM app.site_assignments WHERE organization_id=org AND site_id=site;
 IF app.allowed('employees.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO ppl FROM unnest(staff) e WHERE app.allowed('employees.view',e); END IF;
 IF app.allowed('attendance.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO att FROM unnest(staff) e WHERE app.allowed('attendance.view',e); END IF;
 IF app.allowed('leave.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO lv FROM unnest(staff) e WHERE app.allowed('leave.view',e); END IF;
 IF app.allowed('tasks.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO tk FROM unnest(staff) e WHERE app.allowed('tasks.view',e); END IF;
 IF app.allowed('dwr_review.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO dw FROM unnest(staff) e WHERE app.allowed('dwr_review.view',e); END IF;
 -- Only people who shared location today need a tracking decision.
 IF app.allowed('employee_tracking.view') THEN
  SELECT coalesce(array_agg(e),'{}') INTO trk FROM (
   SELECT DISTINCT t.employee_id e FROM app.tracking_samples t
   WHERE t.organization_id=org AND t.site_id=site AND t.observed_at>=lo AND t.observed_at<hi AND t.received_at>=lo-interval '1 day') x
  WHERE e=ANY(staff) AND app.allowed('employee_tracking.view',e); END IF;

 IF ppl IS NOT NULL THEN
  WITH cur AS (SELECT DISTINCT a.employee_id id FROM app.site_assignments a JOIN unnest(ppl) p(id) ON p.id=a.employee_id
    WHERE a.organization_id=org AND a.site_id=site AND a.starts_on<=today AND (a.ends_on IS NULL OR a.ends_on>=today)),
   dept AS (SELECT CASE WHEN app.field_allowed('employment',e.id) THEN coalesce(nullif(e.department,''),'Unassigned') ELSE 'Not visible' END AS name
    FROM app.employees e JOIN cur ON cur.id=e.id WHERE e.organization_id=org)
  SELECT jsonb_build_object(
   'headcount',(SELECT count(*) FROM cur),
   'joining',(SELECT count(DISTINCT a.employee_id) FROM app.site_assignments a JOIN unnest(ppl) p(id) ON p.id=a.employee_id
     WHERE a.organization_id=org AND a.site_id=site AND a.starts_on>today AND a.starts_on<=today+30
     AND NOT EXISTS(SELECT 1 FROM cur WHERE cur.id=a.employee_id)),
   'departments',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',name,'count',n) ORDER BY n DESC,name),'[]')
     FROM (SELECT name,count(*) n FROM dept GROUP BY name) d)) INTO people;
 END IF;

 IF att IS NOT NULL THEN
  SELECT coalesce(array_agg(DISTINCT s.employee_id),'{}') INTO seen FROM app.duty_sessions s JOIN unnest(att) p(id) ON p.id=s.employee_id
   WHERE s.organization_id=org AND s.site_id=site AND s.opened_at>=lo AND s.opened_at<hi;
  SELECT jsonb_build_object(
   'rostered',(SELECT count(*) FROM app.shift_rosters r JOIN unnest(att) p(id) ON p.id=r.employee_id
     WHERE r.organization_id=org AND r.site_id=site AND r.work_date=today),
   'checkedIn',cardinality(seen),
   'onDuty',(SELECT count(*) FROM app.duty_sessions s JOIN unnest(att) p(id) ON p.id=s.employee_id
     WHERE s.organization_id=org AND s.site_id=site AND s.status='open'
     AND s.opened_at+coalesce((SELECT (op.rules->>'maxSessionHours')::int FROM app.operation_policies op
       WHERE op.organization_id=org AND op.site_id=site AND op.version=s.policy_version),24)*interval '1 hour'>now()),
   'pendingVerification',(SELECT count(*) FROM app.event_verifications v JOIN unnest(att) p(id) ON p.id=v.employee_id
     WHERE v.organization_id=org AND v.site_id=site AND v.status='pending_verification'),
   -- Rostered today without a duty session opened today. Names follow the
   -- directory permission; others are listed without a name.
   'notCheckedIn',(SELECT jsonb_build_object('count',count(*),'people',coalesce(jsonb_agg(jsonb_build_object(
      'name',CASE WHEN x.employee_id=ANY(ppl) THEN x.name END,'startsAt',x.starts_at,'endsAt',x.ends_at)
      ORDER BY x.starts_at,x.name) FILTER(WHERE x.rn<=8),'[]')) FROM (
     SELECT r.employee_id,e.display_name AS name,r.starts_at,r.ends_at,row_number() OVER (ORDER BY r.starts_at,e.display_name) rn
     FROM app.shift_rosters r JOIN unnest(att) p(id) ON p.id=r.employee_id JOIN app.employees e ON e.organization_id=org AND e.id=r.employee_id
     LEFT JOIN unnest(seen) c(id) ON c.id=r.employee_id
     WHERE r.organization_id=org AND r.site_id=site AND r.work_date=today AND c.id IS NULL) x),
   -- Open sessions past the policy's maximum length: the exit was never recorded.
   'exitNotRecorded',(SELECT jsonb_build_object('count',count(*),'people',coalesce(jsonb_agg(jsonb_build_object(
      'name',CASE WHEN x.employee_id=ANY(ppl) THEN x.name END,'openedAt',x.opened_at) ORDER BY x.opened_at) FILTER(WHERE x.rn<=5),'[]')) FROM (
     SELECT s.employee_id,e.display_name AS name,s.opened_at,row_number() OVER (ORDER BY s.opened_at) rn
     FROM app.duty_sessions s JOIN unnest(att) p(id) ON p.id=s.employee_id JOIN app.employees e ON e.organization_id=org AND e.id=s.employee_id
     WHERE s.organization_id=org AND s.site_id=site AND s.status='open'
     AND s.opened_at+coalesce((SELECT (op.rules->>'maxSessionHours')::int FROM app.operation_policies op
       WHERE op.organization_id=org AND op.site_id=site AND op.version=s.policy_version),24)*interval '1 hour'<=now()) x),
   'roster',(SELECT coalesce(jsonb_agg(jsonb_build_object('day',d,'n',n)),'[]') FROM (
     SELECT r.work_date::text d,count(*) n FROM app.shift_rosters r JOIN unnest(att) p(id) ON p.id=r.employee_id
     WHERE r.organization_id=org AND r.site_id=site AND r.work_date BETWEEN today-13 AND today GROUP BY 1) x),
   'seen',(SELECT coalesce(jsonb_agg(jsonb_build_object('day',d,'n',n)),'[]') FROM (
     SELECT (s.opened_at AT TIME ZONE tz)::date::text d,count(DISTINCT s.employee_id) n FROM app.duty_sessions s JOIN unnest(att) p(id) ON p.id=s.employee_id
     WHERE s.organization_id=org AND s.site_id=site AND s.opened_at>=since AND s.opened_at<hi GROUP BY 1) x)) INTO attendance;
 END IF;

 IF lv IS NOT NULL THEN
  SELECT jsonb_build_object(
   'onLeave',count(DISTINCT l.employee_id) FILTER(WHERE l.status='approved' AND today BETWEEN l.starts_on AND l.ends_on),
   'pending',count(*) FILTER(WHERE l.status='pending'),
   'upcoming',count(DISTINCT l.employee_id) FILTER(WHERE l.status='approved' AND l.starts_on>today AND l.starts_on<=today+7),
   'byType',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',name,'units',units) ORDER BY units DESC,name),'[]') FROM (
     SELECT t.label AS name,sum(x.units)::float units FROM app.leave_requests x JOIN unnest(lv) p(id) ON p.id=x.employee_id
     JOIN app.leave_types t ON t.organization_id=org AND t.id=x.type_id
     WHERE x.organization_id=org AND x.site_id=site AND x.status IN ('pending','approved')
     AND x.starts_on>=date_trunc('month',today) AND x.starts_on<date_trunc('month',today)+interval '1 month' GROUP BY 1) b))
  INTO leave FROM app.leave_requests l JOIN unnest(lv) p(id) ON p.id=l.employee_id
  WHERE l.organization_id=org AND l.site_id=site AND (l.status='pending' OR (l.status='approved' AND l.ends_on>=today));
 END IF;

 IF tk IS NOT NULL THEN
  SELECT coalesce(jsonb_agg(jsonb_build_object('status',status,'count',n,'overdue',overdue,'dueToday',due)),'[]') INTO tasks FROM (
   SELECT t.status,count(*) n,count(*) FILTER(WHERE t.deadline<now()) overdue,count(*) FILTER(WHERE t.deadline>=lo AND t.deadline<hi) due
   FROM app.work_tasks t JOIN unnest(tk) p(id) ON p.id=t.employee_id
   WHERE t.organization_id=org AND t.site_id=site AND t.status<>'done' GROUP BY 1) x;
 END IF;

 IF dw IS NOT NULL THEN
  -- Reviewers see others' drafts only when prepared from chat (dwr_read policy).
  SELECT jsonb_build_object(
   'reports',(SELECT coalesce(jsonb_agg(jsonb_build_object('day',d,'status',status,'n',n)),'[]') FROM (
     SELECT r.work_date::text d,r.status,count(*) n FROM app.dwr_reports r JOIN unnest(dw) p(id) ON p.id=r.employee_id
     WHERE r.organization_id=org AND r.site_id=site AND r.work_date BETWEEN today-13 AND today
     AND (r.status<>'draft' OR r.origin='chat') GROUP BY 1,2) x),
   'waiting',(SELECT count(*) FROM app.dwr_reports r JOIN unnest(dw) p(id) ON p.id=r.employee_id
     WHERE r.organization_id=org AND r.site_id=site AND r.status='submitted' AND r.user_id<>app.actor_id())) INTO dwr;
 END IF;

 IF trk IS NOT NULL THEN
  -- Live location from duty-time tracking; evidence of location, not attendance.
  SELECT coalesce((SELECT stale_seconds FROM app.tracking_policies WHERE organization_id=org AND site_id=site ORDER BY version DESC LIMIT 1),120) INTO stale;
  SELECT jsonb_build_object(
   'now',count(DISTINCT t.employee_id) FILTER(WHERE t.observed_at>now()-stale*interval '1 second'),
   'today',count(DISTINCT t.employee_id)) INTO location
  FROM app.tracking_samples t JOIN unnest(trk) p(id) ON p.id=t.employee_id
  WHERE t.organization_id=org AND t.site_id=site AND t.observed_at>=lo AND t.observed_at<hi AND t.received_at>=lo-interval '1 day';
 END IF;

 RETURN jsonb_build_object('timezone',tz,'today',today::text,'people',people,'attendance',attendance,
  'leave',leave,'tasks',tasks,'dwr',dwr,'location',location);
END $$;
