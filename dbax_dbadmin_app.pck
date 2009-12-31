create or replace package DBAX_DBADMIN_APP is

procedure menu2;

-- Locks Module
procedure locks;

-- Concurrent managers Module
procedure concs;

-- Running Programs Module
procedure terminate(p_request_id number, password number default 0);
procedure prog_info(p_request_id number);

procedure mon2;

procedure patches;

procedure re_enqueue_notifications;

procedure before_mrc(p_fromweb varchar2 default 'N');

procedure view_file(p_request_id in number,p_file_type in number);

procedure app_info;

procedure retry_workflow(print_only boolean default false);

procedure retry_workflow_conc ( errbuf out varchar2,
                                retcode out varchar2 );

end DBAX_DBADMIN_APP;
/
create or replace package body DBAX_DBADMIN_APP is

base      varchar2(100);       -- base url for the package
base_app  varchar2(100);
db_name   varchar2(30);

function check_license return boolean is
begin
	return false;
end;

procedure menu2 is
begin
        htp.paragraph;
        htp.print('<STRONG>Oracle Applications</STRONG>');
        htp.nl;
        htp.anchor2(base_app || 'app_info','Application Info','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=8&p_order_by=3 desc,6&p_order_way=asc','Running Programs','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=13&p_order_way=desc','Completed Requests','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=16&p_order_by=2&p_order_way=desc','Long Running Requests','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=9&p_order_by=5&p_order_way=desc','Application Users','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=10','Locks (Extended)','','main');
        htp.nl;
        htp.anchor2(base_app || 'concs','Concurrents','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=11','Patch Levels','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=12&p_order_by=3&p_order_way=desc','Installed Patches','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=2','Self-Service Sessions','','main');
        htp.nl;
        htp.anchor2(base_app || 'before_mrc?p_fromweb=Y','Before MRC','','main');
        htp.nl;
        htp.anchor2(base || 'grid?p_form=17&p_order_by=1&p_order_way=desc','Workflow Errors','','main');
        htp.nl;
end;

procedure locks is

     cursor locks_cursor is
         select * 
         from dba_locks l 
         where lock_type='DML'
         order by lock_id1;

    l_object_name       dba_objects.object_name%type;
    l_serial            number;
    l_owner             dba_objects.owner%type;
    l_osuser            v$session.osuser%type;
    l_terminal          v$session.terminal%type;
    l_full_name        per_people_v7.full_name%type;
    l_phone            per_people_v7.work_telephone%type;
    l_employee_id       number;
    l_process           v$session.process%type;
    l_user_name         fnd_user.user_name%type;

begin
	if check_license then
		return;
	end if;

     htp.htmlopen;
     htp.headopen;
     htp.title(ctitle => 'DBAdmin Locks');
     htp.headclose;
     htp.bodyopen;
     htp.header(1,'Application User Locks');
     htp.paragraph;

     htp.tableopen(null,null,null,null,'border=1');
     htp.tablerowopen;
     htp.tableheader('Object Name');
     htp.tableheader('Object Owner');
     htp.tableheader('Lock Type');
     htp.tableheader('Sid');
     htp.tableheader('Employee');
     htp.tableheader('Phone');
     htp.tableheader('Terminal');
     for c_rec in locks_cursor loop
         if c_Rec.blocking_others like 'Blocking%' then
            htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
         else
            htp.tablerowopen;
         end if;

         select serial#, osuser, s.terminal, s.process
         into l_serial, l_osuser, l_terminal, l_process
         from v$session s
         where s.sid=c_rec.session_id;
         
         select object_name, owner
         into l_object_name, l_owner
         from dba_objects
         where object_id=c_rec.lock_id1;

         begin
            select v.employee_id, v.user_name
            into l_employee_id, l_user_name
            from DBAX_DBADMIN_v v
            where v.process=l_process
               or l_process like v.process || ':%';
        
            if l_employee_id is not null then
                select full_name, nvl(p.work_telephone, '&nbsp')
                into l_full_name, l_phone
                from per_people_v7 p
                where p.person_id=l_employee_id;
            else
                l_full_name := l_user_name;
                l_phone := '&nbsp';
            end if;
         exception
            when others then
                l_full_name := '&nbsp';
                l_phone := '&nbsp';
         end;  
         
         htp.tabledata(l_object_name);
         htp.tabledata(l_owner);
         htp.tabledata(c_rec.mode_held);
         htp.tabledata(c_rec.session_id,'right');
         htp.tabledata(l_full_name);
         htp.tabledata(l_phone);
         
         htp.tabledata(nvl(l_terminal,'&nbsp'));
         htp.print('<TD>');
         htp.anchor2(base || 'kill?sid=' || to_char(c_rec.session_id) || '&' || 'serial='||to_char(l_serial),'Kill','','main');
         htp.print('</TD>');
         htp.tablerowclose;
     end loop;
     htp.tableclose;

     htp.bodyclose;
     htp.htmlclose;
end;

