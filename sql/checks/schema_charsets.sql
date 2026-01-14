SELECT schema_name, default_character_set_name, default_collation_name
FROM information_schema.SCHEMATA
WHERE schema_name NOT IN ('mysql','information_schema','performance_schema','sys')
ORDER BY schema_name;
