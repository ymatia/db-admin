select dbax_dbadmin_app_info.get_full_name(d.employee_id), 
dbax_dbadmin_info.get_sids(d.process),
dbax_dbadmin_app_info.get_work_telephone(d.employee_id), 
d.user_name, d.idle_time, d.process,
d.terminal_id
from DBAX_DBADMIN_v d
