create or replace package DBAX_DBADMIN_INFO is

type vc100 is table of varchar2(100) index by binary_integer;
type vc32k is table of varchar2(32000) index by binary_integer;

headers vc100; 
queries vc32k;
column_headers vc32k;

function get_object_by_id (p_object_id in number) return varchar2;
function get_objects_locked_by_session(p_sid in number) return varchar2;
function get_session_serial# (p_sid in number) return v$session.SERIAL#%type;
function get_session_terminal (p_sid in number) return v$session.terminal%type;
function get_session_username (p_sid in number) return v$session.username%type;
function get_sids(p_process in varchar2) return varchar2;

end DBAX_DBADMIN_INFO;
/
create or replace package body DBAX_DBADMIN_INFO is

g_sid           v$session.SID%type := '-1';
g_serial#       v$session.SERIAL#%type;
g_terminal      v$session.TERMINAL%type;
g_username      v$session.username%type;

function get_object_by_id (p_object_id in number) return varchar2 is
    l_object_name      varchar2(1000);
begin
    select owner || '.' || object_name
    into l_object_name
    from dba_objects
    where object_id=p_object_id;
    
    return l_object_name;
exception
    when others then
        return p_object_id;
end;

function get_objects_locked_by_session(p_sid in number) return varchar2 is
    l_result varchar2(1000) := '';
    cursor locks is
        select get_object_by_id(id1) locked_object
        from v$lock
        where type='TM'
        and sid=p_sid;
begin
    for c in locks loop
        if l_result is not null then
            l_result := l_result || chr(10);
        end if;
        l_result := l_result || c.locked_object;
    end loop;
    return l_result;
end;

procedure get_session_info (p_sid in number) is
begin
    select serial#, terminal, username
    into g_serial#, g_terminal, g_username
    from v$session
    where sid=p_sid;
end get_session_info;

function get_session_serial# (p_sid in number) return v$session.SERIAL#%type is
begin
    if p_sid!=g_sid then
        get_session_info(p_sid);
    end if;
    return g_serial#;
end get_session_serial#;
        
function get_session_terminal (p_sid in number) return v$session.terminal%type is
begin
    if p_sid!=g_sid then
        get_session_info(p_sid);
    end if;
    return g_terminal;
end get_session_terminal;

function get_session_username (p_sid in number) return v$session.username%type is
begin
    if p_sid!=g_sid then
        get_session_info(p_sid);
    end if;
    return g_username;
end get_session_username;

function get_sids(p_process in varchar2) return varchar2 is
     cursor users_sids is
            select sid, module, program
            from v$session s
            where s.process = p_process
               or s.process like p_process || ':%';

    result varchar2(1000);               
begin
    result:='';
    for c in users_sids loop
        if c.program = 'JDBC Thin Client' then
            result := 'Web sessions';
        else
            if result is not null then
               result := result || chr(10);
            end if;
            result := result || to_char(c.sid) || ' ' || nvl(c.module,'Main Menu');
        end if;
    end loop;
    return result;
end;    
---------------------------------------------------------------------------------------------
begin

headers(1) := 'Active SQLs';
queries(1) := 
    'select s.sid,' || chr(10) ||
    '       s.serial#,' || chr(10) ||
    '       s.osuser,' || chr(10) ||
    '       s.process,' || chr(10) ||
    '       s.machine,' || chr(10) ||
    '       s.terminal,' || chr(10) ||
    '       s.program,' || chr(10) ||
    '       s.module,' || chr(10) ||
    '       s.action,' || chr(10) ||
    '       q.SQL_TEXT' || chr(10) ||
    'from v$session s, v$sql q' || chr(10) ||
    'where q.ADDRESS=s.SQL_ADDRESS' || chr(10) ||
    'and status=''ACTIVE''' || chr(10) ||
    'and s.TYPE=''USER''';
column_headers(1):='Session ID,Serial#,Os User,Process,Machine,Terminal,Program,Module,Action,SQL Text';

