## Authentication Plugin Handling

MySQL 8.0 uses caching_sha2_password.

MariaDB caching_sha2_password plugin is not a stable plugin.Its a gamma plugin in 11.8.3-1-MariaDB-enterprise. If we have to install then mariadb server has to start with "--plugin_maturity=Gamma" else by default it will be Stable
MariaDB [(none)]> SELECT PLUGIN_NAME, PLUGIN_LIBRARY, PLUGIN_MATURITY, PLUGIN_STATUS FROM INFORMATION_SCHEMA.ALL_PLUGINS WHERE plugin_type='AUTHENTICATION';
+-----------------------+--------------------+-----------------+---------------+
| PLUGIN_NAME           | PLUGIN_LIBRARY     | PLUGIN_MATURITY | PLUGIN_STATUS |
+-----------------------+--------------------+-----------------+---------------+
| mysql_native_password | NULL               | Stable          | ACTIVE        |
| mysql_old_password    | NULL               | Stable          | ACTIVE        |
| unix_socket           | NULL               | Stable          | ACTIVE        |
| ed25519               | auth_ed25519.so    | Stable          | ACTIVE        |
| caching_sha2_password | auth_mysql_sha2.so | Gamma           | NOT INSTALLED |
| pam                   | auth_pam.so        | Stable          | NOT INSTALLED |
| pam                   | auth_pam_v1.so     | Stable          | NOT INSTALLED |
| parsec                | auth_parsec.so     | Gamma           | NOT INSTALLED |
+-----------------------+--------------------+-----------------+---------------+

All users are recreated using mysql_native_password. After starting the MariaDB server with "--plugin_maturity=Gamma" followed by installing the caching_sha2_password plugin, we were able to create the user with new password. Application testing is pending