-- Fill these in
SET @u = 'report_reader';
SET @h = '%';
SET @p = 'REPLACE_WITH_STRONG_PASSWORD';
SET @s = 'your_schema';

-- Create user
SET @sql = CONCAT(
  "CREATE USER IF NOT EXISTS '", REPLACE(@u,"'","''"),
  "'@'", REPLACE(@h,"'","''"),
  "' IDENTIFIED BY '", REPLACE(@p,"'","''"), "'"
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Grant SELECT on schema
SET @sql = CONCAT(
  "GRANT SELECT ON `", REPLACE(@s,"`","``"), "`.* TO '",
  REPLACE(@u,"'","''"), "'@'", REPLACE(@h,"'","''"), "'"
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Grant SHOW VIEW on schema
SET @sql = CONCAT(
  "GRANT SHOW VIEW ON `", REPLACE(@s,"`","``"), "`.* TO '",
  REPLACE(@u,"'","''"), "'@'", REPLACE(@h,"'","''"), "'"
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Apply changes
FLUSH PRIVILEGES;