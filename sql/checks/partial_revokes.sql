/*
MySQL 8 introduced "Partial Revokes," allowing you to grant global privileges but revoke them for specific schemas (e.g., GRANT UPDATE ON *.* ... REVOKE UPDATE ON secret_db.*). MariaDB does not support this feature, and these privileges will not migrate correctly.
*/

SELECT * FROM mysql.user WHERE User_attributes LIKE '%"partial_revokes":true%';