headers(2) := 'Self-Service Sessions';
queries(2) := 
    'select /*+rule*/ first_connect, round((sysdate-last_connect)*24*60,2) idle, u.user_name, p.full_name, f.user_function_name' || chr(10) ||
    'from icx_sessions s, fnd_user u, per_all_people_f p, fnd_form_functions_tl f' || chr(10) ||
    'where 1=1' || chr(10) ||
    'and s.last_connect > sysdate-1/24/6' || chr(10) ||
    'and u.user_id(+)=s.user_id' || chr(10) ||
    'and p.person_id(+)=u.employee_id' || chr(10) ||
    'and p.effective_start_date (+) <= sysdate' || chr(10) ||
    'and p.effective_end_date (+) >= sysdate' || chr(10) ||
    'and f.function_id(+)=s.function_id' || chr(10) ||
    'and f.language(+)=''US''';
column_headers(2) := 'First Connect,NUM:Idle (minutes),User Name,Employee Name,Function Name';

headers(3) := 'Tablespaces';
queries(3) :=
    'select * from dbax_tablespaces_v';
column_headers(3) := 'Tablespace Name,NUM:Total,NUM:Free,NUM:%Free,NUM:Need for 30%,NUM:Optimal(30%),Drilldown to Datafiles,ROW_COLOR';

headers(4) := 'Locks';
queries(4) :=
'	    select' || chr(10) ||
'    l.sid session_id,' || chr(10) ||
'    dbax_dbadmin_info.get_object_by_id(l3.id1) lock_id1,' || chr(10) ||
'	decode(lmode,' || chr(10) ||
'		0, ''None'',           /* Mon Lock equivalent */' || chr(10) ||
'		1, ''Null'',           /* N */' || chr(10) ||
'		2, ''Row-S (SS)'',     /* L */' || chr(10) ||
'		3, ''Row-X (SX)'',     /* R */' || chr(10) ||
'		4, ''Share'',          /* S */' || chr(10) ||
'		5, ''S/Row-X (SSX)'',  /* C */' || chr(10) ||
'		6, ''Exclusive'',      /* X */' || chr(10) ||
'		to_char(lmode)) mode_held,' || chr(10) ||
'         decode(request,' || chr(10) ||
'		0, ''None'',           /* Mon Lock equivalent */' || chr(10) ||
'		1, ''Null'',           /* N */' || chr(10) ||
'		2, ''Row-S (SS)'',     /* L */' || chr(10) ||
'		3, ''Row-X (SX)'',     /* R */' || chr(10) ||
'		4, ''Share'',          /* S */' || chr(10) ||
'		5, ''S/Row-X (SSX)'',  /* C */' || chr(10) ||
'		6, ''Exclusive'',      /* X */' || chr(10) ||
'		to_char(request)) mode_requested,' || chr(10) ||
'	 ctime last_convert,' || chr(10) ||
'	 decode(block,' || chr(10) ||
'	        0, ''Not Blocking'',  /* Not blocking any other processes */' || chr(10) ||
'		1, ''Blocking'',      /* This lock blocks other processes */' || chr(10) ||
'		2, ''Global'',        /* This lock is global, so we can''t tell */' || chr(10) ||
'		to_char(block)) blocking_others,' || chr(10) ||
'        dbax_dbadmin_info.get_session_terminal(l.SID) terminal,' || chr(10) ||
'        dbax_dbadmin_info.get_session_username(l.sid) username,' || chr(10) ||
'        ''<a href="''||''dbax_dbadmin.'' || ''kill?sid=''|| l.sid || ''&'' || ''serial='' || dbax_dbadmin_info.get_session_serial#(l.SID)||''" target="main">Kill</a>'' drilldown,' || chr(10) ||
'        decode(block,1,''red'',''white'') row_color' || chr(10) ||
' from v$lock l, (select l2.sid, l2.id1 from v$lock l2 where l2.type=''TM'') l3' || chr(10) ||
' where l.type=''TX''' || chr(10) ||
' and l3.sid=l.sid';
column_headers(4) := 'Sid,Object Name,Mode Held,Mode Requested,NUM:Last Convert,Blocking?,Terminal,User Name,Action,ROW_COLOR';

