SELECT engine, COUNT(*) FROM information_schema.TABLES WHERE table_type='BASE TABLE' GROUP BY engine ORDER BY COUNT(*) DESC;
