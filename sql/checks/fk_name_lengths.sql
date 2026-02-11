/*
MySQL 8 allows foreign key names up to 64 characters. In some MariaDB configurations and older storage engine versions, these may be truncated or cause errors if they exceed specific internal limits during import.
*/
SELECT CONSTRAINT_SCHEMA, TABLE_NAME, CONSTRAINT_NAME, LENGTH(CONSTRAINT_NAME) as len
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'FOREIGN KEY'
  AND LENGTH(CONSTRAINT_NAME) > 60;
