---
name: salesforce-soql-queries
description: Query Salesforce data using SOQL and sf CLI. Use for GUS work items, epics, sprints, teams, Agile Accelerator queries, and any Salesforce object queries.
keywords: salesforce, gus, soql, query, work items, epic, sprint, team, agile accelerator, ADM_Work__c, ADM_Epic__c, ADM_Sprint__c, ADM_Scrum_Team_Member__c, user, field verification
---

# Salesforce SOQL Queries

**Scope**: SOQL query syntax, data retrieval, and result formatting
**Lines**: ~920
**Last Updated**: 2025-12-03
**Format Version**: 1.2 (Atomic - Added ADM_Scrum_Team_Member__c field details and LIKE operator on reference fields anti-pattern)

---

## When to Use This Skill

Activate this skill when:
- Querying Salesforce data using SOQL
- Retrieving work items, users, or other records
- Finding record IDs for operations
- Exporting data for analysis
- Building reports or dashboards
- Joining related objects

**⚠️ CRITICAL REQUIREMENT**: Before writing ANY SOQL query, you MUST first run `sf sobject describe --sobject <ObjectName>` to verify field names. DO NOT skip this step. DO NOT assume field names exist, even if they seem obvious (like Department, Title, Team__c on User object). See Concept 1 below.

---

## Core Concepts

### Concept 1: MANDATORY Field Discovery Before Querying

**CRITICAL RULE**: You MUST use `sf sobject describe` BEFORE writing any SOQL query with fields beyond Id and Name. This is NOT optional.

**MANDATORY WORKFLOW**:
1. **FIRST**: Always run `sf sobject describe --sobject <ObjectName>`
2. **SECOND**: Verify the exact field names exist in the output
3. **THIRD**: Only then write your SOQL query using verified field names

**NEVER query fields without verifying them first**, even if they seem obvious (Department, Title, Team__c, etc.).

```bash
# STEP 1: ALWAYS describe the object FIRST
sf sobject describe --sobject User --target-org "$DEFAULT_ORG"

# STEP 2: Search for specific fields (e.g., team-related)
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team

# STEP 3: Find relationship fields
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.relationshipName != null) | {name: .name, relationshipName: .relationshipName, referenceTo: .referenceTo}'

# STEP 4: Only after verification, write your query using confirmed field names
```

