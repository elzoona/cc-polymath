---
name: salesforce-record-operations
description: Create and update Salesforce records using sf CLI. Use for creating/updating GUS work items, epics, sprints, and any Salesforce object.
keywords: salesforce, gus, create, update, record, work item, epic, sprint, sf data, REST API, CRUD operations
---

# Salesforce Record Operations

**Scope**: Creating, updating, and managing individual Salesforce records
**Lines**: ~438
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Creating new Salesforce records
- Updating existing records
- Working with individual records (not bulk operations)
- Setting field values on records
- Using REST API for custom operations

---

## Core Concepts

### Concept 1: Creating Records

**Basic Syntax**:
```bash
sf data create record \
  --sobject <ObjectName> \
  --values "Field1=Value1 Field2=Value2" \
  --target-org <alias>
```

**Examples**:

```bash
# Create a simple record
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement new feature' Status__c='New' Type__c='User Story'" \
  --target-org "$DEFAULT_ORG"

# Create with multiple fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Fix critical bug' \
           Status__c='New' \
           Priority__c='P1' \
           Type__c='Bug' \
           Description__c='<p>Bug details here</p>'" \
  --target-org "$DEFAULT_ORG"

# Create an Epic
sf data create record \
  --sobject ADM_Epic__c \
  --values "Name='Q1 2024 Features' Health__c='On Track' Description__c='Major features for Q1'" \
  --target-org "$DEFAULT_ORG"
```

### Concept 2: Updating Records

**Update by Record ID**:
```bash
sf data update record \
  --sobject <ObjectName> \
  --record-id <SalesforceId> \
  --values "Field1=NewValue" \
  --target-org <alias>
```

**Update by Field Match**:
```bash
sf data update record \
  --sobject <ObjectName> \
  --where "Field=Value" \
  --values "Field1=NewValue" \
  --target-org <alias>
```

**Examples**:

```bash
# Update by ID
sf data update record \
  --sobject ADM_Work__c \
  --record-id a07xx00000ABCDE \
  --values "Status__c='In Progress'" \
  --target-org "$DEFAULT_ORG"

# Update multiple fields
sf data update record \
  --sobject ADM_Work__c \
  --record-id a07xx00000ABCDE \
  --values "Status__c='Code Review' Assignee__c='005xx000001X8Uz' Story_Points__c=5" \
  --target-org "$DEFAULT_ORG"

# Update by field match
sf data update record \
  --sobject ADM_Work__c \
  --where "Name='W-12345678'" \
  --values "Status__c='In Progress'" \
  --target-org "$DEFAULT_ORG"
```

### Concept 3: REST API Direct Calls

**Use case**: Make custom REST API calls for operations not covered by standard commands

```bash
# Get record details via REST API
sf api request rest \
  "/services/data/v56.0/sobjects/ADM_Work__c/a07xx00000ABCDE" \
  --target-org "$DEFAULT_ORG"

# Update multiple fields via PATCH
sf api request rest \
  "/services/data/v56.0/sobjects/ADM_Work__c/a07xx00000ABCDE" \
  --method PATCH \
  --body '{"Status__c": "Fixed", "Resolved_On__c": "2024-01-15"}' \
  --target-org "$DEFAULT_ORG"

# Query using REST API
sf api request rest \
  "/services/data/v56.0/query?q=SELECT+Id,Name+FROM+ADM_Work__c+LIMIT+10" \
  --target-org "$DEFAULT_ORG"

# Create record via REST API
sf api request rest \
  "/services/data/v56.0/sobjects/ADM_Work__c" \
  --method POST \
  --body '{"Subject__c": "New Story", "Status__c": "New", "Type__c": "User Story"}' \
  --target-org "$DEFAULT_ORG"
```

---

## Patterns

### Pattern 1: Create Record with Query for IDs

**Use case**: Create records with relationships to other objects

```bash
# ❌ Bad: Hardcoding IDs
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Feature' Assignee__c='005xx000001X8Uz' Sprint__c='a1Fxx000002EFGH'" \
  --target-org "$DEFAULT_ORG"

# ✅ Good: Query for IDs first
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Get user ID (using dynamic user email)
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Email = '${USER_EMAIL}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# Get sprint ID
SPRINT_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Sprint__c WHERE Name = 'Sprint 42'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# Get epic ID
EPIC_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# Create work item with relationships
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement OAuth' \
           Status__c='New' \
           Priority__c='P1' \
           Type__c='User Story' \
           Story_Points__c=8 \
           Assignee__c='${USER_ID}' \
           Sprint__c='${SPRINT_ID}' \
           Epic__c='${EPIC_ID}'" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 2: Update with Validation

**Use case**: Update records only if they exist

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Query to verify record exists
QUERY_RESULT=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org "$DEFAULT_ORG")

RECORD_COUNT=$(echo "$QUERY_RESULT" | jq -r '.result.totalSize')

if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "Error: Work item W-12345678 not found"
  exit 1
fi

WORK_ITEM_ID=$(echo "$QUERY_RESULT" | jq -r '.result.records[0].Id')

# Update the record
sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='In Progress'" \
  --target-org "$DEFAULT_ORG"

echo "Updated work item W-12345678 to In Progress"
```

