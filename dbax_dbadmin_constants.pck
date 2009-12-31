create or replace package dbax_dbadmin_constants is

MINIMUM_FILE_SIZE         number;
MAXIMUM_FILE_SIZE         number;
ROUND_FILE_SIZE_TO        number;
YELLOW_INVALIDS			  NUMBER;
RED_INVALIDS              number;
APP_USER  				  number;         -- application user that does the actions
MAIL_CRITICAL 			  number;         -- number of pending e-mails that are OK
WF_CRITICAL               number;
ENABLE_KILL_TERMINATE     number;         -- 1=Allow
KILL_TERMINATE_PASSWORD   number;

procedure create_missing_params;

end dbax_dbadmin_constants;
/
create or replace package body dbax_dbadmin_constants is

procedure add_param(p_name varchar2, p_value number, p_desc varchar2) is
begin
    insert into dbax_dbadmin_const values (p_name, p_value, p_desc);
    commit;
exception
    when others then
        null;
end;

procedure create_missing_params is
begin
    add_param('MINIMUM_FILE_SIZE',200,'The minimum database file size to recommend.');
    add_param('MAXIMUM_FILE_SIZE',1800,'The maximum database file size to recommend.');
    add_param('ROUND_FILE_SIZE_TO',200,'By which steps to recommend resizing of database files.');
    add_param('YELLOW_INVALIDS',100,'Warning level for number of invalids.');
    add_param('RED_INVALIDS',1000,'Critical level for number of invalids.');
    add_param('APP_USER',0,'Application user id who performs the action.');          -- application user that does the actions
    add_param('MAIL_CRITICAL',20,'Critical level for number of notifications waiting to be e-mailed.');         -- number of pending e-mails that are OK
    add_param('WF_CRITICAL',10,'Critical level for number of workflow processes in error.');
    add_param('ENABLE_KILL_TERMINATE',1,'Enable or disable kill and terminate (1=enable).');
    add_param('KILL_TERMINATE_PASSWORD',0,'If this number is >0 and ENABLE_KILL_TERMINATE=1, then it is a mandatory password for killing and terminating.');
end;

function get_value(p_name varchar2) return number is
    l_res   number;
begin
    select param_value
    into l_res
    from dbax_dbadmin_const
    where param_name=p_name;
    
    return l_res;
end;

procedure load_values is
begin
    MINIMUM_FILE_SIZE := get_value('MINIMUM_FILE_SIZE');
    MAXIMUM_FILE_SIZE := get_value('MAXIMUM_FILE_SIZE');
    ROUND_FILE_SIZE_TO := get_value('ROUND_FILE_SIZE_TO');
    YELLOW_INVALIDS := get_value('YELLOW_INVALIDS');
    RED_INVALIDS := get_value('RED_INVALIDS');
    APP_USER := get_value('APP_USER');  -- application user that does the actions
    MAIL_CRITICAL := get_value('MAIL_CRITICAL');        -- number of pending e-mails that are OK
    WF_CRITICAL := get_value('WF_CRITICAL');
    ENABLE_KILL_TERMINATE := get_value('ENABLE_KILL_TERMINATE');
    KILL_TERMINATE_PASSWORD := get_value('KILL_TERMINATE_PASSWORD');
end;

begin
    -- add profiles to table if they do not exist, and load into spec variables
    create_missing_params;
    load_values;

end dbax_dbadmin_constants;
/
