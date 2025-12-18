# Migration Checklist

## 1. Assessment
- [ ] Capture MySQL version
- [ ] Identify storage engines
- [ ] Check authentication plugins
- [ ] Identify incompatible SQL features

## 2. Pre-Migration
- [ ] Backup source database
- [ ] Freeze schema changes
- [ ] Extract users & privileges
- [ ] Validate disk space on target

## 3. Schema Migration
- [ ] Export schema
- [ ] Convert incompatible objects
- [ ] Apply schema on MariaDB
- [ ] Verify objects count

## 4. Data Migration
- [ ] Export data
- [ ] Import data
- [ ] Validate row counts
- [ ] Validate sample data

## 5. Users & Security
- [ ] Recreate users
- [ ] Normalize auth plugins
- [ ] Apply privileges
- [ ] Test application connections

## 6. Validation
- [ ] Row counts
- [ ] Checksums
- [ ] Application sanity tests

## 7. Cutover
- [ ] Stop MySQL writes
- [ ] Final sync
- [ ] Switch application
- [ ] Monitor

## 8. Rollback
- [ ] MySQL kept intact
- [ ] DNS / config revert plan ready
