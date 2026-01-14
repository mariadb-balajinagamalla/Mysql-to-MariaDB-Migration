ALTER USER 'analytics'@'10.%' IDENTIFIED WITH mysql_native_password BY '<SET_PASSWORD_HERE>';
ALTER USER 'app_ro'@'%' IDENTIFIED WITH mysql_native_password BY '<SET_PASSWORD_HERE>';
ALTER USER 'app_rw'@'%' IDENTIFIED WITH mysql_native_password BY '<SET_PASSWORD_HERE>';
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '<SET_PASSWORD_HERE>';
