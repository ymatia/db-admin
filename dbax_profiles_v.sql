create or replace view dbax_profiles_v as 
select p.user_profile_option_name, decode(pv.level_id,10001,'Site',10002,'Application',10003,'Responsibility',10004,'User') level_desc, x.level_meaning, pv.profile_option_value, p.profile_option_name
from fnd_profile_options_vl p, fnd_profile_option_values pv, 
(
select 10001 level_id, 0 level_value, 'Site' level_meaning
from dual
union all
select 10002 level_id, a.application_id level_value, a.application_name level_meaning
from fnd_application_vl a
--where a.application_id=pv.application_id
union all
select 10003 level_id, r.responsibility_id level_value, r.responsibility_name level_meaning
from fnd_responsibility_vl r
union all
select 10004 level_id, u.user_id level_value, u.user_name level_meaning
from fnd_user u
) x
where 1=1
--and p.profile_option_name='ICX_SESSION_TIMEOUT'
and p.application_id = pv.application_id (+)
and p.profile_option_id = pv.profile_option_id (+)
and x.level_value (+) = pv.level_value
and x.level_id (+)= pv.level_id;