headers(5) := 'Database Users';
queries(5) :=
'select s.sid,' || chr(10) ||
'       s.osuser,' || chr(10) ||
'       nvl(s.terminal, s.machine) terminal,' || chr(10) ||
'       s.username,' || chr(10) ||
'       value logical_reads,' || chr(10) ||
'       s.program,' || chr(10) ||
'       s.module,' || chr(10) ||
'       s.process os_process,' || chr(10) ||
'       p.spid shadow_process,' || chr(10) ||
'       status,' || chr(10) ||
'       htf.anchor(''dbax_dbadmin.kill?sid='' || s.SID || ''&'' || ''serial='' ||' || chr(10) ||
'                  s.SERIAL#,' || chr(10) ||
'                  ''Kill'') drilldown,' || chr(10) ||
'       decode(status, ''ACTIVE'', ''yellow'', ''KILLED'', ''red'', ''white'')' || chr(10) ||
'  from v$sesstat t, v$session s, v$process p' || chr(10) ||
' where t.sid = s.sid' || chr(10) ||
'   and statistic# = 9' || chr(10) ||
'   and type != ''BACKGROUND''' || chr(10) ||
'   and s.sid > 10' || chr(10) ||
'   and s.paddr = p.addr';
column_headers(5) := 'SID,OS User Name,Terminal,DB User,NUM:Logical Reads,Program,Module,OS PID,Shadow PID,Status,Action,ROW_COLOR';

headers(6) := 'Invalid Objects';
queries(6) :=
'select OBJECT_TYPE,OWNER,object_name, ''<a href="dbax_dbadmin.compile?p_object_type='' || replace(object_type,'' '',''%20'') || ''&'' || ''p_object_name=''|| object_name || ''&'' || ''p_owner=''|| owner || ''">Compile</a>''' || chr(10) ||
'from   dba_objects o' || chr(10) ||
'where  o.status=''INVALID''' || chr(10) ||
'  and not exists (select 1' || chr(10) ||
'                  from  dba_triggers t' || chr(10) ||
'                  where t.status=''DISABLED''' || chr(10) ||
'                    and t.trigger_name=o.object_name' || chr(10) ||
'                    and t.owner=o.owner' || chr(10) ||
'                    and o.object_type=''TRIGGER''' || chr(10) ||
'                 )';
column_headers(6) := 'Object Type,Owner,Object Name,Action';

headers(7) := 'User I/O Waits';
queries(7) :=
'select sw.sid, s.osuser, s.process, s.module, s.action, s.last_call_et, d.file_name' || chr(10) ||
',htf.anchor2(''dbax_dbadmin.kill?sid='' || to_char(sw.sid) || ''&'' || ''serial=''||serial#,''Kill'','''',''main'') drilldown' || chr(10) ||
'from v$session_wait sw, v$session s,' || chr(10) ||
'(select file_id, file_name from dba_data_files' || chr(10) ||
'    union all' || chr(10) ||
' select file_id+(select p.value from v$parameter p where name=''db_files''), file_name from dba_temp_files' || chr(10) ||
') d' || chr(10) ||
'where sw.sid=s.sid' || chr(10) ||
'and s.type=''USER''' || chr(10) ||
'and sw.p1text in (''file#'',''file number'')' || chr(10) ||
'and d.file_id=sw.p1' || chr(10) ||
'and sw.event not in (''SQL*Net message from client'',''pipe get'',''rdbms ipc message'',''wakeup time manager'')';
column_headers(7) := 'Sid,Os User,Process,Module,Action,NUM:Run Time,File Name,Action'; 

