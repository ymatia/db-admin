select sum(su.blocks) blocks, sid, serial#, segtype, process, decode(s.module,null,'',s.module || ' - ') || s.action module_action, last_call_et, sql_text,
decode(trunc(sum(su.blocks)/50000),0,'White','Red') row_color
from v$sort_usage su, v$session s, v$sql sq
where 1=1
and su.session_addr=s.saddr
and su.sqladdr=sq.address(+)
group by sid, serial#, segtype, process, s.module, s.action, last_call_et, sql_text