procedure concs is

     cursor c is
            SELECT CONCURRENT_QUEUE_NAME,MAX_PROCESSES,
            APPLICATION_ID,CONCURRENT_QUEUE_ID,CONTROL_CODE,MANAGER_TYPE,ROWID, enabled_flag
            FROM FND_CONCURRENT_QUEUES
            order by nvl(enabled_flag,'Y') desc, decode(application_id, 0, decode(concurrent_queue_id, 1, 1, 4, 2)), sign(max_processes) desc, concurrent_queue_name, application_id;
     cursor r(conc_id number, applid number) is
            SELECT COUNT(PHASE_CODE)
            FROM FND_CONCURRENT_WORKER_REQUESTS
            WHERE conc_id = CONCURRENT_QUEUE_id
                  AND applid = QUEUE_APPLICATION_ID
                  AND PHASE_CODE = 'R';
     cursor p(conc_id number, applid number) is
            SELECT COUNT(PHASE_CODE)
            FROM FND_CONCURRENT_WORKER_REQUESTS
            WHERE conc_id = CONCURRENT_QUEUE_id
                  AND applid = QUEUE_APPLICATION_ID
                  AND PHASE_CODE = 'P'
                  AND HOLD_FLAG != 'Y'
                  AND REQUESTED_START_DATE <= SYSDATE;

     targetp           number;
     activep           number;
     pmon_method       varchar2(100) := 'a';
     callstat          number;

     l_conc_name       varchar2(100);

     runningp          number;
     pendingp          number;
     Control_nondb     varchar2(100);
     l_color		   varchar2(20);
begin
	if check_license then
		return;
	end if;

     htp.htmlopen;
     htp.headopen;
     htp.title(ctitle => 'DBAdmin Concurrents');
     htp.headclose;
     htp.bodyopen;
     htp.header(1,'Concurrent Managers');
     htp.paragraph;

     begin
           FND_CONCURRENT.GET_MANAGER_STATUS( 0,
                                              1,
                                              TARGETP,
                                              ACTIVEP,
                                              PMON_METHOD,
                                              CALLSTAT);
     end;
     if targetp=0 then
        if activep=0 then
            htp.print('Internal Concurrent is DOWN.');
        else
            htp.print('Internal Concurrent is SHUTTING DOWN.');
        end if;
     else
        htp.print('Internal Concurrent is UP.');
     end if;

     htp.paragraph;

     htp.tableopen(null,null,null,null,'border=1');
     htp.tablerowopen;
     htp.tableheader('Manager Name');
     htp.tableheader('Actual');
     htp.tableheader('Target');
     htp.tableheader('Running');
     htp.tableheader('Pending');
     htp.tableheader('Status');
     for c_rec in c loop
       htp.tablerowopen;

       select user_concurrent_queue_name 
       into l_conc_name
       from fnd_concurrent_queues_vl 
       where concurrent_queue_name=c_rec.concurrent_queue_name
       ;

       htp.tabledata(l_conc_name);
       begin
           FND_CONCURRENT.GET_MANAGER_STATUS( c_rec.APPLICATION_ID,
                                              c_rec.CONCURRENT_QUEUE_ID,
                                              TARGETP,
                                              ACTIVEP,
                                              PMON_METHOD,
                                              CALLSTAT);
       end;
       if activep=0 and targetp>0 then
           l_color := 'red';
       elsif activep<targetp and targetp>0 then
           l_color := 'yellow';
       else
           l_color := 'white';
       end if;
       htp.tabledata(activep,'right',cattributes => 'bgcolor=' || l_color);
       htp.tabledata(targetp,'right');
       open p(c_rec.CONCURRENT_QUEUE_ID,c_rec.APPLICATION_ID);
       fetch p into pendingp;
       close p;
       open  r(c_rec.CONCURRENT_QUEUE_ID,c_rec.APPLICATION_ID);
       fetch r into runningp;
       close r;
       htp.tabledata(runningp,'right');
       htp.tabledata(pendingp,'right');

       IF (c_rec.Control_Code IS NOT NULL) THEN
          SELECT meaning
          INTO Control_nondb
          FROM fnd_lookups L
          WHERE lookup_type = 'CP_CONTROL_CODE'
                and lookup_code = c_rec.Control_Code
                and (lookup_code in ('A', 'D', 'T', 'E', 'X', 'R', 'N')
                         or (lookup_code = 'V'
                             and c_rec.Concurrent_Queue_ID = '1'));
       else
           control_nondb:='';
       END IF;
       if nvl(c_rec.enabled_flag,'Y')='N' then
           control_nondb:= 'Disabled, ' || control_nondb;
       end if;
        
       htp.tabledata(nvl(control_nondb,'&nbsp'));
       htp.tablerowclose;
     end loop;
     htp.tableclose;

     htp.bodyclose;
     htp.htmlclose;
end;

