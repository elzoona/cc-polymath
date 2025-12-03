---
name: salesforce-soql-advanced
description: Advanced SOQL queries for GUS - work items, aggregation, date filters, and tooling API. For complex queries beyond basic lookups.
keywords: salesforce, gus, soql, advanced, work items, aggregation, date filters, tooling api, epic queries, sprint queries, complex queries
---

# Salesforce SOQL Advanced Queries

**Scope**: Advanced SOQL patterns for work items, aggregation, date filtering, and tooling API
**Lines**: ~292
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)

---

## When to Use This Skill

Activate this skill when:
- **Querying work items by various criteria** - Assignee, sprint, epic, status
- **Aggregating data** - Counts, sums, grouped results
- **Filtering by dates** - Date ranges, relative dates (THIS_WEEK, LAST_N_DAYS)
- **Querying metadata** - Apex classes, triggers using Tooling API
- **Complex multi-condition queries** - Multiple filters and relationships

**Prerequisites**: You should understand basic SOQL from `sf-soql-basics.md` first.

**⚠️ CRITICAL**: Always run `sf sobject describe` before querying - see `sf-soql-basics.md` for field verification workflow.

---

## Advanced Patterns

### Pattern 1: Querying Work Items

**Use case**: Find work items by various criteria (assignee, sprint, epic, status)

```bash
# Get default org and current user's work items dynamically
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')

sf data query \
  --query "SELECT Name, Subject__c, Status__c, Priority__c, Type__c, Sprint__c
    FROM ADM_Work__c
    WHERE Assignee__r.Email = '${USER_EMAIL}'
    AND Status__c != 'Closed'
    ORDER BY Priority__c, CreatedDate DESC" \
  --target-org "$DEFAULT_ORG"

# Query by work item name (WI number)
sf data query \
  --query "SELECT Id, Name, Subject__c, Status__c FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --target-org "$DEFAULT_ORG"

# Query by sprint
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Assignee__r.Name, Story_Points__c
    FROM ADM_Work__c
    WHERE Sprint__r.Name = 'Sprint 42'
    ORDER BY Status__c, Priority__c" \
  --target-org "$DEFAULT_ORG"

# Query by epic
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Sprint__r.Name
    FROM ADM_Work__c
    WHERE Epic__r.Name LIKE '%Q1 Features%'
    AND Status__c NOT IN ('Fixed', 'Closed')" \
  --target-org "$DEFAULT_ORG"

# Query by type and priority
sf data query \
  --query "SELECT Name, Subject__c, Assignee__r.Name, Sprint__r.Name
    FROM ADM_Work__c
    WHERE Type__c = 'Bug'
    AND Priority__c = 'P1'
    AND Status__c NOT IN ('Fixed', 'Not a Bug')" \
  --target-org "$DEFAULT_ORG"

# Query user's epics
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')

sf data query \
  --query "SELECT Id, Name, Description__c, Health__c, Priority__c, Owner.Name, LastModifiedDate
    FROM ADM_Epic__c
    WHERE Owner.Email = '${USER_EMAIL}'
    ORDER BY LastModifiedDate DESC" \
  --target-org "$DEFAULT_ORG"

# Query work items with epics (filter non-null with jq)
# IMPORTANT: Avoid != in queries due to shell escaping - filter with jq instead
sf data query \
  --query "SELECT Id, Name, Subject__c, Epic__c, Epic__r.Name, Epic__r.Id
    FROM ADM_Work__c
    WHERE Assignee__r.Email = '${USER_EMAIL}'
    ORDER BY LastModifiedDate DESC
    LIMIT 50" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | select(.Epic__r) | "\(.Epic__r.Name) - \(.Name): \(.Subject__c)"' | sort -u
```

**Note on filtering null values**: Due to shell escaping issues with `!=` (the `!` triggers history expansion), it's best to query all records and filter with jq using `select(.Epic__r)` to check for non-null relationships.

### Pattern 2: Complex Queries with Aggregation

**Use case**: Get counts, sums, and grouped data

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

# Count work items by status
sf data query \
  --query "SELECT Status__c, COUNT(Id) total FROM ADM_Work__c GROUP BY Status__c" \
  --target-org "$DEFAULT_ORG"

# Sum story points by sprint (filter null sprints with jq)
sf data query \
  --query "SELECT Sprint__r.Name, SUM(Story_Points__c) total_points
    FROM ADM_Work__c
    GROUP BY Sprint__r.Name" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | select(.Sprint__r) | "\(.Sprint__r.Name): \(.total_points) points"'

# Count by assignee
sf data query \
  --query "SELECT Assignee__r.Name, COUNT(Id) work_count
    FROM ADM_Work__c
    WHERE Status__c IN ('New', 'In Progress')
    GROUP BY Assignee__r.Name
    ORDER BY COUNT(Id) DESC" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 3: Querying with Date Filters