headers(8) := 'Running Programs';
queries(8) :=
'  select htf.anchor2(''dbax_dbadmin_app.prog_info?p_request_id='' || request_id ,request_id) request_id, DBAX_DBADMIN_app_info.get_user_name(r.requested_by) requestor,' || chr(10) ||
'         phase.meaning phase, status.meaning status,' || chr(10) ||
'         p.user_concurrent_program_name ||' || chr(10) ||
'            decode(p.user_concurrent_program_name,''Report Set'','' ('' || r.description || '')'',''Check Periodic Alert'','' ('' || r.description || '')'','''') user_concurrent_program_name,' || chr(10) ||
'         decode(r.phase_code,''R'',r.actual_start_date,''P'',r.requested_start_date) start_date,' || chr(10) ||
'         decode(r.phase_code,''R'',to_char((sysdate - r.actual_start_date) / (1/24/60),''999.99'')) run_time,' || chr(10) ||
'         nvl(r.os_process_id,s.process) os_process,' || chr(10) ||
'         p.spid shadow_process,' || chr(10) ||
'         s.SID,' || chr(10) ||
'         htf.anchor2(''dbax_dbadmin_app.terminate?p_request_id='' || request_id ,''Terminate'') terminate,' || chr(10) ||
'         decode(r.phase_code,''R'',htf.anchor2(''dbax_dbadmin.kill?sid='' || s.SID || ''&'' || ''serial='' || s.SERIAL#,''Kill''),'''') kill_session' || chr(10) ||
'  from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r,' || chr(10) ||
'        Fnd_Lookups Phase,' || chr(10) ||
'        Fnd_Lookups Status,' || chr(10) ||
'        v$session s, v$process p' || chr(10) ||
'  where  r.phase_code in (''P'',''R'')' || chr(10) ||
'         and r.concurrent_program_id = p.concurrent_program_id' || chr(10) ||
'         and r.program_application_id = p.application_id' || chr(10) ||
'         and s.AUDSID (+) =r.oracle_session_id' || chr(10) ||
'         and p.addr (+) = s.paddr' || chr(10) ||
'    and Phase.Lookup_Type = ''CP_PHASE_CODE''' || chr(10) ||
'    AND Phase.Lookup_Code = Decode(Status.Lookup_Code,' || chr(10) ||
'                        ''H'', ''I'',' || chr(10) ||
'                        ''S'', ''I'',' || chr(10) ||
'                        ''U'', ''I'',' || chr(10) ||
'                        ''M'', ''I'',' || chr(10) ||
'                        R.Phase_Code) AND' || chr(10) ||
'Status.Lookup_Type = ''CP_STATUS_CODE'' AND' || chr(10) ||
'Status.Lookup_Code =' || chr(10) ||
' Decode(R.Phase_Code,' || chr(10) ||
' ''P'', Decode(R.Hold_Flag,          ''Y'', ''H'',' || chr(10) ||
'      Decode(P.Enabled_Flag,       ''N'', ''U'',' || chr(10) ||
'      Decode(Sign(R.Requested_Start_Date - SYSDATE),1,''P'',' || chr(10) ||
'      R.Status_Code))),' || chr(10) ||
' ''R'', Decode(R.Hold_Flag,          ''Y'', ''S'',' || chr(10) ||
'      Decode(R.Status_Code,        ''Q'', ''B'',' || chr(10) ||
'                                   ''I'', ''B'',' || chr(10) ||
'      R.Status_Code)),' || chr(10) ||
'      R.Status_Code)';
column_headers(8) := 'Request ID,Requestor,Phase,Status,Program Name,Start Time,NUM:Run Time (Min.),OS Process,Shadow PID,SID,Terminate,Kill Session'; 

headers(9) := 'Application Users';
queries(9) :=
'select dbax_dbadmin_app_info.get_full_name(d.employee_id),' || chr(10) ||
'dbax_dbadmin_info.get_sids(d.process),' || chr(10) ||
'dbax_dbadmin_app_info.get_work_telephone(d.employee_id),' || chr(10) ||
'd.user_name, d.idle_time, d.process,' || chr(10) ||
'd.terminal_id' || chr(10) ||
'from DBAX_DBADMIN_v d';
column_headers(9) := 'Full Name,Sids+Modules,Phone,User Name,NUM:Idle Time (Min.),OS Process,Terminal'; 

