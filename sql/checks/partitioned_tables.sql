SELECT t.table_schema, t.table_name, t.engine
FROM information_schema.TABLES t
JOIN information_schema.PARTITIONS p
  ON p.table_schema = t.table_schema
 AND p.table_name = t.table_name
WHERE t.table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND p.partition_name IS NOT NULL
GROUP BY t.table_schema, t.table_name, t.engine
ORDER BY t.table_schema, t.table_name;
