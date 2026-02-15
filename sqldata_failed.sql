-- SQLines Data 3.7.11 x86_64 Linux - Database Migration and Validation Tool.
-- Copyright (c) 2026 SQLines. All Rights Reserved.

-- Failed DDL SQL statements executed for the target database

-- Current timestamp: 2026:02:15 18:01:08.268

CREATE INDEX idx_title_description ON sakila.film_text (`title` ASC, `description` ASC);

-- Failed (3 ms)
-- Specified key was too long; max key length is 3072 bytes