headers(10) := 'Application Locks';
queries(10) :=
'select l1.session_id, dbax_dbadmin_info.get_object_by_id(l3.id1), l1.mode_held, l1.mode_requested, round(l1.last_convert/60),' || chr(10) ||
'dbax_dbadmin_app_info.get_full_name_by_sid(l1.session_id),' || chr(10) ||
'dbax_dbadmin_info.get_session_terminal(l1.session_id),' || chr(10) ||
'l1.blocking_others,' || chr(10) ||
'htf.anchor2(''dbax_dbadmin.kill?sid='' || to_char(l1.session_id) || ''&'' || ''serial=''||to_char(dbax_dbadmin_info.get_session_serial#(l1.session_id)),''Kill'','''',''main''),' || chr(10) ||
'decode(l1.blocking_others,''Blocking'',''red'',''white'') row_color' || chr(10) ||
'from dba_locks l1, (select l2.sid, l2.id1 from v$lock l2 where l2.type=''TM'') l3' || chr(10) ||
'where l1.lock_type=''Transaction''' || chr(10) ||
'and l1.session_id=l3.sid';
column_headers(10) := 'Sid,Object Name,Mode Held,Mode Requested,Lock Time (Min.),Employee,Terminal,Blocking?,Action,ROW_COLOR'; 

headers(11) := 'Patchset Levels';
queries(11) :=
'select a.application_short_name, a.application_name, pi.patch_level, decode(pi.status,''N'',''None'',''I'',''Installed'',''S'',''Shared'')' || chr(10) ||
'from fnd_product_installations pi, fnd_application_vl a' || chr(10) ||
'where a.application_id=pi.application_id';
column_headers(11) := 'Application Short Name,Application Name,Patch Level,Status'; 

headers(12) := 'Installed Patches';
queries(12) :=
'select ap.patch_name, ap.patch_type, max(ap.creation_date),' || chr(10) ||
'dbax_dbadmin_app_info.get_moudles_by_patch_name(ap.patch_name)' || chr(10) ||
'from applsys.ad_applied_patches ap' || chr(10) ||
'group by ap.patch_name, ap.patch_type';
column_headers(12) := 'Patch Number,Patch Type,Installation Date,Affected Modules'; 

headers(13) := 'Completed Concurrent Requests';
queries(13) :=
'  select htf.anchor2(''dbax_dbadmin_app.prog_info?p_request_id='' || request_id ,request_id) request_id, DBAX_DBADMIN_app_info.get_user_name(r.requested_by) requestor,' || chr(10) ||
'         status.meaning status,' || chr(10) ||
'         p.user_concurrent_program_name,' || chr(10) ||
'         r.actual_start_date start_date,' || chr(10) ||
'         to_char((r.actual_completion_date - r.actual_start_date) / (1/24/60),''999,999,999.99'') run_time' || chr(10) ||
'  from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r,' || chr(10) ||
'        Fnd_Lookups Status' || chr(10) ||
'  where  r.phase_code=''C''' || chr(10) ||
'         and r.concurrent_program_id = p.concurrent_program_id' || chr(10) ||
'         and r.program_application_id = p.application_id' || chr(10) ||
'and Status.Lookup_Type = ''CP_STATUS_CODE''' || chr(10) ||
'and Status.Lookup_Code =' || chr(10) ||
' Decode(R.Phase_Code,' || chr(10) ||
' ''P'', Decode(R.Hold_Flag,          ''Y'', ''H'',' || chr(10) ||
'      Decode(P.Enabled_Flag,       ''N'', ''U'',' || chr(10) ||
'      Decode(Sign(R.Requested_Start_Date - SYSDATE),1,''P'',' || chr(10) ||
'      R.Status_Code))),' || chr(10) ||
' ''R'', Decode(R.Hold_Flag,          ''Y'', ''S'',' || chr(10) ||
'      Decode(R.Status_Code,        ''Q'', ''B'',' || chr(10) ||
'                                   ''I'', ''B'',' || chr(10) ||
'      R.Status_Code)),' || chr(10) ||
'      R.Status_Code)' || chr(10) ||
'and r.actual_completion_date > sysdate-1/12';
column_headers(13) := 'Request ID,Requestor,Completion Status,Program Name,Start Time,NUM:Run Time (Min.)'; 

