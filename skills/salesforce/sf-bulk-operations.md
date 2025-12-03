---
name: salesforce-bulk-operations
description: Perform bulk data operations on Salesforce objects. Use for mass updates to GUS work items, bulk exports, and large data operations.
keywords: salesforce, gus, bulk, mass update, export, import, CSV, bulk API, large datasets, multiple records
---

# Salesforce Bulk Operations

**Scope**: Bulk data updates, exports, and large-scale operations
**Lines**: ~150
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Updating multiple records at once
- Exporting large datasets
- Bulk status changes
- Mass data migrations
- Batch processing operations
- Avoiding API limit issues

---

## Core Concepts

### Concept 1: Bulk API vs Single Operations

**Use Bulk API when**:
- Updating 10+ records
- Exporting large datasets (>2000 records)
- Performing repetitive operations
- Avoiding API limits

**Use Single Operations when**:
- Updating 1-5 records
- Need immediate feedback
- Complex validation required

### Concept 2: CSV-Based Operations

Bulk operations use CSV files:
- Header row with field names
- One record per line
- Include `Id` for updates
- All fields as text

---

## Patterns

### Pattern 1: Bulk Status Updates

**Use case**: Update multiple work items to a new status

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Step 1: Query work items to update
sf data query \
  --query "SELECT Id, Name FROM ADM_Work__c
    WHERE Sprint__c = 'a1Fxx000002EFGH'
    AND Status__c = 'Ready for Development'" \
  --result-format csv \
  --target-org "$DEFAULT_ORG" > work_items.csv

# Step 2: Create CSV for bulk update
# Manually edit or use script to create:
# work_items_update.csv:
# Id,Status__c
# a07xx00000ABCD1,In Progress
# a07xx00000ABCD2,In Progress
# a07xx00000ABCD3,In Progress

# Step 3: Bulk update using CSV
sf data update bulk \
  --sobject ADM_Work__c \
  --file work_items_update.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

echo "Bulk update complete"
```

### Pattern 2: Bulk Data Export

**Use case**: Export large datasets for analysis or backup

```bash
# Export all work items for a sprint
sf data export bulk \
  --sobject ADM_Work__c \
  --query "SELECT Id, Name, Subject__c, Status__c, Priority__c,
    Assignee__r.Name, Assignee__r.Email, Story_Points__c,
    Sprint__r.Name, Epic__r.Name, CreatedDate, LastModifiedDate
    FROM ADM_Work__c
    WHERE Sprint__r.Name = 'Sprint 42'" \
  --output-file sprint_42_items.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

echo "Exported to sprint_42_items.csv"

# Export all open bugs
sf data export bulk \
  --sobject ADM_Work__c \
  --query "SELECT Id, Name, Subject__c, Status__c, Priority__c,
    Assignee__r.Name, Found_in_Build__r.Name, CreatedDate
    FROM ADM_Work__c
    WHERE Type__c = 'Bug'
    AND Status__c NOT IN ('Fixed', 'Not a Bug', 'Closed')" \
  --output-file open_bugs.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

# Export user list
sf data export bulk \
  --sobject User \
  --query "SELECT Id, Name, Email, Profile.Name, IsActive
    FROM User
    WHERE IsActive = true" \
  --output-file active_users.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"
```

### Pattern 3: Script-Driven Bulk Updates

**Use case**: Generate CSV updates programmatically

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Query and transform data
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c
    WHERE Sprint__r.Name = 'Sprint 42'
    AND Status__c = 'Ready for Development'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" > work_items.json

# Generate CSV with jq
echo "Id,Status__c,Assignee__c" > bulk_update.csv
jq -r '.result.records[] | [.Id, "In Progress", "005xx000001X8Uz"] | @csv' work_items.json >> bulk_update.csv

# Bulk update
sf data update bulk \
  --sobject ADM_Work__c \
  --file bulk_update.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

echo "Updated $(wc -l < bulk_update.csv) records"
```

