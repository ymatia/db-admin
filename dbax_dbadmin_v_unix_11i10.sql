create or replace view dbax_dbadmin_v as
	select x.terminal_id, x.process, idle_time, u.user_name user_name, u.employee_id
        from (
            select replace(substr(machine,instr(machine,'\')+1),chr(0),'') terminal_id, process, pid, round(min(last_call_et)/60) idle_time, count(1) number_of_sids
            from v$session s, v$process p
            where 1=1
            and s.client_info is not null
            and s.status != 'KILLED'
            and s.paddr=p.addr
            group by machine, process, pid
        ) x,
        fnd_logins l, fnd_user u
        where x.pid=l.pid
        and x.process is not null
--	and l.login_name is not null		-- comment because of 11i10
--      and x.terminal_id=l.terminal_id		-- Comment because of unix
        and l.end_time is null
        and exists (select 1 from v$process p where p.pid=l.pid and p.spid=l.process_spid and p.serial#=l.serial#)
        and u.user_id=l.user_id;