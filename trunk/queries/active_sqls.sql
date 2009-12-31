select s.sid, s.serial#, s.osuser, s.process, s.machine, s.terminal, s.program, s.module, s.action, q.SQL_TEXT
from v$session s, v$sql q
where q.ADDRESS=s.SQL_ADDRESS
and status='ACTIVE'
and s.TYPE='USER';