procedure mon2 is

          cursor stuck_concurrents_cur is
            select r.request_id, p.user_concurrent_program_name prog_name,((sysdate - r.actual_start_date) / (1/24/60)) run_time
            from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r
            where  r.phase_code = 'R'
                   and r.concurrent_program_id = p.concurrent_program_id
                   and r.program_application_id=p.application_id
                   and p.concurrent_program_name  != 'FNDWFMAIL'
                   and ((sysdate - r.actual_start_date) / (1/24/60)) > 30;
        
          cursor CONCURRENT_QUEUES_CUR is
            SELECT nvl(user_CONCURRENT_QUEUE_naME,CONCURRENT_QUEUE_naME) user_CONCURRENT_QUEUE_naME,
            MAX_PROCESSES,APPLICATION_ID,CONCURRENT_QUEUE_ID,CONTROL_CODE,MANAGER_TYPE,ROWID
            FROM FND_CONCURRENT_QUEUES_VL
            order by decode(application_id, 0, decode(concurrent_queue_id, 1, 1, 4, 2)), sign(max_processes) desc, concurrent_queue_name, application_id;            
       
            
            targetp            number;
            activep            number;
            callstat          number;
            pmon_method       varchar2(100) := 'a';
            max_pending        number;
            count_pending      number;
            l_default_mail      fnd_user_preferences.preference_value%type;
            l_mail_count       number;
            count_hold          number;
            l_wf_errors         number;