headers(14) := 'Init.ora Parameters';
queries(14) :=
'select num,' || chr(10) ||
'       name,' || chr(10) ||
'       replace(replace(value, '','', chr(10)), '' '', ''''),' || chr(10) ||
'       decode(isdefault, ''TRUE'', ''Yes'', ''No'') isdefault,' || chr(10) ||
'       decode(issys_modifiable , ''TRUE'', ''Yes'', ''No'') issys_modifiable,' || chr(10) ||
'       decode(isdefault, ''TRUE'', ''White'', ''Yellow'') row_color' || chr(10) ||
'  from v$parameter';
column_headers(14) := 'NUM:Num,Name,Value,Default,Modifiable,ROW_COLOR'; 

headers(15) := 'Temporary Space Usage';
queries(15) :=
'select sum(su.blocks) blocks, sid, serial#, segtype, process, decode(s.module,null,'''',s.module || '' - '') || s.action module_action, last_call_et, sql_text,' || chr(10) ||
'decode(trunc(sum(su.blocks)/50000),0,''White'',''Red'') row_color' || chr(10) ||
'from v$sort_usage su, v$session s, v$sql sq' || chr(10) ||
'where 1=1' || chr(10) ||
'and su.session_addr=s.saddr' || chr(10) ||
'and su.sqladdr=sq.address(+)' || chr(10) ||
'group by sid, serial#, segtype, process, s.module, s.action, last_call_et, sql_text';
column_headers(15) := 'NUM:Blocks,NUM:SID,NUM:Serial#,Segment Type,Process,Module/Action,Idle Time,SQL Text,ROW_COLOR'; 

headers(16) := 'Long Running Concurrent Requests';
queries(16) :=
'select decode(p.user_concurrent_program_name,' || chr(10) ||
'              ''Report Set'',' || chr(10) ||
'              p.description || '' (Report Set)'',' || chr(10) ||
'              p.user_concurrent_program_name) program,' || chr(10) ||
'       round(avg(r.actual_completion_date - r.actual_start_date) * 24 * 60,' || chr(10) ||
'             2) average_minutes,' || chr(10) ||
'       round(max(r.actual_completion_date - r.actual_start_date) * 24 * 60,' || chr(10) ||
'             2) max_minutes,' || chr(10) ||
'       round(sum((r.actual_completion_date - r.actual_start_date) * 24 * 60),' || chr(10) ||
'             2) total_run_time,' || chr(10) ||
'       count(1) num' || chr(10) ||
'  from fnd_concurrent_requests r, fnd_concurrent_programs_vl p' || chr(10) ||
' where r.concurrent_program_id = p.concurrent_program_id' || chr(10) ||
'   and r.program_application_id = p.application_id' || chr(10) ||
'   and r.phase_code = ''C''' || chr(10) ||
'   and r.actual_start_date is not null' || chr(10) ||
' group by decode(p.user_concurrent_program_name,' || chr(10) ||
'                 ''Report Set'',' || chr(10) ||
'                 p.description || '' (Report Set)'',' || chr(10) ||
'                 p.user_concurrent_program_name),' || chr(10) ||
'          r.resubmit_interval,' || chr(10) ||
'          r.resubmit_interval_unit_code';
column_headers(16) := 'Program Name,NUM:Average Min.,NUM:Max Min.,NUM:Total Min.,NUM:Run Count'; 

headers(17) := 'Workflow Errors';
queries(17) :=
'select ias.begin_date,' || chr(10) ||
'       i.item_type,' || chr(10) ||
'       i.item_key,' || chr(10) ||
'       i.user_key,' || chr(10) ||
'       pa.activity_name,' || chr(10) ||
'       ias.error_message' || chr(10) ||
'  from wf_item_activity_statuses ias, wf_items i, wf_process_activities pa' || chr(10) ||
' where activity_status = ''ERROR''' || chr(10) ||
'   and ias.item_type = i.item_type' || chr(10) ||
'   and ias.item_key = i.item_key' || chr(10) ||
'   and i.end_date is null' || chr(10) ||
'   and pa.instance_id = ias.process_activity';
column_headers(17) := 'Date,Item Type,Item Key,User Key,Activity Name,Error Message'; 


end DBAX_DBADMIN_INFO;
/
