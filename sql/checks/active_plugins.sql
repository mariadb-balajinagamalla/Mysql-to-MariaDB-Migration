SELECT plugin_name, plugin_status
FROM information_schema.PLUGINS
WHERE plugin_status = 'ACTIVE'
ORDER BY plugin_name;
