	    select
            l.sid session_id,
            dbax_dbadmin_info.get_object_by_id(l3.id1) lock_id1,
        	decode(lmode, 
        		0, 'None',           /* Mon Lock equivalent */
        		1, 'Null',           /* N */
        		2, 'Row-S (SS)',     /* L */
        		3, 'Row-X (SX)',     /* R */
        		4, 'Share',          /* S */
        		5, 'S/Row-X (SSX)',  /* C */
        		6, 'Exclusive',      /* X */
        		to_char(lmode)) mode_held,
                 decode(request,
        		0, 'None',           /* Mon Lock equivalent */
        		1, 'Null',           /* N */
        		2, 'Row-S (SS)',     /* L */
        		3, 'Row-X (SX)',     /* R */
        		4, 'Share',          /* S */
        		5, 'S/Row-X (SSX)',  /* C */
        		6, 'Exclusive',      /* X */
        		to_char(request)) mode_requested,
        	 ctime last_convert,
        	 decode(block,
        	        0, 'Not Blocking',  /* Not blocking any other processes */
        		1, 'Blocking',      /* This lock blocks other processes */
        		2, 'Global',        /* This lock is global, so we can't tell */
        		to_char(block)) blocking_others,
                dbax_dbadmin_info.get_session_terminal(l.SID) terminal,
                dbax_dbadmin_info.get_session_username(l.sid) username,
                '<a href="'||'dbax_dbadmin.' || 'kill?sid='|| l.sid || '&' || 'serial=' || dbax_dbadmin_info.get_session_serial#(l.SID)||'" target="main">Kill</a>' drilldown,
                decode(block,1,'red','white') row_color
         from v$lock l, (select l2.sid, l2.id1 from v$lock l2 where l2.type='TM') l3
         where l.type='TX'
         and l3.sid=l.sid
