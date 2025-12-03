---
name: salesforce-work-items
description: Manage Agile Accelerator (GUS) work items, sprints, and epics. Use for creating stories, bugs, tasks, managing sprints, epics, teams, and builds.
keywords: gus, agile accelerator, work items, story, bug, task, sprint, epic, team, scrum, build, ADM_Work__c, ADM_Epic__c, ADM_Sprint__c, ADM_Scrum_Team__c, salesforce
---

# Salesforce Agile Accelerator Work Items

**Scope**: Creating and managing work items, sprints, epics, and builds in GUS
**Lines**: ~402
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Creating user stories, bugs, or tasks in GUS
- Managing sprints and sprint planning
- Working with epics and product tags
- Managing scheduled builds
- Organizing work item hierarchies
- Sprint planning and backlog management

---

## Core Concepts

### Concept 1: Work Item Types

**ADM_Work__c Object** - Main work tracking object

**Common Types**:
- `User Story` - Feature development
- `Bug` - Defects and issues
- `Task` - General work items
- `Investigation` - Research tasks

**Key Fields**:
```
Name               - WI number (e.g., W-12345678)
Subject__c         - Title/summary (required)
Status__c          - Workflow state (required)
Type__c            - Work item type (required)
Priority__c        - P0, P1, P2, P3, P4
Story_Points__c    - Estimation
Assignee__c        - User ID
Sprint__c          - Sprint ID
Epic__c            - Epic ID
Description__c     - HTML rich text
```

### Concept 2: Sprints and Epics

**ADM_Sprint__c** - Sprint/iteration tracking
**ADM_Epic__c** - Epic grouping
**ADM_Build__c** - Scheduled builds/releases
**ADM_Product_Tag__c** - Product categorization

---

## Patterns

### Pattern 1: Creating User Stories with Dependencies

**Use case**: Create complete user story with proper relationships

```bash
# Step 1: Get default org and query for required IDs
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
USER_ID=$(sf data query \
  --query "SELECT Id FROM User WHERE Email = '${USER_EMAIL}'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

SPRINT_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Sprint__c WHERE Name = 'Sprint 42'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

EPIC_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

# Step 2: Create user story with all required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement user authentication' \
           Status__c='New' \
           Priority__c='P1' \
           Story_Points__c=5 \
           Epic__c='${EPIC_ID}' \
           Sprint__c='${SPRINT_ID}' \
           Assignee__c='${USER_ID}' \
           Type__c='User Story' \
           Description__c='<p>As a user, I want to log in securely</p>'" \
  --target-org "$DEFAULT_ORG"
```

**Benefits**:
- Complete work item with proper tracking
- Links to Epic and Sprint for planning
- Includes story points for velocity tracking

### Pattern 2: Sprint Planning

**Use case**: Create sprint and assign work items

```bash
# Create a new Sprint
SPRINT_RESULT=$(sf data create record \
  --sobject ADM_Sprint__c \
  --values "Name='Sprint 42' Start_Date__c=2024-01-15 End_Date__c=2024-01-29" \
  --target-org "$DEFAULT_ORG" \
  --json)

SPRINT_ID=$(echo "$SPRINT_RESULT" | jq -r '.result.id')

echo "Created Sprint 42 with ID: $SPRINT_ID"

# Query backlog items
sf data query \
  --query "SELECT Id, Name, Subject__c, Story_Points__c
    FROM ADM_Work__c
    WHERE Status__c = 'Ready for Development'
    AND Sprint__c = null
    ORDER BY Priority__c, Story_Points__c" \
  --target-org "$DEFAULT_ORG" \
  --result-format json > backlog.json

# Review items and manually create CSV for assignment
# backlog_assignment.csv:
# Id,Sprint__c
# a07xx00000ABCD1,<SPRINT_ID>
# a07xx00000ABCD2,<SPRINT_ID>

# Bulk assign items to sprint (see sf-bulk-operations.md)
```

### Pattern 3: Managing Epics

**Use case**: Create and organize epics

```bash
# Create an Epic
sf data create record \
  --sobject ADM_Epic__c \
  --values "Name='Q1 2024 Authentication Features' \
           Priority__c='P1' \
           Health__c='On Track' \
           Description__c='<p>Complete authentication overhaul</p>'" \
  --target-org "$DEFAULT_ORG"

# Query work items in epic
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Story_Points__c, Assignee__r.Name
    FROM ADM_Work__c
    WHERE Epic__r.Name LIKE '%Authentication%'
    ORDER BY Status__c, Priority__c" \
  --target-org "$DEFAULT_ORG"

# Update epic health
EPIC_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

sf data update record \
  --sobject ADM_Epic__c \
  --record-id "$EPIC_ID" \
  --values "Health__c='At Risk' Description__c='<p>Blocked on security review</p>'" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 4: Managing Builds

**Use case**: Create and track scheduled builds

```bash
# Create a Build (Scheduled Build)
sf data create record \
  --sobject ADM_Build__c \
  --values "Name='Release 1.0' External_ID__c='R010' Target_Date__c=2024-02-01" \
  --target-org "$DEFAULT_ORG"

