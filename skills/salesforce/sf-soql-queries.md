---
name: salesforce-soql-queries
description: Query Salesforce data using SOQL and sf CLI
---

# Salesforce SOQL Queries

**Scope**: SOQL query syntax, data retrieval, and result formatting
**Lines**: ~200
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Querying Salesforce data using SOQL
- Retrieving work items, users, or other records
- Finding record IDs for operations
- Exporting data for analysis
- Building reports or dashboards
- Joining related objects

---

## Core Concepts

### Concept 1: Basic SOQL Syntax

**Query Structure**:
```sql
SELECT fields FROM object WHERE conditions ORDER BY field LIMIT n
```

**Field Selection**:
- Standard fields: `Id, Name, CreatedDate`
- Custom fields: Use `__c` suffix (e.g., `Status__c, Subject__c`)
- Related fields: Use `__r` for relationships (e.g., `Assignee__r.Email`)

```bash
# Basic query
sf data query \
  --query "SELECT Id, Name FROM ADM_Work__c LIMIT 10" \
  --target-org gus

# Query with conditions
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c WHERE Status__c = 'New'" \
  --target-org gus

# Query with related fields
sf data query \
  --query "SELECT Id, Subject__c, Assignee__r.Name, Assignee__r.Email FROM ADM_Work__c WHERE Status__c = 'In Progress'" \
  --target-org gus

# Query with ordering and limit
sf data query \
  --query "SELECT Id, Name, CreatedDate FROM ADM_Work__c ORDER BY CreatedDate DESC LIMIT 20" \
  --target-org gus
```

### Concept 2: Output Formats

**Available Formats**:
- `human` - Table format (default)
- `json` - JSON output for scripting
- `csv` - CSV format for spreadsheets

```bash
# Human-readable table (default)
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c LIMIT 5" \
  --target-org gus

# JSON output for scripting
sf data query \
  --query "SELECT Id, Name FROM ADM_Work__c LIMIT 5" \
  --target-org gus \
  --result-format json

# CSV output for Excel
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c LIMIT 100" \
  --target-org gus \
  --result-format csv > work_items.csv

# Query from file
echo "SELECT Id, Name FROM ADM_Work__c LIMIT 10" > query.soql
sf data query \
  --file query.soql \
  --target-org gus
```

---

## Patterns

### Pattern 1: Finding Record IDs

**Use case**: Locate record IDs for references (Users, Epics, Sprints, Product Tags)

```bash
# Find user ID by name
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Name LIKE '%John Doe%'" \
  --target-org gus

# Find user ID by email
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Email = 'user@example.com'" \
  --target-org gus

# Find Epic by name
sf data query \
  --query "SELECT Id, Name FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --target-org gus

# Find Sprint by name
sf data query \
  --query "SELECT Id, Name, Start_Date__c, End_Date__c FROM ADM_Sprint__c WHERE Name = 'Sprint 42'" \
  --target-org gus

# Find Product Tag
sf data query \
  --query "SELECT Id, Name FROM ADM_Product_Tag__c WHERE Name LIKE '%Platform%'" \
  --target-org gus

# Get ID with jq for scripting
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Email = 'user@example.com'" \
  --result-format json \
  --target-org gus | jq -r '.result.records[0].Id')

echo "User ID: $USER_ID"
```

### Pattern 2: Querying Work Items

**Use case**: Find work items by various criteria

```bash
# Get current user's work items dynamically
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .username')

sf data query \
  --query "SELECT Name, Subject__c, Status__c, Priority__c, Type__c, Sprint__c
    FROM ADM_Work__c
    WHERE Assignee__r.Email = '${USER_EMAIL}'
    AND Status__c != 'Closed'
    ORDER BY Priority__c, CreatedDate DESC" \
  --target-org gus

# Query by work item name (WI number)
sf data query \
  --query "SELECT Id, Name, Subject__c, Status__c FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --target-org gus

# Query by sprint
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Assignee__r.Name, Story_Points__c
    FROM ADM_Work__c
    WHERE Sprint__r.Name = 'Sprint 42'
    ORDER BY Status__c, Priority__c" \
  --target-org gus

# Query by epic
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Sprint__r.Name
    FROM ADM_Work__c
    WHERE Epic__r.Name LIKE '%Q1 Features%'
    AND Status__c NOT IN ('Fixed', 'Closed')" \
  --target-org gus

# Query by type and priority
sf data query \
  --query "SELECT Name, Subject__c, Assignee__r.Name, Sprint__r.Name
    FROM ADM_Work__c
    WHERE Type__c = 'Bug'
    AND Priority__c = 'P1'
    AND Status__c NOT IN ('Fixed', 'Not a Bug')" \
  --target-org gus

# Query user's epics
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .username')

sf data query \
  --query "SELECT Id, Name, Description__c, Health__c, Priority__c, Owner.Name, LastModifiedDate
    FROM ADM_Epic__c
    WHERE Owner.Email = '${USER_EMAIL}'
    ORDER BY LastModifiedDate DESC" \
  --target-org gus
```

### Pattern 3: Complex Queries with Aggregation

**Use case**: Get counts, sums, and grouped data

