SELECT table_schema, table_name, column_name, data_type
FROM information_schema.COLUMNS
WHERE data_type='json'
AND table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
ORDER BY table_schema, table_name, column_name;
