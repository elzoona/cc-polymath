---
name: salesforce-soql-basics
description: Basic SOQL queries, field discovery, and fundamental patterns for Salesforce. Start here for querying GUS work items, users, and basic data retrieval.
keywords: salesforce, gus, soql, query, basics, field verification, sf sobject describe, beginner, getting started, team lookup, user query
---

# Salesforce SOQL Basics

**Scope**: Basic SOQL syntax, mandatory field discovery, and fundamental query patterns
**Lines**: ~402
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)

---

## When to Use This Skill

Activate this skill when:
- **Starting with SOQL queries** - Learn the basics first
- **Querying simple data** - Users, work items by ID, basic lookups
- **Learning field verification** - Understand the mandatory describe workflow
- **Looking up team memberships** - Find which teams a user belongs to
- **Finding record IDs** - Locate User IDs, Epic IDs, etc.

**⚠️ CRITICAL REQUIREMENT**: Before writing ANY SOQL query, you MUST first run `sf sobject describe --sobject <ObjectName>` to verify field names. DO NOT skip this step. DO NOT assume field names exist, even if they seem obvious (like Department, Title, Team__c on User object).

**For advanced queries**: See `sf-soql-advanced.md`
**For troubleshooting**: See `sf-soql-troubleshooting.md`

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
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

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

### Concept 3: Relationship Names - CRITICAL RULES

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

### Concept 4: Verified Field Names for Common GUS Objects

**IMPORTANT**: These are VERIFIED via `sf sobject describe` but you should still verify them in YOUR org before querying.

**ADM_Work__c (Work Items)**:
```
Id, Name, Subject__c, Status__c, Priority__c, Type__c
Story_Points__c, Assignee__c (→User), Sprint__c (→ADM_Sprint__c)
Epic__c (→ADM_Epic__c), Found_in_Build__c (→ADM_Build__c)
Product_Tag__c (→ADM_Product_Tag__c), Description__c
CreatedDate, LastModifiedDate
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

**Related Field Notation (VERIFIED)**:
```
# From ADM_Work__c
Assignee__r.Name            # User name (field: Assignee__c → User)
Assignee__r.Email           # User email (field: Assignee__c → User)
Sprint__r.Name              # Sprint name (field: Sprint__c → ADM_Sprint__c)
Epic__r.Name                # Epic name (field: Epic__c → ADM_Epic__c)

# From ADM_Scrum_Team_Member__c
Scrum_Team__r.Name          # Team name (field: Scrum_Team__c → ADM_Scrum_Team__c)
                            # NOTE: Relationship is Scrum_Team__r, NOT ADM_Scrum_Team__r!

# CRITICAL: Relationship names come from the relationshipName field in sf sobject describe,
# NOT from the object name! Always verify with describe before using.
```

### Concept 5: Output Formats

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
```

---

## Basic Patterns

### Pattern 1: Discovering Object Fields (MANDATORY FIRST STEP)

**Use case**: Find available fields on an object before querying (avoids INVALID_FIELD errors)

**MANDATORY**: You MUST ALWAYS use `sf sobject describe` as the FIRST STEP before writing ANY query. This is NOT optional, even for fields that seem obvious.

**WORKFLOW - FOLLOW THESE STEPS IN ORDER**:

**STEP 1: Describe the object to see available fields**
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

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

### Pattern 2: Querying Team Memberships (Common Example)

**Use case**: Find which Scrum teams a user belongs to

**COMMON ERRORS** (see sf-soql-troubleshooting.md for details):
- Using non-existent `User__c` field (correct field is `Member_Name__c`)
- Using `LIKE` on ID fields (must use `=` for exact match)
- Looking for `Email__c` field (correct field is `Internal_Email__c`)

**CORRECT APPROACH** (following mandatory field verification):
```bash
# STEP 1: ALWAYS describe the object first
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.custom == true) | {name: .name, type: .type, referenceTo: .referenceTo}'

# STEP 2: Query using verified field names
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

### Pattern 3: Finding Record IDs

**Use case**: Locate record IDs for references (Users, Epics, Sprints, Product Tags)

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty' || sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[0].alias // empty')

# Find user ID by name
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Name LIKE '%John Doe%'" \
  --target-org "$DEFAULT_ORG"

# Find user ID by email (use dynamic user email)
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Email = '${USER_EMAIL}'" \
  --target-org "$DEFAULT_ORG"

# Get ID with jq for scripting
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Email = '${USER_EMAIL}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

echo "User ID: $USER_ID"
```

---

## Best Practices

**Essential Practices (IN ORDER OF IMPORTANCE)**:
```
✅ DO: ALWAYS run `sf sobject describe` FIRST before ANY query - THIS IS MANDATORY, NOT OPTIONAL
✅ DO: Verify field names exist in describe output before writing SELECT statements
✅ DO: Get relationship names from the relationshipName field in describe (NOT from object names)
✅ DO: Use --result-format json for scripting
✅ DO: Use LIMIT to avoid timeouts on large datasets
✅ DO: Validate query results before using extracted values
```

**Common Mistakes to Avoid (CRITICAL)**:
```
❌ DON'T: EVER query fields without running sf sobject describe first - THIS CAUSES MOST ERRORS
❌ DON'T: Assume relationship names match object names (use relationshipName from describe)
❌ DON'T: Use ADM_Scrum_Team__r when the actual relationship is Scrum_Team__r
❌ DON'T: Assume ANY field exists without verification (not even Department, Title, or Team__c)
❌ DON'T: Guess field names without verifying (ALWAYS use sf sobject describe)
❌ DON'T: Use LIKE on ID/reference fields (use = for exact match)
```

---

## Quick Reference

### Common SOQL Operators
```
=           Equal to
!=          Not equal to (avoid in double quotes - shell escapes !)
<           Less than
>           Greater than
<=          Less than or equal
>=          Greater than or equal
LIKE        Pattern match (use % for wildcard, NOT for ID fields)
IN          Match any value in list
NOT IN      Don't match any value in list
```

### Common Fields (Verified)

**Quick Reference - Most Used Fields**:
```
ADM_Work__c: Subject__c, Status__c, Priority__c, Type__c, Assignee__c, Sprint__c, Epic__c
ADM_Scrum_Team_Member__c: Member_Name__c, Scrum_Team__c, Internal_Email__c, Role__c
User: Name, Email, Username (no Team__c - use ADM_Scrum_Team_Member__c)
```

**IMPORTANT**: When uncertain about fields, always use `sf sobject describe --sobject <ObjectName>` to verify field existence and names before querying.

---

## Related Skills

- `sf-soql-advanced.md` - Complex queries, aggregation, date filters, tooling API
- `sf-soql-troubleshooting.md` - Anti-patterns, common errors, and solutions
- `sf-org-auth.md` - Authentication and user info
- `sf-record-operations.md` - Create/update records
- `sf-work-items.md` - Work with GUS objects

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)
