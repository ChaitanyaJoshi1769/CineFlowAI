# CineFlow AI Migration Guide

## From 0.1.0 to 1.0.0

### Breaking Changes

- API v1 endpoint moved from `/api/v1` to `/api/v2`
- Schema changes in character relationships
- GraphQL schema updates

### Migration Steps

1. Backup all data
2. Run migration scripts
3. Verify data integrity
4. Update API clients
5. Run integration tests
6. Deploy gradually (blue-green)

### Rollback Plan

If issues occur:

```bash
# Revert to previous version
kubectl rollout undo deployment/api-gateway
kubectl rollout undo deployment/story-engine
# Restore database from backup
pg_restore -d cineflow backup.sql
```

## Data Migration

### Character Memory Migration

Old format → New format (enhanced memory model)

```sql
-- Create temporary table with new schema
CREATE TABLE characters_v2 AS
SELECT 
  id,
  name,
  CASE WHEN memory_type = 'short_term' 
       THEN 'episodic'
       ELSE memory_type
  END as memory_type,
  memories
FROM characters;

-- Validate data
SELECT COUNT(*) FROM characters_v2 WHERE id IS NULL;

-- Swap tables
ALTER TABLE characters RENAME TO characters_v1;
ALTER TABLE characters_v2 RENAME TO characters;
```

## Testing Migration

- Test with production-scale data (anonymized)
- Verify all relationships
- Check API compatibility
- Performance benchmarking
- Canary deployment
