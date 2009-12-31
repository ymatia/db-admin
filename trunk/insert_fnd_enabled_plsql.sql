whenever sqlerror continue rollback
begin
	insert into fnd_enabled_plsql values ('PACKAGE','DBAX_DBADMIN','Y',sysdate,0,sysdate,0,-1,null);
	commit;
exception
	when others then
		null; --allready exists
end;
/

begin
	insert into fnd_enabled_plsql values ('PACKAGE','DBAX_DBADMIN_APP','Y',sysdate,0,sysdate,0,-1,null);
	commit;
exception
	when others then
		null; --allready exists
end;
/

declare 
	res boolean; 
begin 
	res:=fnd_profile.save('SIGNONAUDIT:LEVEL','D','SITE'); 
end;
/