### Pattern 4: Bulk Assignment to Sprint

**Use case**: Assign multiple backlog items to a sprint

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Get sprint ID
SPRINT_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Sprint__c WHERE Name = 'Sprint 43'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# Query backlog items
sf data query \
  --query "SELECT Id, Name, Subject__c, Story_Points__c
    FROM ADM_Work__c
    WHERE Status__c = 'Ready for Development'
    AND Sprint__c = null
    ORDER BY Priority__c
    LIMIT 20" \
  --result-format csv \
  --target-org "$DEFAULT_ORG" > backlog.csv

# Create assignment CSV
echo "Id,Sprint__c" > sprint_assignment.csv
tail -n +2 backlog.csv | cut -d',' -f1 | while read id; do
  echo "${id},${SPRINT_ID}" >> sprint_assignment.csv
done

# Bulk assign
sf data update bulk \
  --sobject ADM_Work__c \
  --file sprint_assignment.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

echo "Assigned $(tail -n +2 sprint_assignment.csv | wc -l) items to Sprint 43"
```

### Pattern 5: Bulk Creation

**Use case**: Create multiple records from CSV

```bash
# Create CSV file
# new_work_items.csv:
# Subject__c,Status__c,Type__c,Priority__c,Story_Points__c
# "Implement feature A",New,User Story,P2,3
# "Implement feature B",New,User Story,P2,5
# "Fix bug in login",New,Bug,P1,2

# Bulk create
sf data create bulk \
  --sobject ADM_Work__c \
  --file new_work_items.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"

echo "Created records from CSV"
```

---

## Quick Reference

### Common Commands

```bash
# Bulk update
sf data update bulk --sobject <Object> --file <csv> --wait <seconds> --target-org <alias>

# Bulk export
sf data export bulk --sobject <Object> --query "<SOQL>" --output-file <csv> --wait <seconds> --target-org <alias>

# Bulk create
sf data create bulk --sobject <Object> --file <csv> --wait <seconds> --target-org <alias>

# Bulk delete
sf data delete bulk --sobject <Object> --file <csv> --wait <seconds> --target-org <alias>
```

### CSV Format

**For Updates** (requires Id):
```csv
Id,Field1,Field2
a07xx00000ABCD1,Value1,Value2
a07xx00000ABCD2,Value3,Value4
```

**For Creates** (no Id):
```csv
Field1,Field2,Field3
Value1,Value2,Value3
Value4,Value5,Value6
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Use bulk operations for 10+ records
✅ DO: Test with small dataset first
✅ DO: Include --wait flag to monitor completion
✅ DO: Backup data before bulk deletes
✅ DO: Validate CSV format before upload
✅ DO: Use appropriate LIMIT in export queries
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Use single updates in loops
❌ DON'T: Skip validation of CSV data
❌ DON'T: Bulk delete without backup
❌ DON'T: Export without LIMIT (can timeout)
❌ DON'T: Update production without testing
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Loop with single updates
for id in $(cat work_item_ids.txt); do
  sf data update record --sobject ADM_Work__c --record-id "$id" --values "Status__c='Closed'"
done

# ✅ CORRECT: Use bulk update
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

echo "Id,Status__c" > bulk_update.csv
cat work_item_ids.txt | while read id; do
  echo "${id},Closed" >> bulk_update.csv
done

sf data update bulk \
  --sobject ADM_Work__c \
  --file bulk_update.csv \
  --wait 10 \
  --target-org "$DEFAULT_ORG"
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Always backup before bulk deletes
- ⚠️ Test bulk operations in sandbox first
- ⚠️ Validate CSV data before upload
- ⚠️ Use appropriate WHERE clauses in exports
- ⚠️ Be cautious with bulk updates in production

---

## Related Skills

- `sf-soql-queries.md` - Query data for bulk operations
- `sf-record-operations.md` - Single record operations
- `sf-work-items.md` - Bulk sprint/epic management

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
