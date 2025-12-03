---
name: salesforce-soql-troubleshooting
description: Common SOQL errors, anti-patterns, and troubleshooting for Salesforce queries. Debug field verification, relationship errors, and query failures.
keywords: salesforce, soql, troubleshooting, errors, anti-patterns, debug, invalid field, relationship errors, query failures, field verification errors
---

# Salesforce SOQL Troubleshooting

**Scope**: Common SOQL errors, anti-patterns, and solutions
**Lines**: ~450
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)

---

## When to Use This Skill

Activate this skill when:
- **Debugging SOQL query errors** - INVALID_FIELD, relationship errors, operator errors
- **Understanding common mistakes** - Why queries fail and how to fix them
- **Learning anti-patterns** - What NOT to do in SOQL queries
- **Troubleshooting field verification** - Field doesn't exist errors
- **Fixing relationship queries** - Wrong relationship name errors

**Prerequisites**: You should understand basic SOQL from `sf-soql-basics.md` first.

---

## Critical Violations (Most Common Errors)

### Critical Violation #1: Querying Fields Without Verification (MOST COMMON ERROR)

**Error Message**: `No such column 'Team__c' on entity 'User'` or `No such column 'Department' on entity 'User'`

**Why This Happens**:
- Field names vary across Salesforce orgs and implementations
- Custom fields that exist in one org may not exist in another
- Assuming field names without verification WILL cause failures
- User.Team__c, User.Department, User.Division are NOT guaranteed to exist

**Example of the Error**:
```bash
# ❌ NEVER: Query fields without first running sf sobject describe
# This is the #1 cause of INVALID_FIELD errors
sf data query --query "SELECT Id, Name, Username, Email, Department, Division, Title, Team__c FROM User WHERE Username = 'user@example.com'" --target-org gus
# Error: No such column 'Team__c' on entity 'User'
# Error: No such column 'Department' on entity 'User' (may not exist in all orgs)
```

**Correct Solution**:
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# ✅ STEP 1: Describe to see what fields actually exist
sf sobject describe --sobject User --target-org "$DEFAULT_ORG" | grep -i "team\|department\|division\|title"

# ✅ STEP 2: If fields don't exist, find alternative approach (e.g., junction objects)
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.referenceTo[]? == "User")'

# ✅ STEP 3: Query only with verified fields
sf data query \
  --query "SELECT Id, Name, Username, Email FROM User WHERE Username = 'user@example.com'" \
  --target-org "$DEFAULT_ORG"
```

**Prevention**: ALWAYS run `sf sobject describe` FIRST before ANY query. This is MANDATORY, not optional.

---

### Critical Violation #2: Assuming Relationship Names Match Object Names (VERY COMMON)

**Error Message**: `Didn't understand relationship 'ADM_Scrum_Team__r' in field path`

**Why This Happens**:
- Relationship names are defined in the `relationshipName` field, NOT derived from object names
- Field `Scrum_Team__c` references object `ADM_Scrum_Team__c` but has relationship name `Scrum_Team__r`
- The `ADM_` prefix is NOT part of the relationship name
- ALWAYS use `sf sobject describe` to get the exact `relationshipName` value

**Example of the Error**:
```bash
# ❌ NEVER: Assume relationship name matches object name
sf data query --query "SELECT Id, Name, ADM_Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005xx'" --target-org gus
# Error: Didn't understand relationship 'ADM_Scrum_Team__r' in field path
```

**Correct Solution**:
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# ✅ STEP 1: Get the actual relationship name from describe
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" --json | \
  jq -r '.result.fields[] | select(.name == "Scrum_Team__c") | {field: .name, relationshipName: .relationshipName}'
# Output: {"field":"Scrum_Team__c","relationshipName":"Scrum_Team__r"}

# ✅ STEP 2: Use the verified relationship name (Scrum_Team__r, NOT ADM_Scrum_Team__r)
sf data query \
  --query "SELECT Id, Name, Scrum_Team__r.Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c = '005xx'" \
  --target-org "$DEFAULT_ORG"
```

**Key Rule**: The relationship name is in the `relationshipName` field from `sf sobject describe`, NOT derived from the object name.

---

### Critical Violation #3: Using Shell Special Characters

**Error Message**: `unexpected token: '\'`

**Why This Happens**:
In bash/zsh, `!` triggers history expansion even in double quotes, causing the shell to escape it as `\!`. SOQL doesn't recognize this escaped form.

**Example of the Error**:
```bash
# ❌ NEVER: Use != in double-quoted strings (shell escapes the !)
sf data query --query "SELECT Id FROM ADM_Work__c WHERE Epic__c != null" --target-org gus
# Error: unexpected token: '\'
```

**Correct Solutions**:

