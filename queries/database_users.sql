select s.sid,
       s.osuser,
       nvl(s.terminal, s.machine) terminal,
       s.username,
       value logical_reads,
       s.program,
       s.module,
       s.process os_process,
       p.spid shadow_process,
       status,
       htf.anchor('dbax_dbadmin.kill?sid=' || s.SID || '&' || 'serial=' ||
                  s.SERIAL#,
                  'Kill') drilldown,
       decode(status, 'ACTIVE', 'yellow', 'KILLED', 'red', 'white')
  from v$sesstat t, v$session s, v$process p
 where t.sid = s.sid
   and statistic# = 9
   and type != 'BACKGROUND'
   and s.sid > 10
   and s.paddr = p.addr