/*
If your applications use the MySQL X-Protocol (default port 33060), you must note that MariaDB does not currently support the X-Plugin. You should check if the plugin is active on the source.
*/

SELECT PLUGIN_NAME, PLUGIN_STATUS 
FROM INFORMATION_SCHEMA.PLUGINS 
WHERE PLUGIN_NAME = 'mysqlx';
