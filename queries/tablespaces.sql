create or replace view dbax_tablespaces as
            select d.tablespace_name,
                   sum(d.bytes) Total,
                   nvl(f.free_bytes,0) Free,
                   round(nvl(f.free_bytes,0) / sum(d.bytes) * 100,2) free_percent,
                   round((0.3*sum(d.bytes)-nvl(f.free_bytes,0))/0.7) need_for_30,
                   round((sum(d.bytes) + (round((0.3*sum(d.bytes)-nvl(f.free_bytes,0))/0.7)))/1024/1024) optimal_30,
                   '<a href="dbax_dbadmin.datafiles?p_tablespace_name=' || d.tablespace_name || '&' || 'p_total=' || sum(d.bytes) || '&' || 'p_free=' || nvl(f.free_bytes,0)||'" target="main">Datafiles</a>' drilldown,
                   decode(trunc(nvl(f.free_bytes,0) / sum(d.bytes) * 100,-1),0,'red',10,'yellow','white') row_color
            from   dba_data_files d,
            (select tablespace_name, sum(bytes) free_bytes from dba_free_space group by tablespace_name) f
            where  d.tablespace_name=f.tablespace_name(+)
            group by d.tablespace_name, f.free_bytes
