select num,
       name,
       replace(replace(value, ',', chr(10)), ' ', ''),
       decode(isdefault, 'TRUE', 'Yes', 'No') isdefault,
       decode(issys_modifiable , 'TRUE', 'Yes', 'No') issys_modifiable,       
       decode(isdefault, 'TRUE', 'White', 'Yellow') row_color
  from v$parameter
