create or replace view dbax_dbadmin_v as
    select x.terminal_id, substr(x.process,1,instr(x.process,':')-1) process, idle_time, username user_name, null employee_id
        from (
            select nvl(replace(substr(machine,instr(machine,'\')+1),chr(0),''),machine) terminal_id, process, round(min(last_call_et)/60) idle_time, username, count(1) number_of_sids
            from v$session s
            where 1=1
            and s.client_info is not null
            and s.status != 'KILLED'
            group by machine, process, username
        ) x
;