/*
MySQL 8 allows assigning threads to specific "Resource Groups" (CPU affinity). MariaDB does not have an equivalent feature. While this doesn't block data migration, it can cause application performance issues post-migration if the app relies on them.
*/
SELECT * FROM INFORMATION_SCHEMA.RESOURCE_GROUPS;
