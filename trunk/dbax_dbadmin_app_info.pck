create or replace package DBAX_DBADMIN_APP_INFO is

function get_user_name(usr_id number) return varchar2;
function get_usr_conc_queue_name(conc_queue_name varchar2) return varchar2;
function get_full_name (p_person_id in number) return per_people_v7.full_name%type;
function get_work_telephone (p_person_id in number) return per_people_v7.work_telephone%type;
function get_full_name_by_sid (p_sid in number) return per_people_v7.full_name%type;
function get_moudles_by_patch_name (p_patch_name in varchar2) return varchar2;

end DBAX_DBADMIN_APP_INFO;
/
create or replace package body DBAX_DBADMIN_APP_INFO is

function get_user_name(usr_id number) return varchar2 is
     usr_name varchar2(256);
begin
     select  f.user_name
     into usr_name 
     from fnd_user f
     where f.user_id = usr_id;
     
     return usr_name;
exception 
    when no_data_found then
          return '';
end;

function get_usr_conc_queue_name(conc_queue_name varchar2) return varchar2 is

     user_conc varchar2(256);
begin
         select user_concurrent_queue_name 
         into   user_conc
         from   fnd_concurrent_queues_vl 
         where  concurrent_queue_name= conc_queue_name;
         
         return (user_conc);
         
         exception when no_data_found then
                   return '';
         
end;

function get_full_name (p_person_id in number) return per_people_v7.full_name%type is
    result per_people_v7.full_name%type;
begin
    if p_person_id is null then
        return null;
    end if;
    
    select full_name
    into result
    from per_people_v7
    where person_id=p_person_id;
    
    return result;
exception
    when others then
        return null;
end;
        
function get_work_telephone (p_person_id in number) return per_people_v7.work_telephone%type is
    result per_people_v7.work_telephone%type;
begin
    if p_person_id is null then
        return null;
    end if;
    
    select p.work_telephone
    into result
    from per_people_v7 p
    where person_id=p_person_id;
    
    return result;
exception
    when others then
        return null;
end;

function get_full_name_by_sid (p_sid in number) return per_people_v7.full_name%type is
    l_process           v$session.process%type;
    l_employee_id       number;
    l_user_name         fnd_user.user_name%type;
    l_full_name        varchar2(300);

begin
    select s.process
    into l_process
    from v$session s
    where s.sid=p_sid;

    begin
       select v.employee_id, v.user_name
       into l_employee_id, l_user_name
       from DBAX_DBADMIN_v v
       where v.process=l_process
          or l_process like v.process || ':%';
   
       if l_employee_id is not null then
           select p.full_name || decode(p.work_telephone,null,null,' (' || p.work_telephone || ')')
           into l_full_name
           from per_people_v7 p
           where p.person_id=l_employee_id;
       else
           l_full_name := l_user_name;
       end if;
    exception
       when others then
           l_full_name := null;
    end;  
    return l_full_name;
end;

function get_moudles_by_patch_name (p_patch_name in varchar2) return varchar2 is
    res varchar2(4000);
    cursor mods is
        select distinct prb.application_short_name
        from ad_applied_patches ap, AD_PATCH_DRIVERS pd, AD_PATCH_RUNS pr, ad_patch_run_bugs prb
        where ap.patch_name=p_patch_name
        and pd.applied_patch_id=ap.applied_patch_id
        and pr.patch_driver_id=pd.patch_driver_id
        and prb.patch_run_id=pr.patch_run_id;
    
begin
    res := '';
    for c in mods loop
        res := res || ', ' || c.application_short_name;
    end loop;
    return substr(res,3);
end;

end DBAX_DBADMIN_APP_INFO;
/
