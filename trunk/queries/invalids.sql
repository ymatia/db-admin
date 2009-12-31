            select OBJECT_TYPE,OWNER,object_name, '<a href="dbax_dbadmin.compile?p_object_type=' || replace(object_type,' ','%20') || '&' || 'p_object_name='|| object_name || '&' || 'p_owner='|| owner || '">Compile</a>'
            from   dba_objects o
            where  o.status='INVALID'
              and not exists (select 1 
                              from  dba_triggers t
                              where t.status='DISABLED'
                                and t.trigger_name=o.object_name
                                and t.owner=o.owner
                                and o.object_type='TRIGGER'
                             )
