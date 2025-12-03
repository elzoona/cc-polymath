---
name: salesforce-automation
description: Automate Salesforce operations with git integration and CI/CD. Use for automating GUS work item updates, inferring WI numbers from branches, and git workflows.
keywords: salesforce, gus, automation, git, CI/CD, work item, branch, workflow, hook, automated updates, WI inference
---

# Salesforce Automation

**Scope**: Git integration, WI inference, and automated workflows
**Lines**: ~437
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Integrating Salesforce with git workflows
- Inferring WI numbers from branch names
- Automating Chatter updates from CI/CD
- Building automated workflows
- Creating git hooks for Salesforce operations
- Syncing git and GUS automatically

---

## Core Concepts

### Concept 1: WI Number Inference

Extract WI numbers from git branch names automatically.

**Common branch patterns**:
- `W-12345678`
- `wi-12345678`
- `12345678-feature-name`
- `feature/W-12345678`
- `bugfix/12345678-fix-issue`

### Concept 2: Git Integration Points

**Pre-commit**: Validate WI exists before commit
**Post-commit**: Post to Chatter after commit
**Pre-push**: Update WI status before push
**Post-merge**: Close WI after merge to main

---

## Patterns

### Pattern 1: Inferring WI Number from Git Branch

**Use case**: Automatically determine WI number from current git branch name

**IMPORTANT**: The WI number (e.g., W-12345678) is stored in the `Name` field, NOT the `Id` field. You must query by `Name` to get the actual Salesforce record `Id`.

```bash
# ❌ Bad: Asking user for WI number when it's in the branch
echo "What's the WI number?"

# ✅ Good: Extract WI number from git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

# Validate WI number was found
if [ -z "$WI_NUMBER" ]; then
  echo "Error: No WI number found in branch name: $BRANCH"
  exit 1
fi

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Query work item by Name field (NOT Id) to get the record details
QUERY_RESULT=$(sf data query \
  --query "SELECT Id, Name, Subject__c, Status__c FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org "$DEFAULT_ORG" \
  --json)

# Check if query returned results
RECORD_COUNT=$(echo "$QUERY_RESULT" | jq -r '.result.totalSize')
if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "Error: Work item W-${WI_NUMBER} not found in GUS"
  exit 1
fi

# Get the Salesforce record Id from the WI Name
WORK_ITEM_ID=$(echo "$QUERY_RESULT" | jq -r '.result.records[0].Id')

# Validate we got a valid ID
if [ -z "$WORK_ITEM_ID" ] || [ "$WORK_ITEM_ID" = "null" ]; then
  echo "Error: Failed to extract Salesforce ID for W-${WI_NUMBER}"
  exit 1
fi

echo "Found work item: W-${WI_NUMBER} (ID: ${WORK_ITEM_ID})"
```

**Benefits**:
- No need to manually specify WI numbers
- Reduces errors from copying/pasting wrong WI numbers
- Enables automation based on git workflow
- Makes scripts more context-aware

**Key Points**:
- WI number (W-12345678) is in the `Name` field, NOT the `Id` field
- Always query `WHERE Name = 'W-...'` to find work items
- Extract the `Id` field from query results for record operations
- Use `--json` flag for easier parsing with `jq`

### Pattern 2: Automated Chatter Updates from Git

**Use case**: Post commit information to Chatter automatically

```bash
#!/bin/bash
# post-commit hook

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Get WI from branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

if [ -n "$WI_NUMBER" ]; then
  # Get work item ID
  WORK_ITEM_ID=$(sf data query \
    --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
    --target-org "$DEFAULT_ORG" \
    --json | jq -r '.result.records[0].Id')

  if [ -n "$WORK_ITEM_ID" ] && [ "$WORK_ITEM_ID" != "null" ]; then
    # Get latest commit
    COMMIT_MSG=$(git log -1 --pretty=%B)
    COMMIT_HASH=$(git log -1 --pretty=%h)

    # Post to Chatter
    sf data create record \
      --sobject FeedItem \
      --values "ParentId=${WORK_ITEM_ID} \
               Body='Commit ${COMMIT_HASH}: ${COMMIT_MSG}'" \
      --target-org "$DEFAULT_ORG"

    echo "Posted commit to W-${WI_NUMBER}"
  fi
fi
```

### Pattern 3: CI/CD Integration

**Use case**: Update work items from CI/CD pipeline

