SELECT 'VIEW' AS object_type, DEFINER, COUNT(*) AS cnt
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
GROUP BY DEFINER

UNION ALL

SELECT 'TRIGGER' AS object_type, DEFINER, COUNT(*) AS cnt
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
GROUP BY DEFINER

UNION ALL

SELECT 'ROUTINE' AS object_type, DEFINER, COUNT(*) AS cnt
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
GROUP BY DEFINER

UNION ALL

SELECT 'EVENT' AS object_type, DEFINER, COUNT(*) AS cnt
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
GROUP BY DEFINER

ORDER BY object_type, DEFINER;
