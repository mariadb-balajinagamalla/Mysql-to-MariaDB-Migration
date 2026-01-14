SELECT table_schema, table_name, table_collation
FROM information_schema.TABLES
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND table_collation LIKE '%_0900_%'
ORDER BY table_schema, table_name;
