create or replace view dbax_no_free_4_next_extent as
select * from (
select f.tablespace_name , 
       sum(f.bytes) tb_size ,
       max(d.bytes) max_free ,
       max(next_extent) max_next
from   dba_data_files f,
       dba_free_space d,
       (select t.name , 
               max(e.extsize * t.blocksize) next_extent       
        from   sys.seg$ e ,
               sys.ts$  t
        where e.ts# = t.ts#
        group by t.name 
        ) n       
where  f.autoextensible='NO'
and    f.tablespace_name = d.tablespace_name
and    n.name = f.tablespace_name
group by f.tablespace_name)
where max_next > max_free;