**Solution 1: Query all records and filter with jq (RECOMMENDED)**
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# ✅ CORRECT: Filter null values using jq instead
sf data query --query "SELECT Id, Epic__c, Epic__r.Name FROM ADM_Work__c WHERE Assignee__c = '005xx000001X8Uz' LIMIT 50" \
  --result-format json --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | select(.Epic__r) | "\(.Epic__r.Name)"'
```

**Solution 2: Use relationship fields and check with jq**
```bash
# Check for non-null relationships using jq select()
sf data query \
  --query "SELECT Id, Name, Epic__r.Id FROM ADM_Work__c LIMIT 50" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[] | select(.Epic__r) | .Name'
```

---

### Critical Violation #4: Using LIKE on ID/Reference Fields

**Error Message**: `invalid operator on id field`

**Why This Happens**:
- Reference fields (fields ending in __c that link to other objects) store IDs, not text
- LIKE is only valid for text fields (string, textarea)
- You must query the referenced object first to get the ID, then use = for exact match
- Check field type with `sf sobject describe` - if `type: "reference"`, use = not LIKE

**Example of the Error**:
```bash
# ❌ NEVER: Use LIKE operator on reference/ID fields
sf data query --query "SELECT Id, Name FROM ADM_Scrum_Team_Member__c WHERE Member_Name__c LIKE '%Polillo%'" --target-org gus
# Error: invalid operator on id field
```

**Correct Solution**:
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# ✅ STEP 1: Find the User ID first
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Name LIKE '%Polillo%' LIMIT 1" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# ✅ STEP 2: Use the ID with = operator (NOT LIKE)
sf data query \
  --query "SELECT Id, Name, Scrum_Team_Name__c, Role__c
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --target-org "$DEFAULT_ORG"
```

**How to Check Field Type**:
```bash
# Verify if field is a reference type (requires = not LIKE)
sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" --json | \
  jq -r '.result.fields[] | select(.name == "Member_Name__c") | {name: .name, type: .type, referenceTo: .referenceTo}'
# Output: {"name":"Member_Name__c","type":"reference","referenceTo":["User"]}
```

---

### Critical Violation #5: Not Validating Query Results

**Error Message**: Downstream errors with `null` values or empty results

**Why This Happens**:
- Queries may return zero results
- Extracting values from empty results returns "null" as a string
- Using "null" in subsequent operations causes failures
- Always validate before using extracted values

**Example of the Error**:
```bash
# ❌ NEVER: Query without checking results
WORK_ITEM_ID=$(sf data query --query "..." --json | jq -r '.result.records[0].Id')
# If no results, this returns "null" and breaks downstream operations
```

**Correct Solution**:
```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# ✅ CORRECT: Validate query results
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

echo "Work Item ID: $WORK_ITEM_ID"
```

---

## Common Field Errors

### Error: Field Doesn't Exist on Junction Object

**Scenario**: Querying ADM_Scrum_Team_Member__c with wrong field names

**Common Mistakes**:
```bash
# ❌ Field User__c doesn't exist (correct: Member_Name__c)
SELECT Id, User__c FROM ADM_Scrum_Team_Member__c

# ❌ Field Email__c doesn't exist (correct: Internal_Email__c)
SELECT Id, Email__c FROM ADM_Scrum_Team_Member__c

# ❌ Name field is auto-numbered STM-######, not searchable by member name
SELECT Id FROM ADM_Scrum_Team_Member__c WHERE Name LIKE '%Polillo%'
```

**Verified Fields** (from sf sobject describe):
```
Member_Name__c (→User - use = not LIKE)
Scrum_Team__c (→ADM_Scrum_Team__c)
Scrum_Team_Name__c (formula field)
Internal_Email__c (NOT Email__c)
Role__c, Allocation__c, Department__c, Active__c
```

**Correct Approach**:
```bash
# Always describe first
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

sf sobject describe --sobject ADM_Scrum_Team_Member__c --target-org "$DEFAULT_ORG" | \
  jq '.fields[] | select(.custom == true) | {name: .name, type: .type}'

# Then query with verified fields
USER_ID="005EE000001JW5FYAW"
sf data query \
  --query "SELECT Id, Name, Scrum_Team_Name__c, Member_Name__c, Role__c, Internal_Email__c
    FROM ADM_Scrum_Team_Member__c
    WHERE Member_Name__c = '${USER_ID}'" \
  --target-org "$DEFAULT_ORG"
```

---

### Error: Epic Field Name Wrong

**Scenario**: ADM_Epic__c uses `Health__c` not `Status__c`

**Common Mistake**:
```bash
# ❌ WRONG: Epic doesn't have Status__c field
SELECT Id, Name, Status__c FROM ADM_Epic__c
# Error: No such column 'Status__c' on entity 'ADM_Epic__c'
```

**Correct Solution**:
```bash
# ✅ CORRECT: Epic uses Health__c field
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Verify first
sf sobject describe --sobject ADM_Epic__c --target-org "$DEFAULT_ORG" | grep -i "status\|health"

# Query with correct field
sf data query \
  --query "SELECT Id, Name, Health__c, Priority__c FROM ADM_Epic__c" \
  --target-org "$DEFAULT_ORG"
```

