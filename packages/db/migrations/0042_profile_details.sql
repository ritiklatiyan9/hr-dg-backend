-- Profile photo and basic details. Employees propose them in the existing
-- profile request (with the phone); approval by an independent reviewer applies
-- them. Details are "contact" field data; photos are visible with the employee.
ALTER TABLE app.employees ADD COLUMN personal jsonb NOT NULL DEFAULT '{}'::jsonb
 CHECK (jsonb_typeof(personal)='object' AND octet_length(personal::text)<=4000);
ALTER TABLE app.profile_requests
 ADD COLUMN details jsonb CHECK (details IS NULL OR (jsonb_typeof(details)='object' AND octet_length(details::text)<=4000)),
 ADD COLUMN photo bytea CHECK (photo IS NULL OR octet_length(photo) BETWEEN 1 AND 262144);
CREATE TABLE app.employee_photos (
 organization_id uuid NOT NULL, employee_id uuid NOT NULL,
 photo bytea NOT NULL CHECK (octet_length(photo) BETWEEN 1 AND 262144),
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (organization_id,employee_id),
 FOREIGN KEY (organization_id,employee_id) REFERENCES app.employees(organization_id,id)
);
ALTER TABLE app.employee_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY photos_read ON app.employee_photos FOR SELECT USING (organization_id=app.org_id() AND app.visible_employee(employee_id));
GRANT SELECT ON app.employee_photos TO hr_runtime;
-- The request stores the proposal; approval applies it with the phone.
DO $$ DECLARE d text; old_insert text; old_apply text; BEGIN
 d:=pg_get_functiondef('app.employee_foundation(text,jsonb)'::regprocedure);
 old_insert:='INSERT INTO app.profile_requests(organization_id,site_id,employee_id,requester_id,phone,reason,employee_version) VALUES(app.org_id(),app.site_id(),r.id,app.actor_id(),payload->>''phone'',payload->>''reason'',r.version) RETURNING id INTO new_id;';
 old_apply:='UPDATE app.employees SET phone=r.phone,version=version+1,updated_at=now() WHERE organization_id=app.org_id() AND id=r.employee_id AND version=r.employee_version;
 IF NOT FOUND THEN RAISE EXCEPTION ''CONFLICT'' USING ERRCODE=''P0001''; END IF;';
 IF position(old_insert IN d)=0 OR position(old_apply IN d)=0 THEN RAISE EXCEPTION 'employee_foundation changed; update 0042'; END IF;
 d:=replace(d,old_insert,'INSERT INTO app.profile_requests(organization_id,site_id,employee_id,requester_id,phone,reason,employee_version,details,photo) VALUES(app.org_id(),app.site_id(),r.id,app.actor_id(),payload->>''phone'',payload->>''reason'',r.version,payload->''details'',decode(payload->>''photo'',''base64'')) RETURNING id INTO new_id;');
 d:=replace(d,old_apply,'UPDATE app.employees SET phone=r.phone,personal=COALESCE(r.details,personal),version=version+1,updated_at=now() WHERE organization_id=app.org_id() AND id=r.employee_id AND version=r.employee_version;
 IF NOT FOUND THEN RAISE EXCEPTION ''CONFLICT'' USING ERRCODE=''P0001''; END IF;
 IF r.photo IS NOT NULL THEN
 INSERT INTO app.employee_photos(organization_id,employee_id,photo) VALUES(app.org_id(),r.employee_id,r.photo)
 ON CONFLICT (organization_id,employee_id) DO UPDATE SET photo=EXCLUDED.photo,updated_at=now();
 END IF;');
 EXECUTE d;
END $$;
