-- Read-only. Run with the migration connection in the proposed Neon branch.
SELECT name,default_version,installed_version FROM pg_available_extensions
 WHERE name IN ('postgis','pgcrypto','btree_gist');
SELECT current_database(),current_user,version();
SELECT rolname,rolsuper,rolbypassrls,rolcreaterole,rolcreatedb
 FROM pg_roles WHERE rolname IN ('hr_runtime','hr_auth','hr_worker');
SELECT member::regrole,roleid::regrole FROM pg_auth_members
 WHERE member IN (SELECT oid FROM pg_roles WHERE rolname IN ('hr_runtime','hr_auth','hr_worker'));
SELECT schemaname,tablename,tableowner,rowsecurity FROM pg_tables
 WHERE schemaname IN ('app','auth') ORDER BY schemaname,tablename;
