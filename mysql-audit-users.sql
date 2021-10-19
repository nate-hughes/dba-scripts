-- global level
SELECT *
FROM (
  SELECT
  mu.host `Host`,
  mu.user `User`,
  REPLACE(RTRIM(CONCAT(
  IF(mu.Select_priv = 'Y', 'Select ', ''),
  IF(mu.Insert_priv = 'Y', 'Insert ', ''),
  IF(mu.Update_priv = 'Y', 'Update ', ''),
  IF(mu.Delete_priv = 'Y', 'Delete ', ''),
  IF(mu.Create_priv = 'Y', 'Create ', ''),
  IF(mu.Drop_priv = 'Y', 'Drop ', ''),
  IF(mu.Reload_priv = 'Y', 'Reload ', ''),
  IF(mu.Shutdown_priv = 'Y', 'Shutdown ', ''),
  IF(mu.Process_priv = 'Y', 'Process ', ''),
  IF(mu.File_priv = 'Y', 'File ', ''),
  IF(mu.Grant_priv = 'Y', 'Grant ', ''),
  IF(mu.References_priv = 'Y', 'References ', ''),
  IF(mu.Index_priv = 'Y', 'Index ', ''),
  IF(mu.Alter_priv = 'Y', 'Alter ', ''),
  IF(mu.Show_db_priv = 'Y', 'Show_db ', ''),
  IF(mu.Super_priv = 'Y', 'Super ', ''),
  IF(mu.Create_tmp_table_priv = 'Y', 'Create_tmp_table ', ''),
  IF(mu.Lock_tables_priv = 'Y', 'Lock_tables ', ''),
  IF(mu.Execute_priv = 'Y', 'Execute ', ''),
  IF(mu.Repl_slave_priv = 'Y', 'Repl_slave ', ''),
  IF(mu.Repl_client_priv = 'Y', 'Repl_client ', ''),
  IF(mu.Create_view_priv = 'Y', 'Create_view ', ''),
  IF(mu.Show_view_priv = 'Y', 'Show_view ', ''),
  IF(mu.Create_routine_priv = 'Y', 'Create_routine ', ''),
  IF(mu.Alter_routine_priv = 'Y', 'Alter_routine ', ''),
  IF(mu.Create_user_priv = 'Y', 'Create_user ', ''),
  IF(mu.Event_priv = 'Y', 'Event ', ''),
  IF(mu.Trigger_priv = 'Y', 'Trigger ', '')
  )), ' ', ', ') AS `Privileges`
 FROM
  mysql.user mu
 ORDER BY
  mu.Host,
  mu.User ) x
WHERE LENGTH(x.Privileges) > 0;

------------------------------------------------------------------------------------

-- schema level
SELECT 
  md.db `Database`,
  md.user `User`,
  REPLACE(RTRIM(CONCAT(
  IF(md.Select_priv = 'Y', 'Select ', ''),
  IF(md.Insert_priv = 'Y', 'Insert ', ''),
  IF(md.Update_priv = 'Y', 'Update ', ''),
  IF(md.Delete_priv = 'Y', 'Delete ', ''),
  IF(md.Create_priv = 'Y', 'Create ', ''),
  IF(md.Drop_priv = 'Y', 'Drop ', ''),
  IF(md.Grant_priv = 'Y', 'Grant ', ''),
  IF(md.References_priv = 'Y', 'References ', ''),
  IF(md.Index_priv = 'Y', 'Index ', ''),
  IF(md.Alter_priv = 'Y', 'Alter ', ''),
  IF(md.Create_tmp_table_priv = 'Y', 'Create_tmp_table ', ''),
  IF(md.Lock_tables_priv = 'Y', 'Lock_tables ', ''),
  IF(md.Create_view_priv = 'Y', 'Create_view ', ''),
  IF(md.Show_view_priv = 'Y', 'Show_view ', ''),
  IF(md.Create_routine_priv = 'Y', 'Create_routine ', ''),
  IF(md.Alter_routine_priv = 'Y', 'Alter_routine ', ''),
  IF(md.Execute_priv = 'Y', 'Execute ', ''),
  IF(md.Event_priv = 'Y', 'Event ', ''),
  IF(md.Trigger_priv = 'Y', 'Trigger ', '')
  )), ' ', ', ') AS `Privileges`
 FROM
  mysql.db md
 ORDER BY
  md.User,
  md.Db;
  
------------------------------------------------------------------------------------

-- table/view level
SELECT 
  mt.host `Host`,
  mt.user `User`,
  CONCAT(mt.Db, '.', mt.Table_name) `Tables`,
  REPLACE(mt.Table_priv, ',', ', ') AS `Privileges`
 FROM
  mysql.tables_priv mt
 ORDER BY
  mt.Host,
  mt.User,
  mt.Db,
  mt.Table_name;
  
------------------------------------------------------------------------------------
