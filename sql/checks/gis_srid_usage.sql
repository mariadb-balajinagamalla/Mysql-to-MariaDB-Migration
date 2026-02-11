/*
MySQL 8.0 implemented a robust SRS (Spatial Reference System) data dictionary. MariaDB supports GIS data but handles SRID (Spatial Reference Identifier) attributes differently. If your source uses specific SRIDs, you need to verify compatibility.
*/

SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, SRS_ID 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE DATA_TYPE IN ('geometry', 'point', 'linestring', 'polygon')
  AND SRS_ID IS NOT NULL
  AND TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys');