```bash
#!/bin/bash
# ci-build.sh

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Extract WI from branch or PR
WI_NUMBER=$(echo "$CI_BRANCH_NAME" | grep -oE '[0-9]{8}' | head -1)

if [ -z "$WI_NUMBER" ]; then
  echo "No WI number found, skipping GUS update"
  exit 0
fi

# Get work item
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id, Status__c FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org "$DEFAULT_ORG" \
  --json | jq -r '.result.records[0].Id')

if [ -z "$WORK_ITEM_ID" ] || [ "$WORK_ITEM_ID" = "null" ]; then
  echo "Work item W-${WI_NUMBER} not found"
  exit 0
fi

# Post build status
if [ "$BUILD_STATUS" = "success" ]; then
  sf data create record \
    --sobject FeedItem \
    --values "ParentId=${WORK_ITEM_ID} \
             Body='✅ Build #${BUILD_NUMBER} passed
All tests: ${TEST_TOTAL}/${TEST_TOTAL} ✓
Coverage: ${COVERAGE}%
Ready for deployment

Build: ${BUILD_URL}'" \
    --target-org "$DEFAULT_ORG"

  # Update status if still in progress
  CURRENT_STATUS=$(sf data query \
    --query "SELECT Status__c FROM ADM_Work__c WHERE Id = '${WORK_ITEM_ID}'" \
    --target-org "$DEFAULT_ORG" \
    --json | jq -r '.result.records[0].Status__c')

  if [ "$CURRENT_STATUS" = "In Progress" ]; then
    sf data update record \
      --sobject ADM_Work__c \
      --record-id "$WORK_ITEM_ID" \
      --values "Status__c='Code Review'" \
      --target-org "$DEFAULT_ORG"

    echo "Moved W-${WI_NUMBER} to Code Review"
  fi
else
  sf data create record \
    --sobject FeedItem \
    --values "ParentId=${WORK_ITEM_ID} \
             Body='❌ Build #${BUILD_NUMBER} failed
Failed tests: ${TEST_FAILED}/${TEST_TOTAL}
See: ${BUILD_URL}
Please investigate.'" \
    --target-org "$DEFAULT_ORG"
fi
```

### Pattern 4: Pre-push Validation

**Use case**: Validate WI status before allowing push

```bash
#!/bin/bash
# pre-push hook

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

if [ -n "$WI_NUMBER" ]; then
  # Check if WI exists and is in valid state
  WI_STATUS=$(sf data query \
    --query "SELECT Status__c FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
    --target-org "$DEFAULT_ORG" \
    --json | jq -r '.result.records[0].Status__c')

  if [ "$WI_STATUS" = "null" ] || [ -z "$WI_STATUS" ]; then
    echo "Error: Work item W-${WI_NUMBER} not found in GUS"
    echo "Please create the work item before pushing"
    exit 1
  fi

  if [ "$WI_STATUS" = "Closed" ]; then
    echo "Error: Work item W-${WI_NUMBER} is already closed"
    echo "Please reopen or create a new work item"
    exit 1
  fi

  echo "✓ Work item W-${WI_NUMBER} validated (Status: ${WI_STATUS})"
fi
```

### Pattern 5: Automated Status Transitions

**Use case**: Auto-update WI status based on git events

```bash
#!/bin/bash
# auto-status-update.sh

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

if [ -z "$WI_NUMBER" ]; then
  echo "No WI number in branch"
  exit 0
fi

# Get work item
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id, Status__c FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org "$DEFAULT_ORG" \
  --json | jq -r '.result.records[0].Id')

CURRENT_STATUS=$(sf data query \
  --query "SELECT Status__c FROM ADM_Work__c WHERE Id = '${WORK_ITEM_ID}'" \
  --target-org "$DEFAULT_ORG" \
  --json | jq -r '.result.records[0].Status__c')

# Transition logic based on event
case "$1" in
  start)
    if [ "$CURRENT_STATUS" = "New" ]; then
      sf data update record \
        --sobject ADM_Work__c \
        --record-id "$WORK_ITEM_ID" \
        --values "Status__c='In Progress'" \
        --target-org "$DEFAULT_ORG"
      echo "Started work on W-${WI_NUMBER}"
    fi
    ;;

  review)
    if [ "$CURRENT_STATUS" = "In Progress" ]; then
      sf data update record \
        --sobject ADM_Work__c \
        --record-id "$WORK_ITEM_ID" \
        --values "Status__c='Code Review'" \
        --target-org "$DEFAULT_ORG"
      echo "Moved W-${WI_NUMBER} to Code Review"
    fi
    ;;

  merged)
    if [ "$CURRENT_STATUS" != "Closed" ]; then
      sf data update record \
        --sobject ADM_Work__c \
        --record-id "$WORK_ITEM_ID" \
        --values "Status__c='Fixed'" \
        --target-org "$DEFAULT_ORG"
      echo "Marked W-${WI_NUMBER} as Fixed"
    fi
    ;;
esac
```

---

## Quick Reference

### WI Number Extraction

```bash
# Extract 8-digit WI number
WI_NUMBER=$(git rev-parse --abbrev-ref HEAD | grep -oE '[0-9]{8}' | head -1)

# Validate extracted
[ -z "$WI_NUMBER" ] && echo "No WI found" && exit 1

# Get default org
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Query by Name field
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org "$DEFAULT_ORG" --json | jq -r '.result.records[0].Id')
```

### Common Git Hooks

```
pre-commit       - Validate WI exists
post-commit      - Post to Chatter
pre-push         - Check WI status
post-merge       - Update status to Fixed
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Include WI number in branch names
✅ DO: Validate WI exists before operations
✅ DO: Use error handling in automation
✅ DO: Post meaningful updates to Chatter
✅ DO: Test automation in sandbox first
✅ DO: Add fallbacks for missing WI numbers
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Assume branch always has WI number
❌ DON'T: Skip validation of query results
❌ DON'T: Hardcode org or user information
❌ DON'T: Spam Chatter with every commit
❌ DON'T: Auto-close WIs without verification
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Validate all git inputs (branch names, commit messages)
- ⚠️ Don't expose tokens in git hooks
- ⚠️ Test automation thoroughly before production use
- ⚠️ Use appropriate error handling to avoid data corruption

---

## Related Skills

- `sf-org-auth.md` - Authentication for automation
- `sf-soql-queries.md` - Query WI details
- `sf-work-items.md` - Work with GUS objects
- `sf-chatter.md` - Post automated updates

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