### Pattern 3: Complex Field Updates with HTML

**Use case**: Update rich text fields with HTML content

```bash
# Update work item description with HTML
sf data update record \
  --sobject ADM_Work__c \
  --record-id a07xx00000ABCDE \
  --values "Description__c='<p><strong>Overview</strong></p><ul><li>Item 1</li><li>Item 2</li></ul><p>Additional details here.</p>'" \
  --target-org "$DEFAULT_ORG"

# Create work item with formatted description
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Database migration' \
           Description__c='<p><strong>Steps:</strong></p><ol><li>Backup current data</li><li>Run migration script</li><li>Verify integrity</li></ol>' \
           Status__c='New' \
           Type__c='User Story'" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 4: Atomic Updates with Error Handling

**Use case**: Update multiple fields safely with rollback capability

```bash
# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Capture current state before update
CURRENT_STATE=$(sf data query \
  --query "SELECT Id, Status__c, Assignee__c FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org "$DEFAULT_ORG")

WORK_ITEM_ID=$(echo "$CURRENT_STATE" | jq -r '.result.records[0].Id')
OLD_STATUS=$(echo "$CURRENT_STATE" | jq -r '.result.records[0].Status__c')
OLD_ASSIGNEE=$(echo "$CURRENT_STATE" | jq -r '.result.records[0].Assignee__c')

# Attempt update
if sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='Code Review' Assignee__c='${NEW_ASSIGNEE_ID}'" \
  --target-org "$DEFAULT_ORG"; then
  echo "Update successful"
else
  echo "Update failed! Rolling back..."
  # Rollback to previous state
  sf data update record \
    --sobject ADM_Work__c \
    --record-id "$WORK_ITEM_ID" \
    --values "Status__c='${OLD_STATUS}' Assignee__c='${OLD_ASSIGNEE}'" \
    --target-org "$DEFAULT_ORG"
  exit 1
fi
```

---

## Quick Reference

### Common Commands

```bash
# Create record
sf data create record --sobject <Object> --values "Field=Value" --target-org <alias>

# Update by ID
sf data update record --sobject <Object> --record-id <Id> --values "Field=Value" --target-org <alias>

# Update by field match
sf data update record --sobject <Object> --where "Field=Value" --values "Field=NewValue" --target-org <alias>

# REST API call
sf api request rest "<endpoint>" --method <GET|POST|PATCH|DELETE> --target-org <alias>
```

### Required Fields by Object

**ADM_Work__c (Work Items)**:
```
Subject__c       (required)
Status__c        (required)
Type__c          (required)
Priority__c      (recommended)
```

**ADM_Epic__c (Epics)**:
```
Name             (required)
Health__c        (recommended: On Track, At Risk, Off Track, Completed, Canceled)
Priority__c      (optional: P0, P1, P2, P3)
Description__c   (optional, HTML rich text)
Note: Epics do NOT have Status__c - use Health__c
```

**ADM_Sprint__c (Sprints)**:
```
Name             (required)
Start_Date__c    (recommended)
End_Date__c      (recommended)
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Query for IDs before creating related records
✅ DO: Include all required fields when creating records
✅ DO: Validate record existence before updates
✅ DO: Use HTML formatting for rich text fields
✅ DO: Handle errors and provide meaningful messages
✅ DO: Use --result-format json for scripting
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Hardcode record IDs (query for them)
❌ DON'T: Create records without required fields
❌ DON'T: Update records without verifying they exist
❌ DON'T: Forget __c suffix on custom fields
❌ DON'T: Skip error handling in scripts
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Update without checking existence
sf data update record \
  --sobject ADM_Work__c \
  --record-id UNKNOWN_ID \
  --values "Status__c='Fixed'"

# ✅ CORRECT: Query first, then update
RECORD_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name='W-12345678'" \
  --result-format json --target-org gus | jq -r '.result.records[0].Id')

if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "null" ]; then
  echo "Error: Record not found"
  exit 1
fi

sf data update record \
  --sobject ADM_Work__c \
  --record-id "$RECORD_ID" \
  --values "Status__c='Fixed'" \
  --target-org "$DEFAULT_ORG"
```

```bash
# ❌ Don't: Missing required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='New Story'" \
  --target-org "$DEFAULT_ORG"

# ✅ Correct: Include all required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='New Story' Status__c='New' Type__c='User Story' Priority__c='P2'" \
  --target-org "$DEFAULT_ORG"
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Always verify target org before updates
- ⚠️ Query before update to verify record existence
- ⚠️ Validate all input values
- ⚠️ Be cautious with delete operations (use bulk with care)
- ⚠️ Don't expose sensitive data in field values

---

## Related Skills

- `sf-org-auth.md` - Authentication for operations
- `sf-soql-queries.md` - Query for record IDs
- `sf-work-items.md` - Work with GUS-specific objects
- `sf-bulk-operations.md` - Bulk updates for multiple records

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
