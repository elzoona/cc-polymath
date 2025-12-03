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

### Concept 1: Field Discovery Before Querying

**CRITICAL**: Always use `sf sobject describe` when uncertain about field names. This prevents INVALID_FIELD errors.

```bash
# Discover all fields on an object
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG"

# Search for specific fields (e.g., team-related)
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team

# Find relationship fields
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.relationshipName != null) | {name: .name, relationshipName: .relationshipName, referenceTo: .referenceTo}'
```

**Why this matters**: Guessing field names leads to errors like:
- `No such column 'Team__c' on entity 'User'` (field doesn't exist)
- Wrong field type or reference target
- Missing junction objects for many-to-many relationships

See **Pattern 1: Discovering Object Fields** below for detailed examples.

### Concept 2: Basic SOQL Syntax

**Query Structure**:
```sql
SELECT fields FROM object WHERE conditions ORDER BY field LIMIT n
```

**Field Selection**:
- Standard fields: `Id, Name, CreatedDate`
- Custom fields: Use `__c` suffix (e.g., `Status__c, Subject__c`)
- Related fields: Use `__r` for relationships (e.g., `Assignee__r.Email`)

```bash
# Get default org (add this at the start of scripts)
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Basic query
sf data query \
  --query "SELECT Id, Name FROM ADM_Work__c LIMIT 10" \
  --target-org "$DEFAULT_ORG"

# Query with conditions
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c WHERE Status__c = 'New'" \
  --target-org "$DEFAULT_ORG"

# Query with related fields
sf data query \
  --query "SELECT Id, Subject__c, Assignee__r.Name, Assignee__r.Email FROM ADM_Work__c WHERE Status__c = 'In Progress'" \
  --target-org "$DEFAULT_ORG"

# Query with ordering and limit
sf data query \
  --query "SELECT Id, Name, CreatedDate FROM ADM_Work__c ORDER BY CreatedDate DESC LIMIT 20" \
  --target-org "$DEFAULT_ORG"
```

### Concept 2: Verified Field Names

**Common GUS Objects** (verified via `sf sobject describe`):

**ADM_Work__c (Work Items)**:
```
Id, Name, Subject__c, Status__c, Priority__c, Type__c
Story_Points__c, Assignee__c (→User), Sprint__c (→ADM_Sprint__c)
Epic__c (→ADM_Epic__c), Found_in_Build__c (→ADM_Build__c)
Product_Tag__c (→ADM_Product_Tag__c), Description__c
CreatedDate, LastModifiedDate
```

**ADM_Epic__c (Epics)**:
```
Id, Name, Description__c, Health__c (not Status__c!)
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

**ADM_Scrum_Team_Member__c (Team Membership - Junction Object)**:
```
Id, Name, Member_Name__c (→User), Scrum_Team__c (→ADM_Scrum_Team__c)
CreatedDate, LastModifiedDate
```

**User (Standard Object)**:
```
Id, Name, Email, Username, IsActive, ProfileId
Note: No Team__c field - use ADM_Scrum_Team_Member__c junction object
```

**FeedItem (Chatter Posts)**:
```
Id, ParentId, Body, Type, LinkUrl, Visibility
CreatedDate, CreatedById
```

**FeedComment (Chatter Comments)**:
```
Id, FeedItemId, CommentBody, CreatedDate, CreatedById
```

**Related Field Notation**:
```
Assignee__r.Name            # User name
Assignee__r.Email           # User email
Sprint__r.Name              # Sprint name
Epic__r.Name                # Epic name
Scrum_Team__r.Name          # Team name
Found_in_Build__r.Name      # Build name
```

### Concept 3: Output Formats

**Available Formats**:
- `human` - Table format (default)
- `json` - JSON output for scripting
- `csv` - CSV format for spreadsheets

```bash
# Human-readable table (default)
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c LIMIT 5" \
  --target-org "$DEFAULT_ORG"

# JSON output for scripting
sf data query \
  --query "SELECT Id, Name FROM ADM_Work__c LIMIT 5" \
  --target-org "$DEFAULT_ORG" \
  --result-format json

# CSV output for Excel
sf data query \
  --query "SELECT Id, Name, Status__c FROM ADM_Work__c LIMIT 100" \
  --target-org "$DEFAULT_ORG" \
  --result-format csv > work_items.csv

# Query from file
echo "SELECT Id, Name FROM ADM_Work__c LIMIT 10" > query.soql
sf data query \
  --file query.soql \
  --target-org "$DEFAULT_ORG"
```

---

## Patterns

### Pattern 1: Discovering Object Fields

**Use case**: Find available fields on an object before querying (avoids INVALID_FIELD errors)

**IMPORTANT**: Always use `sf sobject describe` when unsure about field names. This prevents errors like `No such column 'Team__c' on entity 'User'`.

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# List all fields on an object
sf sobject describe --sobject User --target-org "$DEFAULT_ORG"

# Search for specific field names (e.g., team-related)
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team

# Find fields that reference another object (e.g., User)
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User") | {name: .name, label: .label, relationshipName: .relationshipName}'

# Get all custom fields (fields ending in __c)
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.name | endswith("__c")) | {name: .name, label: .label, type: .type}'

# Find relationship fields (__r notation)
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.relationshipName != null) | {name: .name, relationshipName: .relationshipName, referenceTo: .referenceTo}'
```

**Example: Finding team membership fields**
```bash
# Discovered that User doesn't have Team__c, but ADM_Scrum_Team_Member__c has Member_Name__c
USER_ID="005EE000001JW5FYAW"

# Query teams through the junction object
sf data query \
  --query "SELECT Id, Name, Scrum_Team__r.Name
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | .Scrum_Team__r.Name'
```

**Benefits**:
- Avoids INVALID_FIELD errors from guessing field names
- Discovers correct relationship field names (__r notation)
- Finds junction objects for many-to-many relationships
- Identifies custom vs standard fields

### Pattern 2: Finding Record IDs

**Use case**: Locate record IDs for references (Users, Epics, Sprints, Product Tags)

```bash
# Find user ID by name
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Name LIKE '%John Doe%'" \
  --target-org "$DEFAULT_ORG"

# Find user ID by email (use dynamic user email)
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Email = '${USER_EMAIL}'" \
  --target-org "$DEFAULT_ORG"

# Find Epic by name
sf data query \
  --query "SELECT Id, Name FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --target-org "$DEFAULT_ORG"

# Find Sprint by name
sf data query \
  --query "SELECT Id, Name, Start_Date__c, End_Date__c FROM ADM_Sprint__c WHERE Name = 'Sprint 42'" \
  --target-org "$DEFAULT_ORG"

# Find Product Tag
sf data query \
  --query "SELECT Id, Name FROM ADM_Product_Tag__c WHERE Name LIKE '%Platform%'" \
  --target-org "$DEFAULT_ORG"

# Get ID with jq for scripting (using dynamic user email)
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Email = '${USER_EMAIL}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

echo "User ID: $USER_ID"
```

### Pattern 3: Querying Work Items

**Use case**: Find work items by various criteria

```bash
# Get default org and current user's work items dynamically
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

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
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

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

### Pattern 4: Complex Queries with Aggregation

**Use case**: Get counts, sums, and grouped data

```bash
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

### Pattern 4: Querying with Date Filters

**Use case**: Find records by date ranges

```bash
# Work items created this week
sf data query \
  --query "SELECT Name, Subject__c, CreatedDate FROM ADM_Work__c WHERE CreatedDate = THIS_WEEK" \
  --target-org "$DEFAULT_ORG"

# Work items updated in last 7 days
sf data query \
  --query "SELECT Name, Subject__c, LastModifiedDate FROM ADM_Work__c WHERE LastModifiedDate = LAST_N_DAYS:7" \
  --target-org "$DEFAULT_ORG"

# Work items created in date range
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

### Pattern 5: Using Tooling API

**Use case**: Query metadata objects

```bash
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

# Query custom fields
sf data query \
  --query "SELECT DeveloperName, DataType, TableEnumOrId FROM CustomField WHERE TableEnumOrId = 'ADM_Work__c'" \
  --use-tooling-api \
  --target-org "$DEFAULT_ORG"
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

### Common Fields (All Verified)

See **Concept 2: Verified Field Names** above for complete field listings.

**Quick Reference - Most Used Fields**:
```
ADM_Work__c: Subject__c, Status__c, Priority__c, Type__c, Assignee__c, Sprint__c, Epic__c
ADM_Epic__c: Description__c, Health__c (NOT Status__c!), Priority__c, OwnerId
ADM_Sprint__c: Start_Date__c, End_Date__c, Scrum_Team__c
User: Name, Email (no Team__c - use ADM_Scrum_Team_Member__c)
```

**Related Field Notation**:
```
Assignee__r.Name            # User name
Assignee__r.Email           # User email
Sprint__r.Name              # Sprint name
Epic__r.Name                # Epic name
Scrum_Team__r.Name          # Team name
Found_in_Build__r.Name      # Build name
```

**IMPORTANT**: When uncertain about fields, always use `sf sobject describe --sobject <ObjectName>` to verify field existence and names before querying.

---

## Best Practices

**Essential Practices:**
```
✅ DO: Use `sf sobject describe` when uncertain about field names (prevents INVALID_FIELD errors)
✅ DO: Use --result-format json for scripting
✅ DO: Use LIMIT to avoid timeouts on large datasets
✅ DO: Query for IDs before creating related records
✅ DO: Use relationship queries (__r) instead of multiple queries
✅ DO: Validate query results before using extracted values
✅ DO: Use WHERE clauses to filter data server-side
✅ DO: Refer to Concept 2 for verified field names
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Guess field names without verifying (use sf sobject describe)
❌ DON'T: Use != in double-quoted queries (shell escapes !)
❌ DON'T: Query without LIMIT (can timeout)
❌ DON'T: Use SELECT * (not supported in SOQL)
❌ DON'T: Assume queries will always return results
❌ DON'T: Forget __c suffix on custom fields
❌ DON'T: Skip validation of jq output (check for null)
❌ DON'T: Assume User has Team__c field (use junction object)
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Use != in double-quoted strings (shell escapes the !)
sf data query --query "SELECT Id FROM ADM_Work__c WHERE Epic__c != null" --target-org gus
# Error: unexpected token: '\'

# ✅ CORRECT: Filter null values using jq instead
sf data query --query "SELECT Id, Epic__c, Epic__r.Name FROM ADM_Work__c WHERE Assignee__c = '005xx000001X8Uz' LIMIT 50" \
  --result-format json --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | select(.Epic__r) | "\(.Epic__r.Name)"'
```

**Why this happens**: In bash/zsh, `!` triggers history expansion even in double quotes, causing the shell to escape it as `\!`. SOQL doesn't recognize this escaped form.

**Solutions**:
1. **Query all records and filter with jq** (recommended for complex conditions)
2. Use `IS NOT NULL` syntax if your SOQL version supports it
3. Use relationship fields like `Epic__r.Id` and check with `select(.Epic__r)` in jq

```bash
# ❌ NEVER: Query without checking results
WORK_ITEM_ID=$(sf data query --query "..." --json | jq -r '.result.records[0].Id')
# If no results, this returns "null" and breaks downstream operations

# ✅ CORRECT: Validate query results
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

QUERY_RESULT=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org "$DEFAULT_ORG")

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

```bash
# ❌ NEVER: Guess field names without verification
sf data query --query "SELECT Id, Name, Team__c FROM User WHERE Id = '005EE000001JW5FYAW'" --target-org gus
# Error: No such column 'Team__c' on entity 'User'

# ✅ CORRECT: Use sf sobject describe to discover correct fields
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Discover available fields
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team
# Result: No Team__c field exists

# Find junction object for team membership
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User") | {name: .name, relationshipName: .relationshipName}'
# Result: Member_Name__c field references User

# Query using correct field
sf data query \
  --query "SELECT Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005EE000001JW5FYAW'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | .Scrum_Team__r.Name'
```

**Why this matters**:
- Field names vary across Salesforce implementations
- Many-to-many relationships use junction objects
- `sf sobject describe` is the authoritative source
- See **Pattern 1: Discovering Object Fields** for detailed examples

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
