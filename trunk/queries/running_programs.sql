  select htf.anchor2('dbax_dbadmin_app.prog_info?p_request_id=' || request_id ,request_id) request_id, DBAX_DBADMIN_app_info.get_user_name(r.requested_by) requestor, 
         phase.meaning phase, status.meaning status, 
         p.user_concurrent_program_name || 
            decode(p.user_concurrent_program_name,'Report Set',' (' || r.description || ')','Check Periodic Alert',' (' || r.description || ')','') user_concurrent_program_name,
         decode(r.phase_code,'R',r.actual_start_date,'P',r.requested_start_date) start_date,
         decode(r.phase_code,'R',to_char((sysdate - r.actual_start_date) / (1/24/60),'999.99')) run_time,
         nvl(r.os_process_id,s.process) os_process,
         p.spid shadow_process,
         s.SID,
         htf.anchor2('dbax_dbadmin_app.terminate?p_request_id=' || request_id ,'Terminate') terminate,
         decode(r.phase_code,'R',htf.anchor2('dbax_dbadmin.kill?sid=' || s.SID || '&' || 'serial=' || s.SERIAL#,'Kill'),'') kill_session
  from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r,
        Fnd_Lookups Phase,
        Fnd_Lookups Status,
        v$session s, v$process p
  where  r.phase_code in ('P','R')
         and r.concurrent_program_id = p.concurrent_program_id
         and r.program_application_id = p.application_id 
         and s.AUDSID (+) =r.oracle_session_id
         and p.addr (+) = s.paddr
    and Phase.Lookup_Type = 'CP_PHASE_CODE'
    AND Phase.Lookup_Code = Decode(Status.Lookup_Code,
                        'H', 'I',
                        'S', 'I',
                        'U', 'I',
                        'M', 'I',
                        R.Phase_Code) AND
Status.Lookup_Type = 'CP_STATUS_CODE' AND
Status.Lookup_Code =
 Decode(R.Phase_Code,
 'P', Decode(R.Hold_Flag,          'Y', 'H',
      Decode(P.Enabled_Flag,       'N', 'U',
      Decode(Sign(R.Requested_Start_Date - SYSDATE),1,'P',
      R.Status_Code))),
 'R', Decode(R.Hold_Flag,          'Y', 'S',
      Decode(R.Status_Code,        'Q', 'B',
                                   'I', 'B',
      R.Status_Code)),
      R.Status_Code)              