---

## Query Performance Issues

### Issue: Query Timeout

**Symptom**: Query takes too long or times out

**Causes**:
- No LIMIT clause on large objects
- Complex WHERE clauses without indexes
- Querying too many fields
- Using LIKE with % on both sides

**Solutions**:
```bash
# ❌ BAD: No LIMIT on large object
SELECT Id, Name, Subject__c FROM ADM_Work__c WHERE Status__c = 'New'

# ✅ GOOD: Add LIMIT
SELECT Id, Name, Subject__c FROM ADM_Work__c WHERE Status__c = 'New' LIMIT 200

# ❌ BAD: LIKE with % on both sides (slow)
SELECT Id FROM ADM_Work__c WHERE Subject__c LIKE '%feature%'

# ✅ BETTER: LIKE with % on right only (uses index)
SELECT Id FROM ADM_Work__c WHERE Subject__c LIKE 'feature%'

# ✅ BEST: Use indexed fields in WHERE clause
SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'
```

---

### Issue: Too Many SOQL Queries

**Symptom**: Hitting SOQL query limits

**Causes**:
- Querying in loops
- Not using relationship queries
- Multiple queries when one would suffice

**Solutions**:
```bash
# ❌ BAD: Two separate queries
sf data query --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-123'" --target-org "$DEFAULT_ORG"
sf data query --query "SELECT Name, Email FROM User WHERE Id = '005xx'" --target-org "$DEFAULT_ORG"

# ✅ GOOD: Single query with relationship
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

sf data query \
  --query "SELECT Id, Name, Assignee__r.Name, Assignee__r.Email FROM ADM_Work__c WHERE Name = 'W-123'" \
  --target-org "$DEFAULT_ORG"
```

---

## Best Practices Summary

**Essential Practices (IN ORDER OF IMPORTANCE)**:
```
✅ DO: ALWAYS run `sf sobject describe` FIRST before ANY query - THIS IS MANDATORY
✅ DO: Verify field names exist in describe output before writing SELECT statements
✅ DO: Get relationship names from relationshipName field (NOT from object names)
✅ DO: Use = operator for ID/reference fields (NOT LIKE)
✅ DO: Filter null values with jq instead of != in queries
✅ DO: Validate query results before using extracted values
✅ DO: Use LIMIT to avoid timeouts on large datasets
✅ DO: Use --result-format json for scripting
```

**Common Mistakes to Avoid (CRITICAL)**:
```
❌ DON'T: EVER query fields without running sf sobject describe first
❌ DON'T: Assume relationship names match object names
❌ DON'T: Use ADM_Scrum_Team__r when actual relationship is Scrum_Team__r
❌ DON'T: Assume ANY field exists without verification
❌ DON'T: Use != in double-quoted queries (shell escapes !)
❌ DON'T: Use LIKE on ID/reference fields (use = instead)
❌ DON'T: Query without LIMIT (can timeout)
❌ DON'T: Use SELECT * (not supported in SOQL)
❌ DON'T: Skip validation of jq output (check for null)
```

---

## Troubleshooting Workflow

**When a query fails, follow these steps**:

1. **Check the error message** - What field or relationship failed?

2. **Run sf sobject describe** - Verify field exists and get exact name:
   ```bash
   sf sobject describe --sobject <ObjectName> --target-org "$DEFAULT_ORG"
   ```

3. **Check field type** - Is it reference, string, or formula?
   ```bash
   sf sobject describe --sobject <ObjectName> --target-org "$DEFAULT_ORG" --json | \
     jq -r '.result.fields[] | select(.name == "FieldName__c") | {name: .name, type: .type}'
   ```

4. **Get relationship name** - If querying related fields:
   ```bash
   sf sobject describe --sobject <ObjectName> --target-org "$DEFAULT_ORG" --json | \
     jq -r '.result.fields[] | select(.name == "FieldName__c") | {field: .name, relationshipName: .relationshipName}'
   ```

5. **Test with minimal query** - Remove complexity and add back:
   ```bash
   sf data query --query "SELECT Id, Name FROM Object__c LIMIT 5" --target-org "$DEFAULT_ORG"
   ```

6. **Add fields one by one** - Identify which field causes the error

7. **Check for shell escaping** - Use single quotes or escape special characters

8. **Validate results** - Check totalSize before extracting values

---

## Related Skills

- `sf-soql-basics.md` - Start here for field discovery and basic queries
- `sf-soql-advanced.md` - Complex queries, aggregation, date filters, tooling API
- `sf-work-items.md` - Creating and managing work items
- `sf-org-auth.md` - Authentication and user info
- `sf-record-operations.md` - Create and update records

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Split from sf-soql-queries v1.2)
