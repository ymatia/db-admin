  select htf.anchor2('dbax_dbadmin_app.prog_info?p_request_id=' || request_id ,request_id) request_id, DBAX_DBADMIN_app_info.get_user_name(r.requested_by) requestor, 
         status.meaning status, 
         p.user_concurrent_program_name,                 
         r.actual_start_date start_date,
         to_char((r.actual_completion_date - r.actual_start_date) / (1/24/60),'999,999,999.99') run_time
  from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r,
        Fnd_Lookups Status
  where  r.phase_code='C'
         and r.concurrent_program_id = p.concurrent_program_id
         and r.program_application_id = p.application_id 
and Status.Lookup_Type = 'CP_STATUS_CODE'
and Status.Lookup_Code =
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
and r.actual_completion_date > sysdate-1/12