# Link work items to build
BUILD_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Build__c WHERE Name = 'Release 1.0'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

sf data update record \
  --sobject ADM_Work__c \
  --where "Status__c='Fixed' AND Scheduled_Build__c = null" \
  --values "Scheduled_Build__c='${BUILD_ID}'" \
  --target-org "$DEFAULT_ORG"

# Query work items in build
sf data query \
  --query "SELECT Name, Subject__c, Status__c, Priority__c
    FROM ADM_Work__c
    WHERE Scheduled_Build__r.Name = 'Release 1.0'
    ORDER BY Priority__c" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 5: Work Item Status Workflows

**Use case**: Move work items through standard workflow states

```bash
# Common status transitions for User Stories
# New → In Progress → Code Review → QA Review → Fixed → Closed

# Start work
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org "$DEFAULT_ORG" | jq -r '.result.records[0].Id')

sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='In Progress'" \
  --target-org "$DEFAULT_ORG"

# Move to code review
sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='Code Review'" \
  --target-org "$DEFAULT_ORG"

# Mark as fixed
sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='Fixed' Resolved_On__c=$(date +%Y-%m-%d)" \
  --target-org "$DEFAULT_ORG"
```

### Pattern 6: Sprint Reporting

**Use case**: Get sprint metrics and burndown data

```bash
# Get sprint summary
sf data query \
  --query "SELECT
    Status__c,
    COUNT(Id) total_items,
    SUM(Story_Points__c) total_points
    FROM ADM_Work__c
    WHERE Sprint__r.Name = 'Sprint 42'
    GROUP BY Status__c" \
  --target-org "$DEFAULT_ORG"

# Get team velocity
sf data query \
  --query "SELECT
    Sprint__r.Name,
    SUM(Story_Points__c) completed_points
    FROM ADM_Work__c
    WHERE Sprint__r.Start_Date__c >= 2024-01-01
    AND Status__c IN ('Fixed', 'Closed')
    GROUP BY Sprint__r.Name
    ORDER BY Sprint__r.Name" \
  --target-org "$DEFAULT_ORG"

# Get individual workload
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')

sf data query \
  --query "SELECT Name, Subject__c, Status__c, Story_Points__c, Sprint__r.Name
    FROM ADM_Work__c
    WHERE Assignee__r.Email = '${USER_EMAIL}'
    AND Status__c NOT IN ('Fixed', 'Closed')
    ORDER BY Priority__c, Sprint__r.Name" \
  --target-org "$DEFAULT_ORG"
```

---

## Quick Reference

### Common Objects and Fields

**Work Items (ADM_Work__c)**:
```
Status Values: New, In Progress, Code Review, QA Review, Fixed, Closed
Priority: P0, P1, P2, P3, P4
Type: User Story, Bug, Task, Investigation
```

**Epics (ADM_Epic__c)**:
```
Health: On Track, At Risk, Off Track, Completed, Canceled
Priority: P0, P1, P2, P3 (optional)
Note: Epics do NOT have a Status__c field - use Health__c instead
```

**Sprints (ADM_Sprint__c)**:
```
Key Fields: Name, Start_Date__c, End_Date__c
No status field - use dates
```

**Builds (ADM_Build__c)**:
```
Key Fields: Name, External_ID__c, Target_Date__c
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Include all required fields when creating work items
✅ DO: Link work items to sprints and epics
✅ DO: Use story points for estimation
✅ DO: Query for IDs before creating relationships
✅ DO: Use descriptive subjects for work items
✅ DO: Update status as work progresses
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Create work items without type or status
❌ DON'T: Hardcode sprint or epic IDs
❌ DON'T: Forget to assign work items
❌ DON'T: Skip story points on user stories
❌ DON'T: Leave work items in stale states
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Create incomplete work items
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Feature'" \
  --target-org "$DEFAULT_ORG"

# ✅ CORRECT: Include all required and recommended fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement feature X' \
           Status__c='New' \
           Type__c='User Story' \
           Priority__c='P2' \
           Story_Points__c=3" \
  --target-org "$DEFAULT_ORG"
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Verify user has permission to create/update work items
- ⚠️ Don't expose sensitive information in subject or description
- ⚠️ Validate sprint and epic IDs before assignment
- ⚠️ Be careful when bulk updating work item statuses

---

## Related Skills

- `sf-org-auth.md` - Get current user for assignments
- `sf-soql-queries.md` - Query work items and related objects
- `sf-record-operations.md` - Create and update individual records
- `sf-bulk-operations.md` - Bulk status updates
- `sf-chatter.md` - Add updates to work items
- `sf-automation.md` - Automate with git integration

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
