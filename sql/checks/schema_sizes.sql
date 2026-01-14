SELECT table_schema,
       ROUND(SUM(data_length+index_length)/1024/1024,2) AS size_mb
FROM information_schema.TABLES
GROUP BY table_schema
ORDER BY SUM(data_length+index_length) DESC;
