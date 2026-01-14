SELECT user, host, plugin FROM mysql.user WHERE user NOT IN ('mysql.infoschema','mysql.session','mysql.sys') AND (plugin LIKE '%sha%' OR plugin LIKE '%caching_sha2%') ORDER BY user, host, plugin;
