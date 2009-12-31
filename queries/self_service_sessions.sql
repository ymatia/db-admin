select /*+rule*/ first_connect, round((sysdate-last_connect)*24*60,2) idle, u.user_name, p.full_name, f.user_function_name
from icx_sessions s, fnd_user u, per_all_people_f p, fnd_form_functions_tl f
where 1=1
and s.last_connect > sysdate-1/24/6
and u.user_id(+)=s.user_id
and p.person_id(+)=u.employee_id
and p.effective_start_date (+) <= sysdate
and p.effective_end_date (+) >= sysdate
and f.function_id(+)=s.function_id
and f.language(+)='US'
and s.user_id!=-1