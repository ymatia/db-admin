create or replace view dbax_dbadmin_v as
        select x.terminal_id, substr(x.process,1,instr(x.process,':')-1) process, idle_time, u.user_name user_name, u.employee_id
        from (
            select nvl(replace(substr(machine,instr(machine,'\')+1),chr(0),''),machine) terminal_id, process, round(min(last_call_et)/60) idle_time, count(1) number_of_sids
            from v$session s
            where 1=1
            and s.client_info is not null
            and s.status != 'KILLED'
            group by machine, process
        ) x,
        fnd_logins l, fnd_user u
        where x.process=l.spid
	and l.login_name is not null
        and x.terminal_id=l.terminal_id
        and l.end_time is null
        and exists (select 1 from v$process p where p.pid=l.pid and p.spid=l.process_spid and p.serial#=l.serial#)
        and u.user_id=l.user_id;