select sw.sid, s.osuser, s.process, s.module, s.action, s.last_call_et, d.file_name
,htf.anchor2('dbax_dbadmin.kill?sid=' || to_char(sw.sid) || '&' || 'serial='||serial#,'Kill','','main') drilldown
from v$session_wait sw, v$session s, 
(select file_id, file_name from dba_data_files 
    union all 
 select file_id+(select p.value from v$parameter p where name='db_files'), file_name from dba_temp_files
) d
where sw.sid=s.sid
and s.type='USER'
and sw.p1text in ('file#','file number')
and d.file_id=sw.p1
and event not in ('SQL*Net message from client','pipe get','rdbms ipc message','wakeup time manager')
