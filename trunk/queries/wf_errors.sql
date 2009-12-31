select ias.begin_date,
       i.item_type,
       i.item_key,
       i.user_key,
       pa.activity_name,
       ias.error_message
  from wf_item_activity_statuses ias, wf_items i, wf_process_activities pa
 where activity_status = 'ERROR'
   and ias.item_type = i.item_type
   and ias.item_key = i.item_key
   and i.end_date is null
   and pa.instance_id = ias.process_activity