```bash
# Count work items by status
sf data query \
  --query "SELECT Status__c, COUNT(Id) total FROM ADM_Work__c GROUP BY Status__c" \
  --target-org gus

# Sum story points by sprint
sf data query \
  --query "SELECT Sprint__r.Name, SUM(Story_Points__c) total_points
    FROM ADM_Work__c
    WHERE Sprint__r.Name != null
    GROUP BY Sprint__r.Name" \
  --target-org gus

# Count by assignee
sf data query \
  --query "SELECT Assignee__r.Name, COUNT(Id) work_count
    FROM ADM_Work__c
    WHERE Status__c IN ('New', 'In Progress')
    GROUP BY Assignee__r.Name
    ORDER BY COUNT(Id) DESC" \
  --target-org gus
```

### Pattern 4: Querying with Date Filters

**Use case**: Find records by date ranges

```bash
# Work items created this week
sf data query \
  --query "SELECT Name, Subject__c, CreatedDate FROM ADM_Work__c WHERE CreatedDate = THIS_WEEK" \
  --target-org gus

# Work items updated in last 7 days
sf data query \
  --query "SELECT Name, Subject__c, LastModifiedDate FROM ADM_Work__c WHERE LastModifiedDate = LAST_N_DAYS:7" \
  --target-org gus

# Work items created in date range
sf data query \
  --query "SELECT Name, Subject__c, CreatedDate
    FROM ADM_Work__c
    WHERE CreatedDate >= 2024-01-01T00:00:00Z
    AND CreatedDate <= 2024-01-31T23:59:59Z" \
  --target-org gus

# Sprints active in date range
sf data query \
  --query "SELECT Name, Start_Date__c, End_Date__c
    FROM ADM_Sprint__c
    WHERE Start_Date__c <= 2024-12-03
    AND End_Date__c >= 2024-12-03" \
  --target-org gus
```

### Pattern 5: Using Tooling API

**Use case**: Query metadata objects

```bash
# Query Apex classes
sf data query \
  --query "SELECT Name, ApiVersion, LengthWithoutComments FROM ApexClass" \
  --use-tooling-api \
  --target-org gus

# Query Apex triggers
sf data query \
  --query "SELECT Name, TableEnumOrId, Status FROM ApexTrigger" \
  --use-tooling-api \
  --target-org gus

# Query custom fields
sf data query \
  --query "SELECT DeveloperName, DataType, TableEnumOrId FROM CustomField WHERE TableEnumOrId = 'ADM_Work__c'" \
  --use-tooling-api \
  --target-org gus
```

---

## Quick Reference

### Common SOQL Operators

```
=           Equal to
!=          Not equal to
<           Less than
>           Greater than
<=          Less than or equal
>=          Greater than or equal
LIKE        Pattern match (use % for wildcard)
IN          Match any value in list
NOT IN      Don't match any value in list
```

### Date Literals

```
TODAY               Current day
THIS_WEEK           Current week
THIS_MONTH          Current month
LAST_N_DAYS:n      Last n days
NEXT_N_DAYS:n      Next n days
LAST_WEEK           Previous week
THIS_QUARTER        Current quarter
```

### Common Fields

**Work Items (ADM_Work__c)**:
```
Id, Name, Subject__c, Status__c, Priority__c, Type__c
Story_Points__c, Assignee__c, Sprint__c, Epic__c
CreatedDate, LastModifiedDate, Description__c
```

**Related Field Notation**:
```
Assignee__r.Name            # User name
Assignee__r.Email           # User email
Sprint__r.Name              # Sprint name
Epic__r.Name                # Epic name
Found_in_Build__r.Name      # Build name
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Use --result-format json for scripting
✅ DO: Use LIMIT to avoid timeouts on large datasets
✅ DO: Query for IDs before creating related records
✅ DO: Use relationship queries (__r) instead of multiple queries
✅ DO: Validate query results before using extracted values
✅ DO: Use WHERE clauses to filter data server-side
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Query without LIMIT (can timeout)
❌ DON'T: Use SELECT * (not supported in SOQL)
❌ DON'T: Assume queries will always return results
❌ DON'T: Forget __c suffix on custom fields
❌ DON'T: Skip validation of jq output (check for null)
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Query without checking results
WORK_ITEM_ID=$(sf data query --query "..." --json | jq -r '.result.records[0].Id')
# If no results, this returns "null" and breaks downstream operations

# ✅ CORRECT: Validate query results
QUERY_RESULT=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org gus)

RECORD_COUNT=$(echo "$QUERY_RESULT" | jq -r '.result.totalSize')

if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "Error: Work item not found"
  exit 1
fi

WORK_ITEM_ID=$(echo "$QUERY_RESULT" | jq -r '.result.records[0].Id')

if [ -z "$WORK_ITEM_ID" ] || [ "$WORK_ITEM_ID" = "null" ]; then
  echo "Error: Failed to extract ID"
  exit 1
fi
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Be careful querying sensitive fields (passwords, tokens, SSN)
- ⚠️ Use appropriate WHERE clauses to avoid exposing all data
- ⚠️ Don't log or export sensitive data to insecure locations
- ⚠️ Validate user input in WHERE clauses to prevent injection

---

## Related Skills

- `sf-org-auth.md` - Authentication and user info
- `sf-record-operations.md` - Create/update records
- `sf-work-items.md` - Work with GUS objects
- `sf-bulk-operations.md` - Export large datasets

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