**Use case**: Find records by date ranges (relative and absolute)

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

# Work items created this week
sf data query \
  --query "SELECT Name, Subject__c, CreatedDate FROM ADM_Work__c WHERE CreatedDate = THIS_WEEK" \
  --target-org "$DEFAULT_ORG"

# Work items updated in last 7 days
sf data query \
  --query "SELECT Name, Subject__c, LastModifiedDate FROM ADM_Work__c WHERE LastModifiedDate = LAST_N_DAYS:7" \
  --target-org "$DEFAULT_ORG"

# Work items created in date range (absolute dates)
sf data query \
  --query "SELECT Name, Subject__c, CreatedDate
    FROM ADM_Work__c
    WHERE CreatedDate >= 2024-01-01T00:00:00Z
    AND CreatedDate <= 2024-01-31T23:59:59Z" \
  --target-org "$DEFAULT_ORG"

# Sprints active in date range
sf data query \
  --query "SELECT Name, Start_Date__c, End_Date__c
    FROM ADM_Sprint__c
    WHERE Start_Date__c <= 2024-12-03
    AND End_Date__c >= 2024-12-03" \
  --target-org "$DEFAULT_ORG"
```

**Date Literals Reference**:
```
TODAY               Current day
THIS_WEEK           Current week
THIS_MONTH          Current month
LAST_N_DAYS:n      Last n days
NEXT_N_DAYS:n      Next n days
LAST_WEEK           Previous week
THIS_QUARTER        Current quarter
```

### Pattern 4: Using Tooling API

**Use case**: Query metadata objects (Apex classes, triggers, custom fields)

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

# Query Apex classes
sf data query \
  --query "SELECT Name, ApiVersion, LengthWithoutComments FROM ApexClass" \
  --use-tooling-api \
  --target-org "$DEFAULT_ORG"

# Query Apex triggers
sf data query \
  --query "SELECT Name, TableEnumOrId, Status FROM ApexTrigger" \
  --use-tooling-api \
  --target-org "$DEFAULT_ORG"

# Query custom fields on a specific object
sf data query \
  --query "SELECT DeveloperName, DataType, TableEnumOrId FROM CustomField WHERE TableEnumOrId = 'ADM_Work__c'" \
  --use-tooling-api \
  --target-org "$DEFAULT_ORG"
```

---

## Best Practices for Advanced Queries

**Advanced Query Guidelines**:
```
✅ DO: Use aggregation (COUNT, SUM) instead of querying all records and counting in code
✅ DO: Use date literals (THIS_WEEK, LAST_N_DAYS:7) for relative date queries
✅ DO: Filter null values with jq when ! causes shell escaping issues
✅ DO: Use IN and NOT IN for multiple value matching
✅ DO: Use ORDER BY to sort results server-side
✅ DO: Add LIMIT to aggregation queries to avoid timeouts
✅ DO: Use relationship fields (Epic__r.Name) in WHERE clauses
```

**Common Mistakes**:
```
❌ DON'T: Use != in double-quoted strings (shell escapes the !)
❌ DON'T: Query without LIMIT on large objects (can timeout)
❌ DON'T: Forget to filter null relationships - use jq select()
❌ DON'T: Hardcode date values - use date literals when possible
❌ DON'T: Use LIKE with % on both sides (performance issue)
```

---

## Advanced GUS Object Fields (Verified)

**ADM_Epic__c (Epics)**:
```
Id, Name, Description__c, Health__c (NOT Status__c!)
Priority__c, OwnerId (→User)
CreatedDate, LastModifiedDate
```

**ADM_Sprint__c (Sprints)**:
```
Id, Name, Start_Date__c, End_Date__c
Scrum_Team__c (→ADM_Scrum_Team__c)
CreatedDate, LastModifiedDate
```

**ADM_Build__c (Builds)**:
```
Id, Name, CreatedDate, LastModifiedDate
```

**ADM_Product_Tag__c (Product Tags)**:
```
Id, Name, CreatedDate, LastModifiedDate
```

**IMPORTANT**: These are verified but may vary by org. Always run `sf sobject describe` to verify fields in YOUR org before querying.

---

## Common SOQL Operators for Advanced Queries

```
=           Equal to
!=          Not equal to (avoid in double quotes - shell escapes !)
<           Less than
>           Greater than
<=          Less than or equal
>=          Greater than or equal
LIKE        Pattern match (use % for wildcard)
IN          Match any value in list
NOT IN      Don't match any value in list
```

---

## Related Skills

- `sf-soql-basics.md` - Start here for field discovery and basic queries
- `sf-soql-troubleshooting.md` - Error handling and anti-patterns
- `sf-work-items.md` - Creating and managing work items
- `sf-bulk-operations.md` - Bulk data operations and exports
- `sf-org-auth.md` - Authentication and user info

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)
