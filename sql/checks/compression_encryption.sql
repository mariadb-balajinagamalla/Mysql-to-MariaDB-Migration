SELECT table_schema, table_name, create_options
FROM information_schema.TABLES
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND (
       create_options LIKE '%COMPRESSED%'
    OR create_options LIKE '%ENCRYPTION%'
    OR row_format IN ('COMPRESSED','ENCRYPTED')
  )
ORDER BY table_schema, table_name;