**Why this matters**: Guessing field names leads to errors like:
- `No such column 'Team__c' on entity 'User'` (field doesn't exist)
- `No such column 'Department' on entity 'User'` (field may not exist)
- Wrong field type or reference target
- Missing junction objects for many-to-many relationships

**Common fields that DON'T exist**:
- User.Team__c (use ADM_Scrum_Team_Member__c junction object instead)
- User.Department (may not exist in all orgs)
- User.Division (may not exist in all orgs)

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

### Concept 2: Relationship Names - CRITICAL RULES

**CRITICAL**: Relationship names (the `__r` suffix) are DIFFERENT from object names. NEVER assume the relationship name matches the object name.

**Common Mistake**:
```sql
-- ❌ WRONG: Using object name as relationship
SELECT ADM_Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c

-- ✅ CORRECT: Using actual relationship name from describe
SELECT Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c
```

**How to get the correct relationship name**:
```bash
# ALWAYS use sf sobject describe to get the relationship name
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" --json | \
  jq -r '.result.fields[] | select(.name == "Scrum_Team__c") | {field: .name, relationshipName: .relationshipName, referenceTo: .referenceTo}'

# Output: {"field":"Scrum_Team__c","relationshipName":"Scrum_Team__r","referenceTo":["ADM_Scrum_Team__c"]}
```

**Key Rule**: The relationship name is in the `relationshipName` field from `sf sobject describe`, NOT derived from the object name.

### Concept 3: Verified Field Names

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
Id, Name (auto-number: STM-######)
Member_Name__c (→User - ID field, use = not LIKE)
Scrum_Team__c (→ADM_Scrum_Team__c)
Scrum_Team_Name__c (formula field with team name)
Internal_Email__c (member's email address)
Role__c (member's role on team)
Allocation__c, Department__c, Functional_Area__c
Active__c (boolean indicating active membership)
CreatedDate, LastModifiedDate

CRITICAL NOTES:
- Member_Name__c is a User ID lookup field - use = for exact match, NOT LIKE
- Name is auto-numbered (STM-######), not searchable by member name
- Use Internal_Email__c for email, NOT Email__c (doesn't exist)
- No User__c field exists - use Member_Name__c instead
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

**Related Field Notation (VERIFIED via sf sobject describe)**:
```
# From ADM_Work__c
Assignee__r.Name            # User name (field: Assignee__c → User)
Assignee__r.Email           # User email (field: Assignee__c → User)
Sprint__r.Name              # Sprint name (field: Sprint__c → ADM_Sprint__c)
Epic__r.Name                # Epic name (field: Epic__c → ADM_Epic__c)
Found_in_Build__r.Name      # Build name (field: Found_in_Build__c → ADM_Build__c)

# From ADM_Scrum_Team_Member__c
Scrum_Team__r.Name          # Team name (field: Scrum_Team__c → ADM_Scrum_Team__c)
                            # NOTE: Relationship is Scrum_Team__r, NOT ADM_Scrum_Team__r!

# CRITICAL: Relationship names come from the relationshipName field in sf sobject describe,
# NOT from the object name! Always verify with describe before using.
```

### Concept 4: Output Formats

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

### Pattern 1: Discovering Object Fields (MANDATORY FIRST STEP)

**Use case**: Find available fields on an object before querying (avoids INVALID_FIELD errors)

**MANDATORY**: You MUST ALWAYS use `sf sobject describe` as the FIRST STEP before writing ANY query. This is NOT optional, even for fields that seem obvious.

**WORKFLOW - FOLLOW THESE STEPS IN ORDER**:

**STEP 1: Describe the object to see available fields**
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# MANDATORY: Describe the object FIRST
sf sobject describe --sobject User --target-org "$DEFAULT_ORG"
```

**STEP 2: Verify the specific fields you want to query exist**
```bash
# Search for specific field names (e.g., team-related)
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team

# If grep returns nothing, the field doesn't exist - find the junction object instead
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User") | {name: .name, label: .label, relationshipName: .relationshipName}'
```

**STEP 3: Extract verified field names programmatically (RECOMMENDED)**
```bash
# Get all custom fields (fields ending in __c)
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.name | endswith("__c")) | {name: .name, label: .label, type: .type}'

# Find relationship fields (__r notation)
sf sobject describe --sobject ADM_Work__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.relationshipName != null) | {name: .name, relationshipName: .relationshipName, referenceTo: .referenceTo}'
```

**STEP 4: Only after verification, write your query**
```bash
# Example: Finding team membership fields
# After discovering that User doesn't have Team__c, we found ADM_Scrum_Team_Member__c has Member_Name__c
USER_ID="005EE000001JW5FYAW"

# Query teams through the verified junction object
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

### Pattern 2: Querying Team Memberships (Common Pitfall Example)

**Use case**: Find which Scrum teams a user belongs to

**COMMON ERRORS** (see error explanations at bottom):
```bash
# ❌ WRONG: Using non-existent fields
sf data query --query "SELECT Id, Name, User__c FROM ADM_Scrum_Team_Member__c WHERE User__c = '005xx'" --target-org gus
# Error: No such column 'User__c' on entity 'ADM_Scrum_Team_Member__c'

# ❌ WRONG: Using LIKE on an ID field
sf data query --query "SELECT Id, Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c LIKE '%Polillo%'" --target-org gus
# Error: invalid operator on id field

# ❌ WRONG: Looking for email field that doesn't exist
sf data query --query "SELECT Id, Name, Email__c FROM ADM_Scrum_Team_Member__c LIMIT 3" --target-org gus
# Error: No such column 'Email__c' on entity 'ADM_Scrum_Team_Member__c'
```

**CORRECT APPROACH** (following mandatory field verification):
```bash
# STEP 1: ALWAYS describe the object first
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.custom == true) | {name: .name, type: .type, referenceTo: .referenceTo}'

# STEP 2: Verify discovered field names (from describe above):
# - Member_Name__c (User ID lookup - use = not LIKE)
# - Scrum_Team__c (Team ID lookup)
# - Scrum_Team_Name__c (formula field with team name)
# - Internal_Email__c (email field, NOT Email__c)
# - Role__c (member's role)

# STEP 3: Query using verified field names
USER_ID="005EE000001JW5FYAW"

sf data query \
  --query "SELECT Id, Name, Scrum_Team_Name__c, Member_Name__c, Role__c, Internal_Email__c
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --target-org "$DEFAULT_ORG"

# Get just team names as a list
sf data query \
  --query "SELECT Scrum_Team__r.Name
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | .Scrum_Team__r.Name'
```

**Error Explanations**:
- **No `User__c` field**: The correct field is `Member_Name__c` (found via describe)
- **No `Email__c` field**: The correct field is `Internal_Email__c` (found via describe)
- **Cannot use LIKE on `Member_Name__c`**: It's a User ID lookup field (reference type), not a text field
- **`Name` field is auto-numbered**: The Name field is STM-###### (auto-number), not the member's name

### Pattern 3: Finding Record IDs

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

### Pattern 4: Querying Work Items

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

### Pattern 5: Complex Queries with Aggregation

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

### Pattern 6: Querying with Date Filters

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

### Pattern 7: Using Tooling API

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

**Essential Practices (IN ORDER OF IMPORTANCE):**
```
✅ DO: ALWAYS run `sf sobject describe` FIRST before ANY query - THIS IS MANDATORY, NOT OPTIONAL
✅ DO: Verify field names exist in describe output before writing SELECT statements
✅ DO: Get relationship names from the relationshipName field in describe (NOT from object names)
✅ DO: Use --result-format json for scripting
✅ DO: Use LIMIT to avoid timeouts on large datasets
✅ DO: Query for IDs before creating related records
✅ DO: Use relationship queries (__r) instead of multiple queries
✅ DO: Validate query results before using extracted values
✅ DO: Use WHERE clauses to filter data server-side
✅ DO: Refer to Concepts 2-3 for verified field/relationship names (but verify them first!)
```

**Common Mistakes to Avoid (CRITICAL):**
```
❌ DON'T: EVER query fields without running sf sobject describe first - THIS CAUSES MOST ERRORS
❌ DON'T: Assume relationship names match object names (use relationshipName from describe)
❌ DON'T: Use ADM_Scrum_Team__r when the actual relationship is Scrum_Team__r
❌ DON'T: Assume ANY field exists without verification (not even Department, Title, or Team__c)
❌ DON'T: Guess field names without verifying (ALWAYS use sf sobject describe)
❌ DON'T: Write queries based on field names from other orgs or documentation
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

### Critical Violation #1: Querying Fields Without Verification (MOST COMMON ERROR)

```bash
# ❌ NEVER: Query fields without first running sf sobject describe
# This is the #1 cause of INVALID_FIELD errors
sf data query --query "SELECT Id, Name, Username, Email, Department, Division, Title, Team__c FROM User WHERE Username = 'user@example.com'" --target-org gus
# Error: No such column 'Team__c' on entity 'User'
# Error: No such column 'Department' on entity 'User' (may not exist in all orgs)

# ✅ CORRECT: ALWAYS describe the object FIRST
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# STEP 1: Describe to see what fields actually exist
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i "team\|department\|division\|title"

# STEP 2: If fields don't exist, find alternative approach (e.g., junction objects)
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User")'

# STEP 3: Query only with verified fields
sf data query \
  --query "SELECT Id, Name, Username, Email FROM User WHERE Username = 'user@example.com'" \
  --target-org "$DEFAULT_ORG"
```

**Why this is the #1 error**:
- Field names vary across Salesforce orgs and implementations
- Custom fields that exist in one org may not exist in another
- Assuming field names without verification WILL cause failures
- User.Team__c, User.Department, User.Division are NOT guaranteed to exist

### Critical Violation #2: Assuming Relationship Names Match Object Names (VERY COMMON)

```bash
# ❌ NEVER: Assume relationship name matches object name
sf data query --query "SELECT Id, Name, ADM_Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005xx'" --target-org gus
# Error: Didn't understand relationship 'ADM_Scrum_Team__r' in field path

# ✅ CORRECT: Use sf sobject describe to get the actual relationship name
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# STEP 1: Get the actual relationship name from describe
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" --json | \
  jq -r '.result.fields[] | select(.name == "Scrum_Team__c") | {field: .name, relationshipName: .relationshipName}'
# Output: {"field":"Scrum_Team__c","relationshipName":"Scrum_Team__r"}

# STEP 2: Use the verified relationship name (Scrum_Team__r, NOT ADM_Scrum_Team__r)
sf data query \
  --query "SELECT Id, Name, Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005xx'" \
  --target-org "$DEFAULT_ORG"
```

**Why this is a common error**:
- Relationship names are defined in the `relationshipName` field, NOT derived from object names
- Field `Scrum_Team__c` references object `ADM_Scrum_Team__c` but has relationship name `Scrum_Team__r`
- The `ADM_` prefix is NOT part of the relationship name
- ALWAYS use `sf sobject describe` to get the exact `relationshipName` value

### Critical Violation #3: Using Shell Special Characters

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

### Critical Violation #3: Using LIKE on ID/Reference Fields

```bash
# ❌ NEVER: Use LIKE operator on reference/ID fields
sf data query --query "SELECT Id, Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c LIKE '%Polillo%'" --target-org gus
# Error: invalid operator on id field

# ✅ CORRECT: Reference fields require exact match with = operator
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# STEP 1: Find the User ID first
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Name LIKE '%Polillo%' LIMIT 1" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# STEP 2: Use the ID with = operator (NOT LIKE)
sf data query \
  --query "SELECT Id, Name, Scrum_Team_Name__c, Role__c
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --target-org "$DEFAULT_ORG"
```

**Why this happens**:
- Reference fields (fields ending in __c that link to other objects) store IDs, not text
- LIKE is only valid for text fields (string, textarea)
- You must query the referenced object first to get the ID, then use = for exact match
- Check field type with `sf sobject describe` - if `type: "reference"`, use = not LIKE

### Critical Violation #4: Assuming Fields Exist Without Verification

**NOTE**: This is another example of Violation #1. See above for the full explanation.

```bash
# ❌ NEVER: Guess field names without verification (see Violation #1)
sf data query --query "SELECT Id, Name, Team__c FROM User WHERE Id = '005EE000001JW5FYAW'" --target-org gus
# Error: No such column 'Team__c' on entity 'User'

# ✅ CORRECT: Use sf sobject describe to discover correct fields (MANDATORY STEP)
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# STEP 1: Discover available fields
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i team
# Result: No Team__c field exists

# STEP 2: Find junction object for team membership
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User") | {name: .name, relationshipName: .relationshipName}'
# Result: Member_Name__c field references User

# STEP 3: Query using verified fields and correct object
sf data query \
  --query "SELECT Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005EE000001JW5FYAW'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | .Scrum_Team__r.Name'
```

**Why this matters**:
- Field names vary across Salesforce implementations
- Many-to-many relationships use junction objects
- `sf sobject describe` is the authoritative source - USE IT FIRST, ALWAYS
- See **Pattern 1: Discovering Object Fields** and **Violation #1** for detailed examples

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
**Format Version**: 1.2 (Atomic - Added ADM_Scrum_Team_Member__c field details and LIKE operator on reference fields anti-pattern)
