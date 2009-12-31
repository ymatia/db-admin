drop package t24_dbadmin;
drop package t24_dbadmin_app;
drop package t24_dbadmin_constants;
drop view t24_dbadmin_v;
delete from fnd_enabled_plsql where plsql_name like 'T24_DBADMIN%';
commit;
exit;
