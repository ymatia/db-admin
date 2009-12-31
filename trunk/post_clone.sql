-- post clone updates:
update dbax_dbadmin_const set param_value=20 where param_name='ROUND_FILE_SIZE_TO';
update dbax_dbadmin_const set param_value=99999 where param_name='MAIL_CRITICAL';
update dbax_dbadmin_const set param_value=99999 where param_name='WF_CRITICAL';
commit;
