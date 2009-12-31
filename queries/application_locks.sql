select l1.session_id, dbax_dbadmin_info.get_object_by_id(l3.id1), l1.mode_held, l1.mode_requested, round(l1.last_convert/60),
dbax_dbadmin_app_info.get_full_name_by_sid(l1.session_id),
dbax_dbadmin_info.get_session_terminal(l1.session_id),
l1.blocking_others,
htf.anchor2('dbax_dbadmin.kill?sid=' || to_char(l1.session_id) || '&' || 'serial='||to_char(dbax_dbadmin_info.get_session_serial#(l1.session_id)),'Kill','','main'),
decode(l1.blocking_others,'Blocking','red','white') row_color
from dba_locks l1, (select l2.sid, l2.id1 from v$lock l2 where l2.type='TM') l3
where l1.lock_type='Transaction'
and l1.session_id=l3.sid