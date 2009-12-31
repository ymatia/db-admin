select decode(p.user_concurrent_program_name,
              'Report Set',
              p.description || ' (Report Set)',
              p.user_concurrent_program_name) program,
--       round(min(r.actual_completion_date - r.actual_start_date) * 24 * 60,
--             2) min_minutes,
       round(avg(r.actual_completion_date - r.actual_start_date) * 24 * 60,
             2) average_minutes,
       round(max(r.actual_completion_date - r.actual_start_date) * 24 * 60,
             2) max_minutes,
       round(sum((r.actual_completion_date - r.actual_start_date) * 24 * 60),
             2) total_run_time,
       count(1) num
  from fnd_concurrent_requests r, fnd_concurrent_programs_vl p
 where r.concurrent_program_id = p.concurrent_program_id
   and r.program_application_id = p.application_id
   and r.phase_code = 'C'
   and r.actual_start_date is not null
 group by decode(p.user_concurrent_program_name,
                 'Report Set',
                 p.description || ' (Report Set)',
                 p.user_concurrent_program_name),
          r.resubmit_interval,
          r.resubmit_interval_unit_code