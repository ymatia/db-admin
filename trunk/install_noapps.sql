set serveroutput on
begin
  execute immediate 'create table dbax_dbadmin_const(
    param_name  varchar2(30) not null,
    param_value number not null,
    description	varchar2(250))';
  execute immediate 'alter table dbax_dbadmin_const add constraint dbax_dbadmin_const primary key (param_NAME)';
exception
    when others then
        dbms_output.put_line('Table dbax_dbadmin_const allready exists.');
end;
/
@dbax_dbadmin_constants.pck
exec dbax_dbadmin_constants.create_missing_params;
@dbax_dbadmin_v_noapps.sql
@dbax_tablespaces_v.sql
@dbax_no_free_4_next_extent.sql
set scan off
@dbax_dbadmin_info.pck
@dbax_dbadmin_app_noapps.pck
@dbax_dbadmin.pck
exit;
