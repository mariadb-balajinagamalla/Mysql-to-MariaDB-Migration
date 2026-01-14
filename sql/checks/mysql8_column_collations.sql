SELECT table_schema, table_name, column_name, collation_name
FROM information_schema.COLUMNS
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND collation_name LIKE '%_0900_%'
ORDER BY table_schema, table_name, column_name;
