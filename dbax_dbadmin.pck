create or replace package DBAX_DBADMIN is

  procedure test_license;
  function check_license return boolean;

  -- Grid Procedure
  type col_head_arr is table of varchar2(50) index by binary_integer;
  procedure comma_to_arr(list   in varchar2,
                         arr    out col_head_arr,
                         lenarr out integer);
  procedure grid(p_form      in number,
                 p_order_by  varchar2 default '1',
                 p_order_way varchar2 default 'asc');

  -- Main Module - Display Startup screen and menu
  procedure main;
  procedure intro;
  procedure menu;

  procedure mon;
  procedure mon1;

  -- Dynamic sql function for general use
  function dyn_sql(p_sql in varchar2) return varchar2;

  procedure kill(sid number, serial number, password number default 0);

  -- Tablespaces Module
  function next_file_name(p_file_name varchar2) return varchar2;
  procedure recommend_resize(p_tablespace_name varchar2, p_new_size number);
  procedure datafiles(p_tablespace_name varchar2,
                      p_total           number,
                      p_free            number);

  -- Invalid Objects Module
  procedure compile(p_object_type varchar2,
                    p_object_name varchar2,
                    p_owner       varchar2,
                    password      number default 0);
  procedure compile_all(p_fromweb varchar2 default 'N',
                        password  number default 0);
  procedure compile_all_conc(errbuf out varchar2, retcode out varchar2);

  -- Rebuild Database Indexes
  procedure rebuild_indexes_conc(errbuf out varchar2, retcode out varchar2);
  procedure rebuild_all_indexes;
  procedure rebuild_indexes_list(p_tablespace_name in varchar2);

  procedure shrink_rbs(p_tablespace_name in varchar2);

  procedure user_io_waits;

  procedure large_segments(p_tablespace_name in varchar2);

  procedure resize_all_to_optimal;
  --procedure active_sqls;

  procedure analyze(days number default 14, percent number default 10);

  procedure analyze_conc(errbuf out varchar2, retcode out varchar2);

  procedure no_free_space_4_next_extent(p_tablespace_name in varchar2);

end DBAX_DBADMIN;
/
create or replace package body DBAX_DBADMIN is

  base     varchar2(100); -- base url for the package
  base_app varchar2(100);
  db_name  varchar2(200);

  --need to change this in dbax_dbadmin_app also
  g_version      varchar2(15) := '1.4.5 Beta';
  g_last_changes varchar2(32000) := '
Version 1.4.5 Beta
    - Removed expiry date and changed to open source
Version 1.4.4 Beta
    - Extended date to Jan 1st, 2010
Version 1.4.3 Beta
    - Fixed bug in User I/O Waits query in Oracle 10g and higher.
    - Extended date to Jul 1st, 2009
Version 1.4.2 Beta
    - Extended date to Jan 1st, 2009
Version 1.4.1 Beta
    - Extended date to May 30th, 2008
Version 1.4 Beta
    - Added test of available next free extent (monitor only)
Version 1.3.10 Beta
    - Added Shadow pid also to database users report.
Version 1.3.9 Beta
    - Fixed os process and added shadow pid to Running Programs.
    - Added "Modifiable" column in init.ora screen.
    - Added "Long Running Requests" report.
    - Added "Workflow Errors" report, and a link in the monitor screen.
    - Added CRs in before mrc.
Version 1.3.8 Beta
    - added password protection to kill and terminate (using constant).
    - fixed code to also fit 10g
    - links in the application info open in a new window
Version 1.3.7 Beta
    - added analyze and analyze_conc APIs for analyzing tables not analyzed recently.
    - added DBAX_DBADMIN.resize_all_to_optimal API, that will output a list of all tablespace resizing.
    - added dbax_dbadmin_app.retry_workflow and retry_workflow_conc APIs for retrying errored workflows.
Version 1.3.6 Beta
    - moved constants into a table dbax_dbadmin_const, which you can change and it won''t be overrun
    - added workflow errors to monitor
    - added discoverer, aol/j tests, application manager links to application info
    - added Sid and kill columns to running programs and changed sort order
    - Changed monitor from frameset to one page
    - added an empty dbax_dbadmin_app package for non-apps databases
    - Improved mechanism for recommending tablespace resizing.
    - Fixed bug in monitor - to not show tablespaces that are over 20% free.
    - Modified dbax_profiles_v to also show profiles with no values.
    - Fixed bug with very long db_name
Version 1.3.5
    - added init.ora parameters screen.
    - fixed Bug: monitor doesn''t display tablespaces with zero free space.
    - added view dbax_tablespaces_v to the package, and connected it to Tablespaces form.
    - added view dbax_profiles_v to the package, but it has too many rows, so no screen yet.
    - added temporary space usage screen.
    - added application info screen.
Version 1.3.4
    - Modified the re-enqueue notification process
    - Extended free date to 31-MAY-2006
Version 1.3.3
    - Minor bug fixes
    - Extended date to 31-DEC-2005
Version 1.3.2
	- Fixed "Locks" and "Locks Extended" not showing Blocking/Not Blocking properly.
	- Added list of changes to Intro screen.
	- Added "View Log" and "View Output" functionality in Running Programs.
	- Added "Completed Requests" screen.
Version 1.3.1
	- small fixes - changes in column order
	- removed number formatting from columns which shouldn''t be formatted (process number, patch number, ...)
Version 1.3
	- Changed the tech base to use a specially developed grid - enable sorting, faster development
	- Added User I/O Waits, Active SQLs, Self-Service Sessions, Before MRC
	- Added drill down from Running Programs to the program''s details
Version 1.2b 
	- Added an install.cmd script for installing
	- Added support for non-Oracle Applications databases
	- Created this readme file