begin
	if check_license then
		return;
	end if;
     
     begin
    FND_CONCURRENT.GET_MANAGER_STATUS( 0,
                                              1,
                                              TARGETP,
                                              ACTIVEP,
                                              PMON_METHOD,
                                              CALLSTAT);
                                                  
                                                        
     if activep=0 then
          if targetp=0 then
              htp.tableopen(cattributes => 'WIDTH=100%');
              htp.tablerowopen(cattributes => 'BGCOLOR="red"');
              htp.strong('Internal Manager: DOWN.');
              htp.tablerowclose;
              htp.tableclose;
          else
              htp.tableopen(cattributes => 'WIDTH=100%');
              htp.tablerowopen(cattributes => 'BGCOLOR="red"');
              htp.print('Internal Manager: CRASHING.');
              htp.tablerowclose;
              htp.tableclose;
          end if;
      else
          if targetp=0 then
              htp.tableopen(cattributes => 'WIDTH=100%');
              htp.tablerowopen(cattributes => 'BGCOLOR="red"');
              htp.print('Internal Manager: SHUTTING DOWN.');
              htp.tablerowclose;
              htp.tableclose;
          else
              htp.tableopen(cattributes => 'WIDTH=100%');
              htp.tablerowopen(cattributes => 'BGCOLOR="#00ff00"');
              htp.print('Internal Manager: OK.');
              htp.tablerowclose;
              htp.tableclose;
          end if;
       end if;
     exception
       when others then
         null;
         --htp.print('Not an oracle applications database.');
     end;           
     
          
     -- warn in case there is a concurrent that is down
     for CONCURRENT_QUEUES_LOOP in CONCURRENT_QUEUES_CUR loop

           FND_CONCURRENT.GET_MANAGER_STATUS( CONCURRENT_QUEUES_LOOP.APPLICATION_ID,
                                              CONCURRENT_QUEUES_LOOP.CONCURRENT_QUEUE_ID,
                                              TARGETP,
                                              ACTIVEP,
                                              PMON_METHOD,
                                              CALLSTAT); 

           if (targetp > 0 and activep = 0) then 
                 htp.tableopen(cattributes => 'WIDTH=100%');
                 htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');  
                 htp.print('Concurrent manager ' || CONCURRENT_QUEUES_LOOP.user_CONCURRENT_QUEUE_name || ' is down!');         
                 htp.tablerowclose;
                 htp.tableclose;
           end if;

     end loop;
     
     -- warn in case there is a concurrent in pending status that runs more than 20 minutes
     select max(((sysdate - r.requested_start_date) / (1/24/60)))
     into   max_pending
     from   fnd_concurrent_requests r
     where  r.phase_code = 'P' 
        and r.status_code in ('I','Q')
        and r.hold_flag='N';
            
     if max_pending > 20 then
        htp.tableopen(cattributes => 'WIDTH=100%');     
        
        if max_pending > 60 then
                htp.tablerowopen(cattributes => 'BGCOLOR="red"');
        else
                htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        end if;
        htp.print('The maximum time of a concurrent in pending status is:' ||  to_char(max_pending,'999,999,999.99') || ' minutes');
        
        htp.tablerowclose;
        htp.tableclose;
     end if;             
            
     -- warn in case there are many concurrents in pending status
     select count(*)
     into   count_pending
     from   fnd_concurrent_requests r
     where  r.phase_code = 'P'
       and  r.requested_start_date <= sysdate
       and  r.requested_start_date > to_date('01-NOV-1998','DD-MON-YYYY')
       and  r.hold_flag = 'N';
       
       
     if count_pending > 30 then
        htp.tableopen(cattributes => 'WIDTH=100%');     
        
        if count_pending > 60 then
                htp.tablerowopen(cattributes => 'BGCOLOR="red"');
        else
                htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        end if;
        htp.print('There are '|| count_pending || ' concurrents in Pending status');
        
        htp.tablerowclose;
        htp.tableclose;
     end if;             

     -- warn in case there are many concurrents in hold status
     select count(*)
     into   count_hold
     from   fnd_concurrent_requests r
     where  r.phase_code = 'P'
       and  r.requested_start_date <= sysdate
       and  r.requested_start_date > to_date('01-NOV-1998','DD-MON-YYYY')
       and  r.hold_flag = 'Y';
       
     if count_hold > 0 then
        htp.tableopen(cattributes => 'WIDTH=100%');     
        htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        htp.print('There are '|| count_hold || ' concurrents in hold status');
        htp.tablerowclose;
        htp.tableclose;
     end if;             
           
     -- warn in case there are concurrents that runs a long time     
     for stuck_concurrents_loop in stuck_concurrents_cur loop
         htp.tableopen(cattributes => 'WIDTH=100%');     
         
         if stuck_concurrents_loop.run_time > 120 then
             htp.tablerowopen(cattributes => 'BGCOLOR="red"');
         else
             htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');         
         end if;
         
         htp.print(stuck_concurrents_loop.request_id || ' - ' || stuck_concurrents_loop.prog_name || ' is running for more than' || to_char(stuck_concurrents_loop.run_time,'999999.99') || ' minutes');         
         htp.tablerowclose;
         htp.tableclose;
     end loop;      
     
     -- Check how many e-mails were not sent by the workflow mailer
     begin
         select up.preference_value
           into l_default_mail
           from fnd_user_preferences up
          where up.user_name='-WF_DEFAULT-'
            and module_name='WF'
            and up.preference_name='MAILTYPE';
     exception
        when no_data_found then
            null;
     end;

     select count(1)
     into l_mail_count
     from wf_notifications n, wf_roles r, wf_item_activity_statuses ias, wf_process_activities pa
     where n.status='OPEN'
     and nvl(n.mail_status,'NONEED') in ('MAIL','ERROR')
     and n.recipient_role=r.name(+)
     and notification_preference not in ('QUERY','SUMMARY')
     and email_address is not null
     and r.status='ACTIVE'
     and ias.notification_id=n.notification_id
     and ias.activity_status='NOTIFIED'
     and pa.instance_id=ias.process_activity
     and n.begin_date < sysdate - 1/24;
 
     if l_mail_count > 0 then
        htp.tableopen(cattributes => 'WIDTH=100%');     
        
        if l_mail_count > DBAX_DBADMIN_constants.MAIL_CRITICAL then
                htp.tablerowopen(cattributes => 'BGCOLOR="red"');
        else
                htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        end if;
        htp.print('There are '|| l_mail_count || ' notifications waiting to be e-mailed. ');
		htp.anchor(curl => base_app || 're_enqueue_notifications', ctext => 'Re-Enqueue');

        htp.tablerowclose;
        htp.tableclose;
     end if;             
     
     select count(1)
     into l_wf_errors
     from wf_item_activity_statuses ias, wf_items i
     where activity_status='ERROR'
     and ias.item_type=i.item_type
     and ias.item_key=i.item_key
     and i.end_date is null;
     
     if l_wf_errors>0 then
        htp.tableopen(cattributes => 'WIDTH=100%');     
        
        if l_wf_errors > DBAX_DBADMIN_constants.WF_CRITICAL then
                htp.tablerowopen(cattributes => 'BGCOLOR="red"');
        else
                htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        end if;
        htp.anchor2(base || 'grid?p_form=17&p_order_by=1&p_order_way=desc','There are '|| l_wf_errors || ' workflow processes in error.','','Workflow' || db_name);

        htp.tablerowclose;
        htp.tableclose;
     end if;             
                     
end;


procedure terminate(p_request_id number, password number default 0) is

    l_phase_code varchar2(10);

begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'terminate');
    htp.headclose;
    htp.bodyopen;

    if dbax_dbadmin_constants.enable_kill_terminate = 1 then
        if nvl(password,0) != dbax_dbadmin_constants.KILL_TERMINATE_PASSWORD then
            -- password is required and was not given - open a form to ask for it
            htp.print('A password is required in order to terminate this request. Please enter password below:<BR>');
            htp.formopen(curl => base_app || 'terminate');
            htp.formhidden('p_request_id',p_request_id);
            htp.formpassword('password');
            htp.print('<BR>');
            htp.formsubmit(cvalue => 'Terminate');
            htp.formclose;
            htp.bodyclose;
            htp.htmlclose;
            return;
        end if;

        select phase_code
          into l_phase_code
          from fnd_concurrent_requests
         where request_id = p_request_id;
    
        if l_phase_code = 'P' then
            update fnd_concurrent_requests
               set status_code      = 'X',
                   phase_code       = 'C',
                   last_updated_by  = DBAX_DBADMIN_constants.app_user,
                   last_update_date = sysdate
             where request_id = p_request_id;
        elsif l_phase_code = 'R' then
            update fnd_concurrent_requests
               set status_code      = 'T',
                   last_updated_by  = DBAX_DBADMIN_constants.app_user,
                   last_update_date = sysdate
             where request_id = p_request_id;
        end if;
        htp.paragraph;
        htp.print('Program ' || to_char(p_request_id) ||
                  ' is being Terminated!');
    else
        htp.print('Terminate functionality has been disabled (ENABLE_KILL_TERMINATE<>1).');
    end if;
    htp.paragraph;
    htp.anchor2(base || 'grid?p_form=8&p_order_way=desc',
                'Click here to go back...',
                '',
                'main');
    htp.paragraph;

    htp.bodyclose;
    htp.htmlclose;

