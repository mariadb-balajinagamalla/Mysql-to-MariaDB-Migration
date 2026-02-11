/*
MySQL 8 allows multiple triggers for the same event and uses FOLLOWS or PRECEDES to define execution order. 
MariaDB 11 uses creation order or manual priority in some versions, but the FOLLOWS/PRECEDES syntax in your dump might cause errors.
*/

SELECT TRIGGER_SCHEMA, EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION, COUNT(*) 
FROM INFORMATION_SCHEMA.TRIGGERS 
GROUP BY TRIGGER_SCHEMA, EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION 
HAVING COUNT(*) > 1;