Version 1.1b - first public version - still needs work in order to become a "product"
Version 1.0b - first version - all the functionality but badly "wrapped"
';

  procedure test_license is
  begin
    if check_license then
      dbms_output.put_line('License expired.');
    else
      dbms_output.put_line('License is ok.');
    end if;
  end;

  function check_license return boolean is
  begin
    return false;
  end;

  procedure comma_to_arr(list   in varchar2,
                         arr    out col_head_arr,
                         lenarr out integer) is
    l_arr       col_head_arr;
    i           integer;
    str_start   integer;
    arr_counter integer;
  begin
    -- first check if it is null
    if length(list) = 0 then
      arr    := l_arr;
      lenarr := 0;
      return;
    end if;
  
    i           := 1;
    str_start   := 1;
    arr_counter := 0;
    while i <= length(list) + 1 loop
      if i > length(list) or substr(list, i, 1) = ',' then
        arr_counter := arr_counter + 1;
        l_arr(arr_counter) := substr(list, str_start, i - str_start);
        str_start := i + 1;
      end if;
      i := i + 1;
    end loop;
    arr    := l_arr;
    lenarr := arr_counter;
  end;

  -- Grid info
  procedure grid(p_form      in number,
                 p_order_by  varchar2 default '1',
                 p_order_way varchar2 default 'asc') is
    n                  integer;
    g                  col_head_arr;
    c                  number;
    l_temp_num         number;
    l_temp_vc          varchar2(1000);
    l_row_color_column number := 0;
    l_temp_n           number;
    l_counter          number := 0;
  begin
    if check_license then
      return;
    end if;
  
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => dbax_dbadmin_info.headers(p_form));
    htp.script(clanguage => 'JavaScript',
               cscript   => '
        function resort(col, direction) {
            if (direction==2) {
                document.forms.sortform.p_order_way.value="desc";
            } else {
                document.forms.sortform.p_order_way.value="asc";
            }
            document.forms.sortform.p_order_by.value=col;
            document.forms.sortform.submit();
        }
    ');
    htp.style(cstyle => '
        TD {white-space:nowrap;overflow:auto}
    ');
    htp.headclose;
    htp.bodyopen;
    htp.comment('p_sql=' || dbax_dbadmin_info.queries(p_form) ||
                ' order by ' || p_order_by || ' ' || p_order_way);
    htp.header(1, dbax_dbadmin_info.headers(p_form));
    htp.paragraph;
  
    htp.tableopen(cattributes => 'border=1 width="100%"');
    htp.tablerowopen;
    comma_to_arr(list   => dbax_dbadmin_info.column_headers(p_form),
                 arr    => g,
                 lenarr => n);
    for i in 1 .. n loop
      if g(i) = 'ROW_COLOR' then
        l_row_color_column := i;
      else
        htp.tableHeader(replace(g(i), 'NUM:', '') ||
                        '<br><span onclick="resort(' || i ||
                        ',1);">&Delta;</span>&nbsp' ||
                        '&nbsp<span onclick="resort(' || i ||
                        ',2);">&nabla;&nbsp</span>');
      end if;
    end loop;
    htp.tablerowclose;
  
    c := dbms_sql.open_cursor;
    dbms_sql.parse(c,
                   dbax_dbadmin_info.queries(p_form) || ' order by ' ||
                   p_order_by || ' ' || p_order_way,
                   dbms_sql.native);
    --define columns
    for i in 1 .. n loop
      dbms_sql.define_column(c, i, l_temp_vc, 200);
    end loop;
    --execute
    l_temp_num := dbms_sql.execute(c);
    --fetch_rows
    while dbms_sql.fetch_rows(c) > 0 loop
      l_counter := l_counter + 1;
      if l_row_color_column > 0 then
        dbms_sql.column_value(c, l_row_color_column, l_temp_vc);
        htp.tablerowopen(cattributes => 'bgcolor="' || l_temp_vc || '"');
      else
        htp.tablerowopen;
      end if;
      --column value
      for i in 1 .. n loop
        if i != l_row_color_column then
          dbms_sql.column_value(c, i, l_temp_vc);
          l_temp_vc := nvl(replace(l_temp_vc, chr(10), '<BR>'), '&nbsp');
        
          begin
            l_temp_n := to_number(l_temp_vc);
            -- it's a number
          
            if g(i) like 'NUM:%' then
              -- if formatting was requested
              if trunc(l_temp_n) = l_temp_n then
                l_temp_vc := to_char(l_temp_n,
                                     'FM999,999,999,999,999,999,999');
              else
                l_temp_vc := to_char(l_temp_n,
                                     'FM999,999,999,999,999,999,999.99');
              end if;
            end if;
            htp.tabledata(l_temp_vc, calign => 'right');
          exception
            when others then
              -- It's a normal string - print as is - left alighned
              htp.tabledata(l_temp_vc);
          end;
        end if;
      end loop;
      htp.tablerowclose;
    end loop;
    dbms_sql.close_cursor(c);
    htp.print('Total: ' || l_counter); -- This is a trick, you put htp.print inside a table and it appears above it!
    htp.tableclose;
  
    htp.formOpen(curl        => base || 'grid',
                 cmethod     => 'POST',
                 cattributes => 'name="sortform"');
    htp.formhidden(cname => 'p_form', cvalue => p_form);
    htp.formHidden(cname => 'p_order_by', cvalue => p_order_by);
    htp.formHidden(cname => 'p_order_way', cvalue => p_order_way);
    htp.formClose;
  
    htp.bodyclose;
    htp.htmlClose;
  exception
    when others then
      if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
      end if;
      htp.print('Error: ' || sqlerrm);
  end;

  -----------------------------------------------------------------------------------------

  procedure main is
  begin
    htp.print('<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN//3.2">');
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'DBAdmin - ' || db_name);
    htp.framesetopen('', '20%,80%');
    htp.frame(base || 'menu', 'menu');
    htp.frame(base || 'intro', 'main');
    htp.framesetclose;
  
    htp.headclose;
    htp.bodyopen;
    htp.bodyclose;
    htp.htmlclose;
  
  end;

  function dyn_sql(p_sql in varchar2) return varchar2 is
    c      integer;
    result varchar2(4000);
    l_temp number;
  begin
    c := dbms_sql.open_cursor;
    dbms_sql.parse(c, p_sql, dbms_sql.native);
    if upper(p_sql) like 'SELECT%' then
      dbms_sql.define_column(c, 1, result, 4000);
      l_temp := dbms_sql.execute_and_fetch(c);
      if l_temp > 0 then
        dbms_sql.column_value(c, 1, result);
      else
        result := null;
      end if;
    else
      l_temp := dbms_sql.execute(c);
      result := null;
    end if;
    dbms_sql.close_cursor(c);
    return result;
  end;

  procedure mon is
  begin
    if check_license then
      return;
    end if;
  
    htp.htmlopen;
    htp.meta(chttp_equiv => 'Refresh', cname => 'mon', ccontent => '180');
    htp.headopen;
    htp.title('Main Page');
    htp.headclose;
    htp.bodyopen;
    mon1;
    dbax_dbadmin_app.mon2;
    htp.bodyclose;
    htp.htmlclose;
  exception
    when others then
      htp.nl;
      htp.print('Error in dbax_dbadmin.mon procedure:');
      htp.print(sqlerrm);
  end;

  procedure mon1 is
  
    l_tablespace_name dbax_tablespaces_v.tablespace_name%type;
    l_free_percent    dbax_tablespaces_v.free_percent%type;
    l_row_color       dbax_tablespaces_v.row_color%type;
    l_invalid         number;
  
    cursor c4 is
      select tablespace_name, free_percent, row_color
        from dbax_tablespaces_v
       where row_color != 'white'
       order by free_percent;
  
    cursor loaded_users_cur is
      select osuser, value, s.sid sid
        from v$sesstat t, v$session s
       where t.sid = s.sid
         and statistic# = 9
         and value > 10000000
         and type != 'BACKGROUND'
         and s.status <> 'INACTIVE';
  
    /*    cursor stuck_concurrents_cur is
    select p.user_concurrent_program_name prog_name,((sysdate - r.actual_start_date) / (1/24/60)) run_time
    from   fnd_concurrent_programs_vl p, fnd_concurrent_requests r
    where  r.phase_code = 'R'
           and r.concurrent_program_id = p.concurrent_program_id
           and ((sysdate - r.actual_start_date) / (1/24/60)) > 30;  */
  
    --add by Kobi Masika
    cursor no_free_for_next_extent is
      select * from dbax_no_free_4_next_extent;
  begin
    htp.anchor(base || 'main',
               db_name,
               cattributes => 'target="_' || db_name || '"');
    htp.paragraph;
    htp.tableopen(cattributes => 'WIDTH=150');
    htp.tableclose;
  
    -- Added by Kobi Masika 12/04/2007
    -- warn for no free space for next extent
    htp.tableopen(cattributes => 'WIDTH=100%');
    for no_free_for_next_extent_loop in no_free_for_next_extent loop
      if no_free_for_next_extent%rowcount = 1 then
        htp.tablerowopen;
        htp.tabledata('Name');
        htp.tabledata('Max free');
        htp.tabledata('Max next');
        htp.tablerowclose;
      end if;
    
      htp.tablerowopen(cattributes => 'BGCOLOR="red"');
      htp.tabledata(no_free_for_next_extent_loop.TABLESPACE_NAME);
      htp.tabledata(no_free_for_next_extent_loop.max_free);
      htp.tabledata(no_free_for_next_extent_loop.max_next);
      htp.tabledata(htf.anchor2(curl    => base ||
                                           'no_free_space_4_next_extent?p_tablespace_name=' ||
                                           no_free_for_next_extent_loop.TABLESPACE_NAME,
                                ctext   => 'Object List',
                                ctarget => db_name || l_tablespace_name));
      htp.tablerowclose;
    
    end loop;
    htp.tableclose;
  
    htp.tableopen(cattributes => 'WIDTH=100%');
    open c4;
    for i in 1 .. 5 loop
      fetch c4
        into l_tablespace_name, l_free_percent, l_row_color;
      if c4%found then
        htp.tablerowopen(cattributes => 'BGCOLOR="' || l_row_color || '"');
        htp.tabledata(l_tablespace_name);
        htp.tabledata(to_char(l_free_percent, '999.99') || '% free');
        if l_tablespace_name like 'RBS%' then
          htp.tabledata(htf.anchor2(curl    => base ||
                                               'shrink_rbs?p_tablespace_name=' ||
                                               l_tablespace_name,
                                    ctext   => 'Shrink RBS',
                                    ctarget => db_name || l_tablespace_name));
        elsif l_tablespace_name like '%X' then
          htp.tabledata(htf.anchor2(curl    => base ||
                                               'rebuild_indexes_list?p_tablespace_name=' ||
                                               l_tablespace_name,
                                    ctext   => 'rebuild_indexes',
                                    ctarget => db_name || l_tablespace_name));
        else
          htp.tabledata(htf.anchor2(curl    => base ||
                                               'large_segments?p_tablespace_name=' ||
                                               l_tablespace_name,
                                    ctext   => 'Find Large Segments',
                                    ctarget => db_name || l_tablespace_name));
        end if;
        htp.tablerowclose;
      end if;
    end loop;
    close c4;
    htp.tableclose;
  
    select count(object_name)
      into l_invalid
      from dba_objects o
     where o.status = 'INVALID'
       and not exists (select 1
              from dba_triggers t
             where t.status = 'DISABLED'
               and t.trigger_name = o.object_name
               and t.owner = o.owner
               and o.object_type = 'TRIGGER');
  
    htp.tableopen(cattributes => 'WIDTH=100%');
    if l_invalid < DBAX_DBADMIN_constants.YELLOW_INVALIDS then
      htp.tablerowopen(cattributes => 'BGCOLOR="#00ff00"');
    elsif l_invalid < DBAX_DBADMIN_constants.RED_INVALIDS then
      htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
    else
      htp.tablerowopen(cattributes => 'BGCOLOR="red"');
    end if;
    htp.tabledata(to_char(l_invalid) || ' Invalid objects ' ||
                  htf.anchor(curl        => base ||
                                            'compile_all?p_fromweb=Y',
                             ctext       => 'Compile All',
                             cattributes => 'target="_' || db_name || '"'));
    /*     if l_invalid > 10 then
        htp.tabledata(cvalue => 
            htf.formopen(base || 'compile_all') ||
            htf.formsubmit(cvalue => 'Compile All') ||
            htf.formclose 
        );
    end if;*/
    htp.tablerowclose;
    htp.tableclose;
  
    -- Added by Yigal Ozery  30/08/00
    -- warn in case that any user runs a "loaded" program
    for loaded_users_loop in loaded_users_cur loop
      htp.tableopen(cattributes => 'WIDTH=100%');
    
      if loaded_users_loop.sid >= 10 then
        if loaded_users_loop.value > 100000000 then
          htp.tablerowopen(cattributes => 'BGCOLOR="red"');
        else
          htp.tablerowopen(cattributes => 'BGCOLOR="yellow"');
        end if;
      else
        htp.tablerowopen;
      end if;
      htp.tabledata('Logical Reads of : ' || loaded_users_loop.osuser ||
                    ' (SID number: ' || loaded_users_loop.sid ||
                    ')&nbsp is: ' || loaded_users_loop.value);
      htp.tablerowclose;
      htp.tableclose;
    end loop;
  
  exception
    when others then
      htp.nl;
      htp.print('Error in dbax_dbadmin.mon1 procedure:');
      htp.print(sqlerrm);
  end;

  procedure intro is
  begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'DBAdmin Intro');
    htp.headclose;
    htp.bodyopen;
    htp.tableopen(cattributes => 'width=100% height=70%');
    htp.tablerowopen;
    htp.tabledata(htf.header(1,
                             '<font size="+7">DB-Admin</font><BR>Oracle Database/Application Administration Utility') ||
                  htf.nl || htf.header(2, 'Version ' || g_version),
                  calign => 'middle');
    htp.tablerowclose;
    htp.tablerowopen;
    htp.tabledata(replace(g_last_changes, chr(10), '<br>'));
    htp.tablerowclose;
    htp.tableclose;
    htp.paragraph;
    htp.bodyclose;
    htp.htmlclose;
  end;

  procedure menu is
  begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'DBAdmin Intro');
    htp.headclose;
    htp.bodyopen;
    htp.print('<STRONG>Main Menu - ' || db_name || '</STRONG>');
    htp.nl;
    htp.anchor2(base || 'intro', 'Intro Screen', '', 'main');
    htp.nl;
    htp.anchor2(base || 'mon', 'Database Monitor', '', 'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=5&p_order_by=10,5&p_order_way=desc',
                'DataBase Users',
                '',
                'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=4', 'Locks', '', 'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=3&p_order_by=4&p_order_way=asc',
                'Tablespaces',
                '',
                'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=6', 'Invalids', '', 'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=7', 'User I/O Waits', '', 'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=1', 'Active SQLs', '', 'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=14',
                'Init.ora Parameters',
                '',
                'main');
    htp.nl;
    htp.anchor2(base || 'grid?p_form=15&p_order_by=1&p_order_way=desc',
                'Temp Space Usage',
                '',
                'main');
    htp.nl;
  
    dbax_dbadmin_app.menu2;
    htp.paragraph;
    htp.bodyclose;
    htp.htmlclose;
  end;

  procedure kill(sid number, serial number, password number default 0) is
  
    cur    integer;
    l_temp number;
  
  begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'kill');
    htp.headclose;
    htp.bodyopen;
  
    if dbax_dbadmin_constants.ENABLE_KILL_TERMINATE = 1 then
      if nvl(password, 0) != dbax_dbadmin_constants.KILL_TERMINATE_PASSWORD then
        -- password is required and was not given - open a form to ask for it
        htp.print('A password is required in order to kill this session. Please enter password below:<BR>');
        htp.formopen(curl => base || 'kill');
        htp.formhidden('sid', sid);
        htp.formhidden('serial', serial);
        htp.formpassword('password');
        htp.print('<BR>');
        htp.formsubmit(cvalue => 'Kill');
        htp.formclose;
        htp.bodyclose;
        htp.htmlclose;
        return;
      end if;
      begin
        CUR := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(CUR,
                       'alter system kill session ''' || sid || ',' ||
                       serial || '''',
                       dbms_sql.native);
        l_temp := dbms_sql.execute(cur);
        DBMS_SQL.CLOSE_CURSOR(CUR);
      
        htp.print('Sid number ' || to_char(sid) || ' serial# ' ||
                  to_char(serial) || ' was killed!');
      exception
        when others then
          htp.print('Could not kill session - ORA' || sqlcode);
      end;
    else
      htp.print('Kill functionality has been disabled (ENABLE_KILL_TERMINATE<>1).<br>');
      htp.print('You can kill the session by issuing the following command from sqlplus connected as system user:<br>');
      htp.print('alter system kill session ''' || sid || ',' || serial ||
                ''';');
    end if;
    htp.nl;
    --     htp.anchor2(base || 'locks','Click here to go back...','','main');
    htp.paragraph;
    htp.bodyclose;
    htp.htmlclose;
  end;

  function next_file_name(p_file_name varchar2) return varchar2 is
    l_slash_loc      number;
    l_new_name       varchar2(200);
    l_file_name_only varchar2(200);
  begin
    l_slash_loc := instr(p_file_name, '\', -1, 1);
    if l_slash_loc = 0 then
      l_slash_loc := instr(p_file_name, '/', -1, 1);
    end if;
    l_file_name_only := substr(p_file_name, l_slash_loc + 1);
    l_file_name_only := translate(l_file_name_only, '12345678', '23456789');
  
    l_new_name := substr(p_file_name, 1, l_slash_loc) || l_file_name_only;
    if l_new_name <> p_file_name then
      return l_new_name;
    else
      return substr(p_file_name, 1, l_slash_loc) || '--new file name here--';
    end if;
  exception
    when others then
      return '--new file name here--';
  end;

  procedure recommend_resize(p_tablespace_name varchar2, p_new_size number) is
    l_sum           number := 0;
    l_last          varchar2(200);
    l_last_size     number;
    l_file_size     number := 0;
    l_file_count    number := 0;
    l_added_total   number;
    l_new_file_size number;
    cursor c is
      select file_id, file_name, bytes
        from dba_data_files
       where tablespace_name = p_tablespace_name
       order by file_id;
  begin
    --    select 
    --    l_for_30 := round((0.3*p_total-p_free)/0.7/1024/1024);
    for c_rec in c loop
      l_last_size  := round(c_rec.bytes / 1024 / 1024, -1);
      l_sum        := l_sum + l_last_size;
      l_last       := c_rec.file_name;
      l_file_count := l_file_count + 1;
    end loop;
  
    l_added_total := 0;
    for c_rec in c loop
      if l_added_total < p_new_size then
        l_file_size := round(c_rec.bytes / 1024 / 1024, -1);
        if l_file_size < DBAX_DBADMIN_CONSTANTS.MAXIMUM_FILE_SIZE then
          l_new_file_size := l_file_size + p_new_size;
          l_new_file_size := ceil(l_new_file_size /
                                  DBAX_DBADMIN_CONSTANTS.ROUND_FILE_SIZE_TO) *
                             DBAX_DBADMIN_CONSTANTS.ROUND_FILE_SIZE_TO;
          l_new_file_size := least(l_new_file_size,
                                   DBAX_DBADMIN_CONSTANTS.MAXIMUM_FILE_SIZE);
          l_added_total   := l_added_total + l_new_file_size - l_file_size;
          htp.print('alter database datafile ''' || c_rec.file_name ||
                    ''' resize ' || to_char(l_new_file_size) || 'M;'); -- added ' || (l_new_file_size - l_file_size));
          htp.nl;
        end if;
      end if;
    end loop;
    while l_added_total < p_new_size loop
      l_new_file_size := greatest(DBAX_DBADMIN_CONSTANTS.MINIMUM_FILE_SIZE,
                                  p_new_size - l_added_total);
      l_new_file_size := ceil(l_new_file_size /
                              DBAX_DBADMIN_CONSTANTS.ROUND_FILE_SIZE_TO) *
                         DBAX_DBADMIN_CONSTANTS.ROUND_FILE_SIZE_TO;
      l_new_file_size := least(l_new_file_size,
                               DBAX_DBADMIN_CONSTANTS.MAXIMUM_FILE_SIZE);
      l_last          := next_file_name(l_last);
      l_added_total   := l_added_total + l_new_file_size;
      htp.print('alter tablespace ' || p_tablespace_name ||
                ' add datafile ''' || l_last || ''' size ' ||
                l_new_file_size || 'M;'); -- added ' || l_new_file_size );
      htp.nl;
    end loop;
  end;

  procedure datafiles(p_tablespace_name varchar2,
                      p_total           number,
                      p_free            number) is
    cursor c is
      select file_id, file_name, bytes
        from dba_data_files
       where tablespace_name = p_tablespace_name
       order by file_id;
  
  begin
    if check_license then
      return;
    end if;
  
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'DBAdmin Datafiles of ' || p_tablespace_name);
    htp.headclose;
    htp.bodyopen;
    htp.header(1, 'Datafiles of ' || p_tablespace_name || ' tablespace');
    htp.paragraph;
  
    htp.tableopen(null, null, null, null, 'border=1');
    htp.tablerowopen;
    htp.tableheader('ID');
    htp.tableheader('Name');
    htp.tableheader('Size (Mb)');
  
    for c_rec in c loop
      htp.tablerowopen;
      htp.tabledata(c_rec.file_id);
      htp.tabledata(c_rec.file_name);
      htp.tabledata(to_char(round(c_rec.bytes / 1024 / 1024, -1), '99,999'),
                    'right');
      htp.tablerowclose;
      --if l_file_size < round(c_rec.bytes / 1024 / 1024,-1) then
    --   l_file_size := round(c_rec.bytes / 1024 / 1024,-1);
    --end if;
    end loop;
  
    htp.tableclose;
  
    if p_free / p_total * 100 < 20 then
      htp.nl;
      htp.print('Recommendation:');
      htp.nl;
      recommend_resize(p_tablespace_name,
                       round((0.3 * p_total - p_free) / 0.7 / 1024 / 1024));
    end if;
  
    htp.nl;
  
    htp.print('If this is a rollback segment tablespace, you can: ' ||
              htf.anchor2(curl  => base || 'shrink_rbs?p_tablespace_name=' ||
                                   p_tablespace_name,
                          ctext => 'Shrink RBS'));
    htp.nl;
    htp.print('If this is an indexes tablespace, you can: ' ||
              htf.anchor2(curl  => base ||
                                   'rebuild_indexes_list?p_tablespace_name=' ||
                                   p_tablespace_name,
                          ctext => 'Rebuild Indexes'));
    htp.nl;
    htp.print('or you can: ' ||
              htf.anchor2(curl  => base ||
                                   'large_segments?p_tablespace_name=' ||
                                   p_tablespace_name,
                          ctext => 'Find Large Segments'));
  
    htp.bodyclose;
    htp.htmlclose;
  end;

  procedure compile(p_object_type varchar2,
                    p_object_name varchar2,
                    p_owner       varchar2,
                    password      number default 0) is
  
    result varchar2(20);
    cur    integer;
  begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'compile');
    htp.headclose;
    htp.bodyopen;
  
    if nvl(password, 0) != dbax_dbadmin_constants.KILL_TERMINATE_PASSWORD then
      -- password is required and was not given - open a form to ask for it
      htp.print('A password is required in order to compile this object. Please enter password below:<BR>');
      htp.formopen(curl => base || 'compile');
      htp.formhidden('p_object_type', p_object_type);
      htp.formhidden('p_object_name', p_object_name);
      htp.formhidden('p_owner', p_owner);
      htp.formpassword('password');
      htp.print('<BR>');
      htp.formsubmit(cvalue => 'Compile');
      htp.formclose;
      htp.bodyclose;
      htp.htmlclose;
      return;
    end if;
  
    htp.print('Compiling Object: ' || p_object_type || ' ' || p_owner || '.' ||
              p_object_name || ' is being compiled...');
    htp.paragraph;
    begin
      if p_object_type in ('VIEW', 'SEQUENCE', 'TRIGGER') then
        CUR := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(CUR,
                       'alter ' || p_object_type || ' ' || p_owner || '.' ||
                       p_object_name || ' compile',
                       DBMS_SQL.V7);
        DBMS_SQL.CLOSE_CURSOR(CUR);
      else
        dbms_ddl.alter_compile(p_object_type, p_owner, p_object_name);
      end if;
    exception
      when others then
        htp.nl;
        htp.print('Oracle Error: ORA' || sqlcode);
    end;
  
    htp.nl;
  
    select status
      into result
      from dba_objects
     where owner = p_owner
       and object_name = p_object_name
       and object_type = p_object_type;
  
    if result = 'VALID' then
      htp.print('Compiled Successfully!');
    else
      htp.print('Could not compile object.');
    end if;
  
    htp.nl;
    htp.anchor2(base || 'grid?p_form=6',
                'Click here to go back...',
                '',
                'main');
    htp.paragraph;
    htp.bodyclose;
    htp.htmlclose;
  end;

  procedure compile_all(p_fromweb varchar2 default 'N',
                        password  number default 0) is
  
    number_of_invalids     number;
    old_number_of_invalids number;
    cur                    integer;
    cursor d is
      select object_type, owner, object_name
        from all_objects o
       where o.status = 'INVALID'
         and o.object_type in ('PACKAGE BODY', 'PACKAGE', 'PROCEDURE',
              'FUNCTION', 'VIEW', 'SEQUENCE', 'TRIGGER')
            
         and not exists (select 1
                from dba_triggers t
               where t.status = 'DISABLED'
                    
                 and t.trigger_name = o.object_name
                 and t.owner = o.owner
                 and o.object_type = 'TRIGGER')
       order by decode(object_type,
                       'PACKAGE',
                       '1',
                       'PACKAGE BODY',
                       '2',
                       object_type);
  BEGIN
    if upper(p_fromweb) = 'Y' then
      htp.htmlopen;
      htp.headopen;
      htp.title(ctitle => 'DBAdmin Compile All Log');
      htp.headclose;
      htp.bodyopen;
      if nvl(password, 0) != dbax_dbadmin_constants.KILL_TERMINATE_PASSWORD then
        -- password is required and was not given - open a form to ask for it
        htp.print('A password is required in order to compile all the objects. Please enter password below:<BR>');
        htp.formopen(curl => base || 'compile_all');
        htp.formhidden('p_fromweb', p_fromweb);
        htp.formpassword('password');
        htp.print('<BR>');
        htp.formsubmit(cvalue => 'Compile All');
        htp.formclose;
        htp.bodyclose;
        htp.htmlclose;
        return;
      end if;
      htp.print('Compile All Log');
      htp.paragraph;
    end if;
  
    old_number_of_invalids := 0;
    select count(object_name)
      into number_of_invalids
      from all_objects
     where status = 'INVALID'
       and object_type in ('PACKAGE BODY', 'PACKAGE', 'PROCEDURE',
            'FUNCTION', 'VIEW', 'SEQUENCE', 'TRIGGER');
    while old_number_of_invalids <> number_of_invalids loop
      old_number_of_invalids := number_of_invalids;
      for obj in d loop
        begin
          if upper(p_fromweb) = 'Y' then
            htp.print('Compiling ' || obj.object_type || ' ' || obj.owner || '.' ||
                      obj.object_name);
            htp.nl;
          end if;
          if obj.object_type in ('VIEW', 'SEQUENCE', 'TRIGGER') then
            CUR := DBMS_SQL.OPEN_CURSOR;
            DBMS_SQL.PARSE(CUR,
                           'alter ' || obj.object_type || ' ' || obj.owner || '."' ||
                           obj.object_name || '" compile',
                           DBMS_SQL.V7);
            DBMS_SQL.CLOSE_CURSOR(CUR);
            /*                            elsif obj.object_type = 'JAVA CLASS' then   
                                              CUR := DBMS_SQL.OPEN_CURSOR;                            
                                              DBMS_SQL.PARSE (CUR, 'alter ' || obj.object_type || ' ' || obj.owner || '."' || obj.object_name || '" resolve', DBMS_SQL.V7);           
                                              DBMS_SQL.CLOSE_CURSOR(CUR);                             
            */
          else
            dbms_ddl.alter_compile(obj.object_type,
                                   obj.owner,
                                   obj.object_name);
          end if;
        exception
          when others then
            if upper(p_fromweb) = 'Y' then
              htp.print(obj.object_name || ' Not Compiled.');
              htp.nl;
            end if;
        end;
      end loop;
    
      select count(object_name)
        into number_of_invalids
        from all_objects
       where status = 'INVALID'
         and object_type in ('PACKAGE BODY', 'PACKAGE', 'PROCEDURE',
              'FUNCTION', 'VIEW', 'SEQUENCE', 'TRIGGER');
    end loop;
  
    if upper(p_fromweb) = 'Y' then
      htp.bodyclose;
      htp.htmlclose;
    end if;
  end;

  procedure compile_all_conc(errbuf out varchar2, retcode out varchar2) is
  begin
    begin
      errbuf  := '';
      retcode := 0;
      compile_all;
    exception
      when others then
        errbuf  := sqlerrm;
        retcode := 2;
    end;
  end;

  procedure rebuild_indexes_conc(errbuf out varchar2, retcode out varchar2) is
  
    f   utl_file.file_type;
    g   utl_file.file_type;
    cur integer;
    cursor c is
      select index_name, OWNER, tablespace_name
        from all_indexes
       where owner not in ('SYS', 'SYSTEM');
    l_index_name all_indexes.index_name%type;
    l_owner      all_indexes.owner%type;
  
    l_directory varchar2(200);
  
  begin
  
    errbuf  := '';
    retcode := '0';
  
    select substr(value, 1, instr(value, ',') - 1)
      into l_directory
      from v$parameter
     where name = 'utl_file_dir';
  
    f := utl_file.fopen(location  => l_directory,
                        filename  => 'Index_rebuild.log',
                        open_mode => 'w');
    g := utl_file.fopen(location  => l_directory,
                        filename  => 'Index_rebuild.err',
                        open_mode => 'w');
    utl_file.put_line(g,
                      '--The following indexes need rebuilding. Run This script at a later hour.');
    for c_rec in c loop
      l_owner      := c_rec.owner;
      l_index_name := c_rec.index_name;
      utl_file.put(f,
                   'rebuilding ' || l_owner || '.' || l_index_name ||
                   ' ... tablespace:' || c_rec.tablespace_name);
      begin
        CUR := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(CUR,
                       'alter index ' || l_owner || '."' || l_index_name ||
                       '" rebuild tablespace ' || c_rec.tablespace_name,
                       DBMS_SQL.V7);
        DBMS_SQL.CLOSE_CURSOR(CUR);
        utl_file.put_line(f, 'rebuilded.');
      exception
        when others then
          utl_file.put_line(f, 'got error: ' || sqlcode);
          utl_file.put_line(g,
                            'alter index ' || l_owner || '."' ||
                            l_index_name || '" rebuild tablespace ' ||
                            c_rec.tablespace_name || ';');
          --              errbuf := errbuf || newline || 'got error: ' || sqlcode || ' in ' || l_index_name;
          if dbms_sql.is_open(cur) then
            dbms_sql.close_cursor(cur);
          end if;
      end;
    end loop;
    utl_file.put_line(f, '');
    utl_file.put_line(f,
                      'Finished Rebuilding. Check ' || l_directory ||
                      '\index_rebuild.err to find errors in rebuilds.');
    errbuf := 'Finished Rebuilding. Check ' || l_directory ||
              '\index_rebuild.err to find errors in rebuilds.';
    utl_file.fclose(file => f);
    utl_file.fclose(file => g);
  exception
    when others then
      if utl_file.is_open(f) then
        utl_file.put_line(f, 'got error: ' || sqlcode);
      end if;
      if utl_file.is_open(f) then
        utl_file.fclose(file => f);
      end if;
      if utl_file.is_open(g) then
        utl_file.fclose(file => g);
      end if;
      if dbms_sql.is_open(cur) then
        dbms_sql.close_cursor(cur);
      end if;
      -- Retrieve error message into errbuf
      errbuf := errbuf || 'ORA' || sqlcode || ' : ' || sqlerrm;
      -- Return 2 for error.
      retcode := '2';
      raise;
    
  end rebuild_indexes_conc;

  procedure rebuild_all_indexes is
    p_param1 varchar2(2000);
    p_param2 varchar2(2000);
  begin
    rebuild_indexes_conc(p_param1, p_param2);
  end rebuild_all_indexes;

  procedure rebuild_indexes_list(p_tablespace_name in varchar2) is
    cursor ind is
      select 'alter index ' || s.owner || '.' || s.segment_name ||
             ' rebuild tablespace ' || s.tablespace_name ||
             ' storage (initial ' ||
             least(ceil(s.bytes / 1024 / 1024 * 0.5), 20) || 'M next ' ||
             least(ceil(s.bytes / 1024 / 1024 * 0.2), 20) || 'M);' str
        from dba_segments s
       where s.extents > 10
         and s.bytes < s.extents * 20 * 1024 * 1024 * 0.9
         and s.segment_type = 'INDEX'
         and s.tablespace_name = p_tablespace_name
       order by bytes desc;
  begin
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'Rebuild Indexes for tablespace ' ||
                        p_tablespace_name);
    htp.headclose;
    htp.bodyopen;
    htp.header(1, 'Rebuild Indexes for tablespace ' || p_tablespace_name);
    htp.paragraph;
  
    for c in ind loop
      htp.print(c.str);
      htp.nl;
    end loop;
  
    htp.bodyclose;
    htp.htmlClose;
  end rebuild_indexes_list;

  procedure shrink_rbs(p_tablespace_name in varchar2) is
    cursor rb is
      select 'alter rollback segment ' || segment_name || ' shrink;' str
        from dba_rollback_segs s
       where s.tablespace_name = p_tablespace_name;
  
  begin
    if check_license then
      return;
    end if;
  
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'Shrink Rollback Segments');
    htp.headclose;
    htp.bodyopen;
    htp.header(1, 'Shrink Rollback Segments');
    htp.paragraph;
  
    for c in rb loop
      htp.print(c.str);
      htp.nl;
    end loop;
  
    htp.bodyclose;
    htp.htmlClose;
  end;

  procedure resize_all_to_optimal is
    cursor tbs is
      select tablespace_name, need_for_30
        from dbax_tablespaces_v t
       where t.free_percent < 20
      --        and rownum<5
       order by free_percent;
  begin
    if check_license then
      return;
    end if;
  
    for c in tbs loop
      recommend_resize(c.tablespace_name,
                       round(c.need_for_30 / 1024 / 1024));
    end loop;
  end;

  procedure user_io_waits is
    l_db_files number;
    cursor waits is
      select sw.sid,
             sw.event,
             sw.state,
             s.serial#,
             s.osuser,
             s.process,
             s.module,
             s.action,
             s.last_call_et,
             d.file_name
      --        ,sw.*,s.*,d.*
        from v$session_wait sw,
             v$session s,
             (select file_id, file_name
                from dba_data_files
              union all
              select file_id + l_db_files, file_name from dba_temp_files) d
       where sw.sid = s.sid
         and s.type = 'USER'
         and sw.p1text in ('file#', 'file number')
         and d.file_id = sw.p1
         and sw.event not in ('SQL*Net message from client', 'pipe get',
              'rdbms ipc message', 'wakeup time manager')
       order by sw.seconds_in_wait desc;
  begin
    if check_license then
      return;
    end if;
  
    select p.value
      into l_db_files
      from v$parameter p
     where name = 'db_files';
  
    htp.header(nsize => 1, cheader => 'User I/O Waits');
  
    htp.tableopen(null, null, null, null, 'border=1');
    htp.tablerowopen;
    htp.tableheader('Sid');
    htp.tableheader('Os User');
    htp.tableheader('Process');
    htp.tableheader('Module & Action');
    htp.tableheader('Run Time');
    htp.tableheader('File Name');
    htp.tableheader('Kill');
    htp.tablerowclose;
    for c in waits loop
      htp.tablerowopen;
      htp.tabledata(c.sid);
      htp.tabledata(c.osuser);
      htp.tabledata(c.Process);
      htp.tabledata(c.Module || ' - ' || c.Action);
      htp.tabledata(c.last_call_et);
      htp.tabledata(c.file_name);
      htp.print('<TD>' ||
                htf.anchor2(base || 'kill?sid=' || to_char(c.sid) || '&' ||
                            'serial=' || c.serial#,
                            'Kill',
                            '',
                            'main') || '</TD>');
      htp.tablerowclose;
    end loop;
    htp.tableclose;
  end;

  procedure large_segments(p_tablespace_name in varchar2) is
    cursor large_Segs is
      select owner, segment_name, extents, s.bytes / 1024 / 1024 size_mb
        from dba_segments s
       where tablespace_name = p_tablespace_name
         and s.bytes > 1024 * 1024
       order by s.bytes desc;
  begin
    if check_license then
      return;
    end if;
  
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'Find Large Segments in tablespace ' ||
                        p_tablespace_name);
    htp.headclose;
    htp.bodyopen;
    htp.header(1,
               'Find Large Segments in tablespace ' || p_tablespace_name);
    htp.paragraph;
  
    htp.tableopen(null, null, null, null, 'border=1');
    htp.tablerowopen;
    htp.tableheader('Owner');
    htp.tableheader('Segment Name');
    htp.tableheader('Extents');
    htp.tableheader('Size (Mb)');
    htp.tablerowclose;
    for c in large_segs loop
      htp.tablerowopen;
      htp.tabledata(c.owner);
      htp.tabledata(c.segment_name);
      htp.tabledata(c.extents);
      htp.tabledata(c.size_mb);
      htp.tablerowclose;
    end loop;
    htp.tableclose;
  
    htp.bodyclose;
    htp.htmlClose;
  
  end large_segments;

  procedure analyze(days number default 14, percent number default 10) is
    cursor to_analyze is
      select owner, table_name
        from dba_tables t
       where t.last_analyzed < sysdate - days
         and t.tablespace_name not in ('SYSTEM', 'CTXD')
         and temporary = 'N';
    l_cmd varchar2(1000);
    cur     integer;
  begin
    for c in to_analyze loop
      begin
        l_cmd := 'analyze table ' || c.owner || '.' || c.table_name ||
                 ' estimate statistics sample ' || percent || ' percent';
      
        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, l_cmd, dbms_sql.native);
        dbms_sql.close_cursor(cur);
      
        --execute immediate l_cmd;
        --dbms_output.put_line(l_cmd);
      exception
        when others then
          if dbms_sql.is_open(cur) then
            dbms_sql.close_cursor(cur);
          end if;
          dbms_output.put_line(c.owner || '.' || c.table_name || ' - ' ||
                               sqlerrm);
      end;
    end loop;
  end;

  procedure analyze_conc(errbuf out varchar2, retcode out varchar2) is
  begin
    retcode := 0;
    errbuf  := '';
    analyze;
  exception
    when others then
      errbuf  := sqlerrm;
      retcode := 2;
  end;

  procedure no_free_space_4_next_extent(p_tablespace_name in varchar2) is
  
    l_max_free number;
  
    cursor object_list is
      select s.owner,
             s.segment_name,
             s.segment_type,
             s.next_extent,
             l_max_free - s.next_extent space_missing
        from dba_segments s
       where s.tablespace_name = p_tablespace_name
         and s.next_extent > l_max_free
       order by s.segment_type desc;
  
  begin
    if check_license then
      return;
    end if;
  
    begin
      select max(d.bytes)
        into l_max_free
        from dba_free_space d
       where d.tablespace_name = p_tablespace_name;
    exception
      when no_data_found then
        l_max_free := 0;
    end;
    htp.htmlopen;
    htp.headopen;
    htp.title(ctitle => 'No free space for next extent in tablespace ' ||
                        p_tablespace_name);
    htp.headclose;
    htp.bodyopen;
    htp.header(1,
               'Max free space in ' || p_tablespace_name || ' is : ' ||
               l_max_free || ' Bytes');
    htp.header(3, 'No free space for next extent of the next objects :');
  
    htp.tableopen(null, null, null, null, 'border=1');
    htp.tablerowopen;
    htp.tableheader('Owner');
    htp.tableheader('Object Name');
    htp.tableheader('Object Type');
    htp.tableheader('Next Extent');
    htp.tableheader('Space Missing');
    htp.tablerowclose;
  
    for c in object_list loop
      htp.tablerowopen;
      htp.tabledata(c.owner);
      htp.tabledata(c.segment_name);
      htp.tabledata(c.segment_type);
      htp.tabledata(c.next_extent);
      htp.tabledata(c.space_missing);
      htp.tablerowclose;
    end loop;
  
    htp.tableclose;
  
    htp.bodyclose;
    htp.htmlClose;
  
  end no_free_space_4_next_extent;

begin
  dbms_session.set_nls('NLS_LANGUAGE', 'AMERICAN');
  dbms_session.set_nls('NLS_DATE_FORMAT', '''DD/MM/YYYY HH24:MI:SS''');

  base     := 'DBAX_DBADMIN.';
  base_app := 'DBAX_DBADMIN_app.';

  select instance_name || '_' || host_name into db_name from v$instance d;

exception
  when others then
    htp.nl;
    htp.print('Error in dbax_dbadmin package:');
    htp.print(sqlerrm);
end DBAX_DBADMIN;
/
