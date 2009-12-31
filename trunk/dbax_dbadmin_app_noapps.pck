create or replace package DBAX_DBADMIN_APP is

procedure menu2;

-- Locks Module
procedure locks;

-- Concurrent managers Module
procedure concs;

-- Running Programs Module
procedure terminate(p_request_id number);
procedure prog_info(p_request_id number);

procedure mon2;

procedure patches;

procedure re_enqueue_notifications;

procedure before_mrc;

procedure view_file(p_request_id in number,p_file_type in number);

procedure app_info;

end DBAX_DBADMIN_APP;
/
create or replace package body dbax_dbadmin_app is

procedure menu2 is begin null; end;

-- Locks Module
procedure locks is begin null; end;

-- Concurrent managers Module
procedure concs is begin null; end;

-- Running Programs Module
procedure terminate(p_request_id number) is begin null; end;
procedure prog_info(p_request_id number) is begin null; end;

procedure mon2 is begin null; end;

procedure patches is begin null; end;

procedure re_enqueue_notifications is begin null; end;

procedure before_mrc is begin null; end;

procedure view_file(p_request_id in number,p_file_type in number) is begin null; end;

procedure app_info is begin null; end;

end dbax_dbadmin_app;
/