end;

procedure prog_info(p_request_id number) is
    cursor req is
        select r.*, p.USER_CONCURRENT_PROGRAM_NAME
        from fnd_concurrent_requests r, fnd_concurrent_programs_vl p
        where r.request_id=p_request_id
          and r.concurrent_program_id=p.CONCURRENT_PROGRAM_ID
          and r.program_application_id=p.APPLICATION_ID;
begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'Program Information');
    htp.headclose;
    htp.bodyopen;
    htp.header(1,'Program Information');
    htp.paragraph;
    htp.tableopen(cattributes => 'border=1');
    for c in req loop
        htp.tablerowopen;htp.tabledata('Request Id');       htp.tabledata(c.request_id);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('User Program Name');htp.tableData(c.user_concurrent_program_name);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Description');      htp.tableData(nvl(c.description,'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Parameters');       htp.tableData(nvl(c.argument_text,'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Phase');            htp.tableData(c.phase_code);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Status');           htp.tableData(c.status_code);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Requestor');        htp.tableData(c.requested_by);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Date submitted');   htp.tableData(c.request_date);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Requested Start Date');htp.tableData(to_char(c.requested_start_date));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Actual Start Time');htp.tableData(nvl(to_char(c.actual_start_date),'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Date Completed');   htp.tableData(nvl(to_char(c.actual_completion_date),'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Completion Text');  htp.tableData(nvl(c.completion_text,'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Language');         htp.tableData(nvl(to_char(c.language_id),'&nbsp'));htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Style');            htp.tableData(c.print_style);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Schedule');         htp.tableData('&nbsp');htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Printer');          htp.tableData(c.printer);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('Copies');           htp.tableData(c.number_of_copies);htp.tableRowClose;
        htp.tablerowopen;htp.tabledata('<a href="' || base_app || 'view_file?p_request_id=' || c.request_id || '&p_file_type=3" target="log' || c.request_id || '">View Log</a>');         
        htp.tabledata('<a href="' || base_app || 'view_file?p_request_id=' || c.request_id || '&p_file_type=4" target="out' || c.request_id || '">View Output</a>');htp.tableRowClose;
     end loop;
     htp.tableclose;
     htp.paragraph;
     htp.anchor2(base || 'grid?p_form=8&p_order_way=desc','Click here to go back...','','main');
     htp.paragraph;

     htp.bodyclose;
     htp.htmlclose;
end;

procedure patches is
    l_start_date date;
	
    cursor pr is
        select patch_name patch, max(ap.creation_date) install_date
    	from applsys.ad_applied_patches ap
    	group by patch_name
    	order by 2 desc
    	;
		
	cursor mods(patch_name in varchar2) is
		select distinct prb.application_short_name
		from ad_patch_run_bugs prb
		where prb.orig_bug_number=patch_name
		order by 1
		;	
		
	l_temp varchar2(32000);
  
begin
	if check_license then
		return;
	end if;

  	begin
      	l_start_date := to_date(substr(fnd_profile.value('SITENAME'),instr(fnd_profile.value('SITENAME'),' - ')+3),'DD/MM/YYYY HH24:MI');
  	exception
		when others then
			l_start_date:=to_date('01-JAN-1950','DD-MON-YYYY');
	end;
	
	htp.htmlopen;
	htp.bodyopen;
    htp.header(1,'All Patches');
	htp.tableopen(cattributes => 'border=1');
	htp.tablerowopen;
	htp.tableheader('Install Date');
	htp.tableheader('Patch Number');
	htp.tablerowclose;
  	for c in pr loop
		if c.install_date>l_start_date then 
     		htp.tablerowopen(cattributes => 'BGCOLOR="pink"');
		else
			htp.tablerowopen;
		end if;
		htp.tabledata(to_char(c.install_date,'DD/MM/YYYY'));
		htp.tabledata(c.patch);
		l_temp := '';
		for m in mods(c.patch) loop
			l_temp := l_temp || m.application_short_name || ', ';			
		end loop;
		htp.tabledata(substr(l_temp,1,length(l_temp)-2));
		htp.tablerowclose;
  	end loop;
	htp.tableclose;
	htp.bodyclose;
	htp.htmlclose;	
end patches;

procedure re_enqueue_notifications is
  i number;
  cursor cr is
    select n.notification_id, ias.item_type, ias.item_key, ias.process_activity, pa.process_name || ':' || pa.instance_label activity
    from wf_notifications n, wf_roles r, wf_item_activity_statuses ias, wf_process_activities pa
    where n.status='OPEN'
    and nvl(n.mail_status,'MAIL') in ('MAIL','ERROR')
    and n.recipient_role=r.name(+)
    and notification_preference not in ('QUERY','SUMMARY')
    and email_address is not null
    and r.status='ACTIVE'
    and ias.notification_id=n.notification_id
    and ias.activity_status='NOTIFIED'
    and pa.instance_id=ias.process_activity
    and n.begin_date < sysdate - 1/24
    ;

begin
    i := 0;
    htp.p('The following notifications have been requeued:');
    htp.nl;
    for c in cr loop
        wf_engine.handleerror(itemtype => c.item_type, itemkey => c.item_key, activity => c.activity, command => 'RETRY');
        htp.p(c.notification_id);
        htp.nl;
        i := i+1;
    end loop;  
    commit;
    htp.print('Re-enqueued ' || i || ' notifications.');
	htp.nl;
	htp.print('Assuming the notification mailer is running - it will take a couple of minutes for them to be sent');
	htp.nl;
	htp.anchor(curl => 'javascript:history.back(1)',ctext => 'Click here to go back');
end;

procedure before_mrc(p_fromweb varchar2 default 'N') is
    i integer;
    cursor gt is
        select /*+ ORDERED */ u.name owner, o.name object_name
        from sys.user$ u, sys.obj$ o
        where o.type# = 2
        and   o.name not like '%$%'
        and   o.name not like 'SYS_IOT_OVER%'
        and   u.user# = o.owner#
        and   u.user# in 
          (select /*+ ORDERED */ distinct u2.user#
           from applsys.fnd_product_installations i,
                applsys.fnd_oracle_userid o,
                sys.user$ u2
           where 1=1--i.db_status='I'
           and   i.oracle_id = o.oracle_id
--           and   o.read_only_flag in ('E', 'A')
--           and   o.install_group_num in (0, 1)
           and   o.oracle_username = u2.name)
        and 7 <>
          (select count(*)
           from sys.objauth$ oa
           where oa.obj# = o.obj#
           and   oa.grantor# = o.owner#
           and   oa.grantee# = (select user# APPS_UN
                                from sys.user$
                                where name='APPS'))
        union                                
        select /*+ ORDERED */ u.name, o.name
        from sys.user$ u, sys.obj$ o
        where o.type# = 6
        and   o.name not like '%$%'
        and   u.user# = o.owner#
        and   u.user# in 
          (select /*+ ORDERED */ distinct u2.user#
           from applsys.fnd_product_installations i,
                applsys.fnd_oracle_userid o,
                sys.user$ u2
           where 1=1--i.db_status='I'
           and   i.oracle_id = o.oracle_id
--           and   o.read_only_flag in ('E', 'A')
--           and   o.install_group_num in (0, 1)
           and   o.oracle_username = u2.name)
        and 2 <>
          (select count(*)
           from sys.objauth$ oa
           where oa.obj# = o.obj#
           and   oa.grantor# = o.owner#
           and   oa.grantee# = (select user# APPS_UN
                                from sys.user$
                                where name='APPS'));   
        
            cursor syn is
                select synonym_name
                from dba_synonyms s
                where not exists (select 1 from dba_objects
                          where owner = table_owner
                            and object_name = table_name)
                and owner='APPS';

    cursor missing_syn is
        select /*+ ORDERED */ u.name owner,
               o.name object_name,
               decode(o.type#, 2, 'TABLE', 6, 'SEQUENCE', '??') object_type
        from sys.user$ u, sys.obj$ o
        where o.type# in (2, 6)
        and   o.name not like '%$%'
        and   o.name not like 'SYS_IOT_OVER%'
        and   u.user# = o.owner#
        and (  u.user# in
          (select /*+ ORDERED */ distinct u2.user#
           from applsys.fnd_product_installations i,
    	    applsys.fnd_oracle_userid o,
    	    sys.user$ u2
           where 1=1--i.db_status='I'
           and   i.oracle_id = o.oracle_id
--           and   o.read_only_flag in ('E', 'A')
--           and   o.install_group_num in (0, 1)
           and   o.oracle_username = u2.name
           )
           )
        and not exists (select 1 from dba_objects do where do.owner='APPS' and do.object_name=o.name);

    OLD_owner varchar2(30) := '--';
    l_password varchar2(30);
    
    procedure htp_or_dbms(buf in varchar2) is
    begin
        if p_fromweb='Y' then
            htp.p(buf || '<BR>');
        else
            dbms_output.put_line(buf);
        end if;
    end;    
begin
  	if check_license then
		return;
	end if;

    if p_fromweb='Y' then
        htp.htmlopen;
        htp.headopen;
        htp.title(ctitle => 'Before MRC');
        htp.headclose;
        htp.bodyopen;
    end if;
        
    -- Drop bad synonyms
    for syn_rec in syn loop
        htp_or_dbms('drop synonym ' || syn_rec.synonym_name || ';');
    end loop;
    -- Missing synonyms
    for syn_rec in missing_syn loop
        htp_or_dbms('create synonym ' || syn_rec.object_name || ' for ' || syn_rec.owner || '.' || syn_rec.object_name || ';');
    end loop;
    -- Missing Grants
    htp_or_dbms('grant all on wf_event_t to applsys with grant option;');
    for gt_Rec in gt loop
        begin
            if old_owner != gt_Rec.owner then
                if gt_rec.owner = 'APPLSYS' then
                    l_password := 'APPSPWD';
                else
                    if gt_rec.owner in ('List of different users') then
                        l_password := '';
                    else
                        l_password := gt_rec.owner;
                    end if;
                end if;
                htp_or_dbms('Connect ' || gt_rec.owner || '/' || l_password );
                old_owner := gt_rec.owner;
            end if;
            htp_or_dbms('grant all on ' || gt_rec.object_name || ' to apps with grant option;');
        end;
    end loop;
    
    if p_fromweb='Y' then
        htp.bodyclose;
        htp.htmlclose;
    end if;    
   
end before_mrc;

procedure view_file(p_request_id in number,p_file_type in number) is
    l_url varchar2(1000);
begin
    l_url := fnd_webfile.get_url(file_type => p_file_type, id => p_request_id,gwyuid => 'APPLSYSPUB/PUB', two_task => db_name, expire_time => 2);
    owa_util.redirect_url(l_url);
end;

procedure app_info is
    l_instance_name v$instance.instance_name%type;
    l_host_name     v$instance.host_name%type;
    l_version       v$instance.version%type;
    l_log_mode      v$database.log_mode%type;
begin
	htp.htmlopen;
	htp.bodyopen;
    htp.header(1,'Application Information');
	htp.tableopen(cattributes => 'border=1');
	htp.tablerowopen;
	htp.tableheader('Subject');
	htp.tableheader('Value');
	htp.tablerowclose;

    select instance_name, host_name, version 
    into l_instance_name, l_host_name, l_version
    from v$instance;

    select log_mode 
    into l_log_mode 
    from v$database;
    
    htp.p('<tr><td>Instance name (SID)</td><td>' || l_instance_name || '</td></tr>');
    htp.p('<tr><td>Database host</td><td>' || l_host_name || '</td></tr>');
    htp.p('<tr><td>Archive mode</td><td>' || l_log_mode || '</td></tr>');
    htp.p('<tr><td>Site name</td><td>' || fnd_profile.value('SITENAME') || '</td></tr>');
    htp.p('<tr><td>Application web entry point</td><td><a href="' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '" target="_blank">' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '</a></td></tr>');
    htp.p('<tr><td>E-Business Suite Home Page</td><td><a href="' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/oa_servlets/AppsLogin" target="_blank">' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/oa_servlets/AppsLogin</a></td></tr>');
    htp.p('<tr><td>Oracle Application Manager</td><td><a href="' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/servlets/weboam/oam/oamLogin" target="_blank">' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/servlets/weboam/oam/oamLogin</a></td></tr>');
    htp.p('<tr><td>Discoverer Viewer</td><td><a href="' || substr(fnd_profile.value('ICX_DISCOVERER_VIEWER_LAUNCHER'),1,instr(fnd_profile.value('ICX_DISCOVERER_VIEWER_LAUNCHER'),'?')-1) || '" target="_blank">' || substr(fnd_profile.value('ICX_DISCOVERER_VIEWER_LAUNCHER'),1,instr(fnd_profile.value('ICX_DISCOVERER_VIEWER_LAUNCHER'),'?')-1) || '</a></td></tr>');
    htp.p('<tr><td>Discoverer Plus</td><td><a href="' || substr(fnd_profile.value('ICX_DISCOVERER_LAUNCHER'),1,instr(fnd_profile.value('ICX_DISCOVERER_LAUNCHER'),'?')-1) || '" target="_blank">' || substr(fnd_profile.value('ICX_DISCOVERER_LAUNCHER'),1,instr(fnd_profile.value('ICX_DISCOVERER_LAUNCHER'),'?')-1) || '</a></td></tr>');
    htp.p('<tr><td>AOL/J Diagnostics Tests</td><td><a href="' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/OA_HTML/jsp/fnd/aoljtest.jsp" target="_blank">' || fnd_profile.value('APPS_FRAMEWORK_AGENT') || '/OA_HTML/jsp/fnd/aoljtest.jsp</a></td></tr>');
    
    htp.tableclose;

    htp.bodyclose;
    htp.htmlclose;
    
            
end;

procedure retry_workflow(print_only boolean default false) is
    cursor notifs is
        select x.* from (
            select notification_id, decode(message_name,'RETRY _ONLY','RETRY',
            											'RESET_ERROR_MESSAGE','RETRY',
                                                        'DEFAULT_EVENT_ERROR','RAISE_KEY_DATA_PARAM',
                                                        'MSG_FAILURE_NOTIF','RETRY_MSG',
                                                        'DOC_MANAGER_FAILED','RETRY',
                                                        'OMERROR_MSG','RETRY',
                                                        'SUPPTEST_MSG','APPROVED',
                                                        'REQ_COMPLETION_W_URL','#NORESULT',
                                                        /*'APPROVE_PO_REMAINDER','IGNORE',
                                                        'RFQ_NEAR_EXPIRATION','CLOSE',
                                                        'RFQ_COMPLETION','CLOSE',
                                                        'QUOTE_COMPLETION','CLOSE',
                                                        'QUOTE_NEAR_EXPIRATION','CLOSE',
                                                        'APPROVE_REL_REMAINDER','IGNORE',
                                                        'APPROVE_REQ_REMAINDER','IGNORE',*/
                                                        '--UNKNOWN--') action
                ,n.begin_date
                ,n.recipient_role
                ,n.message_type
            from wf_notifications n
            where n.status='OPEN'
            and message_type in ('WFERROR','XDPWFSTD','POERROR','OMERROR','SUPPTEST','FNDCMMSG')   --'APVRMDER'
            --and subject like '%Could not send notification%'
            --and rownum<100
            --and n.recipient_role in ('SYSADMIN','FND_RESP535:21704') 
            --and message_type in ('WFERROR','XDPWFSTD')
            --and message_type ='POERROR'
            --and message_type='POERROR'
            --and n.recipient_role='A176119'
            --and n.begin_date < sysdate - 30
            --and mail_status!='FAILED'
        ) x
        where x.action != '--UNKNOWN--'
        order by x.begin_date;
    ok boolean;
    l_activity varchar2(200);
    l_error_result_code varchar2(100);
    l_error_item_type varchar2(100);
    
    l_action varchar2(100);
begin
    if (fnd_global.user_id = -1) then
        fnd_global.apps_initialize(0, 20420, 1, 0);
    end if;
  
    for c in notifs loop
        l_action := c.action;
        ok := true;
        if c.message_type='WFERROR' then
            begin
                l_activity := wf_notification.getattrtext(c.notification_id,'ERROR_ACTIVITY_LABEL');
                l_error_result_code := wf_notification.getattrtext(c.notification_id,'ERROR_RESULT_CODE');
                l_error_item_type := wf_notification.getattrtext(c.notification_id,'ERROR_ITEM_TYPE');
                
                if l_activity like 'ROOT:%' and l_error_result_code = '#STUCK' then
                    l_action := 'ABORT';
                end if;
                if l_error_item_type in ('POWFRQAG','POWFPOAG') then
                    l_action := 'ABORT';
                end if;
            exception
                when others then
                    null;
            end;
        end if;
        
        if ok then
            if fnd_global.CONC_REQUEST_ID != -1 then
                fnd_file.put_line(fnd_file.log, '-- ' || c.notification_id || ' - ' || c.begin_date || ' - ' || c.recipient_role || ' - ' || l_action);
            end if;

        	if print_only then
                dbms_output.put_line ('-- ' || c.notification_id || ' - ' || c.begin_date || ' - ' || c.recipient_role);
                if c.action != '#NORESULT' then
            	    dbms_output.put_line('exec wf_notification.setattrtext(nid => ' || c.notification_id || ', aname => ''RESULT'', avalue => ''' || l_action|| ''');');
                end if;
                dbms_output.put_line('exec wf_notification.respond(nid => ' || c.notification_id || ', responder => ''SYSADMIN'');');
                dbms_output.put_line('commit;');        
            else
                begin
                    if c.action != '#NORESULT' then
        	            wf_notification.setattrtext(nid => c.notification_id, aname => 'RESULT', avalue => l_action);
                    end if;
        	        wf_notification.respond(nid => c.notification_id, responder => 'SYSADMIN');
        	        commit;
                exception
                    when others then
                        if fnd_global.CONC_REQUEST_ID = -1 then
                            dbms_output.put_line(c.notification_id || ' - ' || sqlerrm);
                        else
                            fnd_file.put_line(fnd_file.log, c.notification_id || ' - ' || sqlerrm);
                        end if;
                end;
            end if;
        end if;
    end loop;
end;

procedure retry_workflow_conc ( errbuf out varchar2,
                            retcode out varchar2 ) is
begin
    begin
        errbuf := '';
        retcode := 0;
        retry_workflow;
    exception
        when others then
            errbuf := sqlerrm;
            retcode := 2;
    end;
end;

begin
    base := 'DBAX_DBADMIN.';
    base_app :='DBAX_DBADMIN_app.';

    dbms_session.set_nls('NLS_LANGUAGE','AMERICAN');
    dbms_session.set_nls('NLS_DATE_FORMAT','''DD/MM/YYYY HH24:MI:SS''');

    select name
    into db_name
    from v$database;
    
end DBAX_DBADMIN_APP;
/
