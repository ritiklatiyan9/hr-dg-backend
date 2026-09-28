-- Compare local calendar timestamps so reminders can cross midnight without wrapping.
CREATE OR REPLACE FUNCTION app.dwr_tick() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record; BEGIN
 FOR r IN
 SELECT ds.organization_id,ds.site_id,e.user_id,e.id employee_id,dates.dt
 FROM app.dwr_settings ds JOIN app.sites s ON s.id=ds.site_id AND s.organization_id=ds.organization_id
 CROSS JOIN LATERAL (SELECT now() AT TIME ZONE s.timezone AS local_now) clock
 CROSS JOIN LATERAL (SELECT clock.local_now::date+i-ds.deadline_day_offset AS dt FROM generate_series(0,1) i) dates
 JOIN app.site_assignments a ON a.organization_id=ds.organization_id AND a.site_id=ds.site_id
 JOIN app.employees e ON e.organization_id=a.organization_id AND e.id=a.employee_id
 WHERE e.user_id IS NOT NULL AND dates.dt<=clock.local_now::date
 AND dates.dt BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date)
 AND clock.local_now >= (dates.dt+ds.deadline_day_offset+ds.deadline)-(ds.reminder_minutes*interval '1 minute')
 AND clock.local_now < (dates.dt+ds.deadline_day_offset+1)::timestamp
 AND NOT EXISTS(SELECT 1 FROM app.dwr_reminders n WHERE (n.organization_id,n.site_id,n.user_id,n.work_date)=(ds.organization_id,ds.site_id,e.user_id,dates.dt))
 AND NOT EXISTS(SELECT 1 FROM app.dwr_reports d WHERE (d.organization_id,d.site_id,d.employee_id,d.work_date)=(ds.organization_id,ds.site_id,e.id,dates.dt) AND d.status IN ('submitted','approved'))
 ORDER BY ds.site_id,e.id,dates.dt LIMIT 1000
 LOOP
 PERFORM set_config('app.organization_id',r.organization_id::text,true),set_config('app.site_id',r.site_id::text,true),set_config('app.actor_id',r.user_id::text,true);
 IF app.has_site(r.site_id) AND app.allowed('my_dwr.submit',r.employee_id) THEN
 INSERT INTO app.dwr_reminders VALUES(r.organization_id,r.site_id,r.user_id,r.dt) ON CONFLICT DO NOTHING;
 IF FOUND THEN PERFORM app.operation_notify(r.user_id,'my_dwr',gen_random_uuid(),'dwr.reminder.'||r.dt); END IF;
 END IF;
 END LOOP;
END $$;
