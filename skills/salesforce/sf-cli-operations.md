---
name: salesforce-sf-cli-operations
description: Using Salesforce CLI (sf) for managing orgs, data, and records
---

# Salesforce CLI Operations

**Scope**: Comprehensive guide to using the Salesforce CLI (sf) for common operations
**Lines**: ~400
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Creating or updating Salesforce records (Work Items/WI, User Stories, Bugs, Epics, Sprints)
- Querying Salesforce data using SOQL
- Managing Salesforce org authentication and connections
- Performing bulk data operations on Salesforce objects
- Interacting with Agile Accelerator (GUS) objects
- Creating Chatter posts or comments
- Updating record statuses or fields
- Executing REST API calls against Salesforce
- Working with WI (Work Items) in any context

**Important Notes**:
- **Always use `sf` CLI tool directly** for all Salesforce operations
- **WI Number Inference**: If no WI number is explicitly mentioned, check the current git branch name for WI patterns (e.g., `W-12345678`, `wi-12345678`, `12345678-feature-name`)
- **Default Org**: This skill uses `gus` as the default org alias for examples. If your org has a different alias, replace `--target-org gus` with your org alias (e.g., `--target-org my-gus`, `--target-org production-gus`, etc.)

## Core Concepts

### Concept 1: Org Authentication

**Authentication Methods**:
- Web login flow: `sf org login web`
- JWT bearer flow: `sf org login jwt`
- Access token: `sf org login access-token`
- SFDX auth URL: `sf org login sfdx-url`

**Note**: This skill uses `gus` as the default org alias throughout. Replace with your org alias if different.

```bash
# Login to org via web browser (use 'gus' as alias for consistency)
sf org login web --alias gus

# Or use your own alias
sf org login web --alias my-gus

# List all authenticated orgs
sf org list

# Display details about the gus org
sf org display --target-org gus

# Open gus org in browser
sf org open --target-org gus
```

### Concept 2: SOQL Queries

**Query Execution**:
- Query using `sf data query`
- Support for CSV, JSON, and human-readable output
- Can query standard and custom objects
- Tooling API access for metadata queries

```bash
# Query Work Items (Agile Accelerator)
sf data query \
  --query "SELECT Id, Name, Status__c, Subject__c FROM ADM_Work__c WHERE Status__c = 'New' LIMIT 10" \
  --target-org my-org \
  --result-format json

# Query from file
sf data query \
  --file query.soql \
  --output-file results.csv \
  --result-format csv \
  --target-org my-org

# Query using Tooling API
sf data query \
  --query "SELECT Name, ApiVersion FROM ApexClass" \
  --use-tooling-api \
  --target-org my-org
```

### Concept 3: Record Creation and Updates

**Creating Records**:
- Use `sf data create record` for single records
- Specify object type with `--sobject`
- Provide field values with `--values`
- Use bulk operations for multiple records

```bash
# Create a Work Item (User Story)
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement new feature' Status__c='New' Priority__c='P2' Assignee__c='005xx000001X8Uz'" \
  --target-org my-org

# Create an Epic
sf data create record \
  --sobject ADM_Epic__c \
  --values "Name='Q1 2024 Features' Status__c='New' Description__c='Major features for Q1'" \
  --target-org my-org

# Update a record by ID
sf data update record \
  --sobject ADM_Work__c \
  --record-id a07xx00000ABCDe \
  --values "Status__c='In Progress' Assignee__c='005xx000001X8Uz'" \
  --target-org my-org

# Update a record by field match
sf data update record \
  --sobject ADM_Work__c \
  --where "Subject__c='Old Feature Name'" \
  --values "Subject__c='New Feature Name' Priority__c='P1'" \
  --target-org my-org
```

---

## Patterns

### Pattern 1: Creating User Stories with Dependencies

**When to use**:
- Creating work items in Agile Accelerator
- Setting up sprints and assignments
- Linking related work items

```bash
# ❌ Bad: Creating story without proper fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Feature'" \
  --target-org my-org

# ✅ Good: Complete story with all required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Implement user authentication' \
           Status__c='New' \
           Priority__c='P1' \
           Story_Points__c=5 \
           Epic__c='a0Axx000001ABCD' \
           Sprint__c='a1Fxx000002EFGH' \
           Assignee__c='005xx000001X8Uz' \
           Type__c='User Story' \
           Description__c='<p>As a user, I want to log in securely</p>'" \
  --target-org my-org
```

**Benefits**:
- Complete work item with proper tracking
- Links to Epic and Sprint for planning
- Includes story points for velocity tracking

### Pattern 2: Bulk Status Updates

**Use case**: Update multiple work items to a new status

```bash
# Query work items to update
sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Sprint__c = 'a1Fxx000002EFGH' AND Status__c = 'Ready for Development'" \
  --result-format json \
  --target-org my-org > work_items.json

# Create CSV for bulk update
# work_items.csv:
# Id,Status__c
# a07xx00000ABCD1,In Progress
# a07xx00000ABCD2,In Progress
# a07xx00000ABCD3,In Progress

# Bulk update using CSV
sf data update bulk \
  --sobject ADM_Work__c \
  --file work_items.csv \
  --wait 10 \
  --target-org my-org
```

### Pattern 3: Creating Chatter Posts

**Use case**: Post updates to Chatter feeds for work items

```bash
# Create a Chatter post on a Work Item (example with real output format)
sf data create record \
  --sobject FeedItem \
  --values "ParentId=a07xx00000ABCDE Body='Phase 1.2 complete: S3 Storage Service implemented with 32 tests, file size validation, and CI configuration.'" \
  --target-org gus

# Output:
# Successfully created record: 0D5xx00000FGHIJ.
# Creating record for FeedItem... done

# Create a Chatter post with simple update
sf data create record \
  --sobject FeedItem \
  --values "ParentId='a07xx00000ABCDE' Body='Work has been completed and is ready for review'" \
  --target-org gus

# Create a Chatter comment on an existing post
sf data create record \
  --sobject FeedComment \
  --values "FeedItemId='0D5xx00000FGHIJ' CommentBody='LGTM - approved for merge'" \
  --target-org gus

# Query Chatter feed for a record
sf data query \
  --query "SELECT Id, Body, CreatedBy.Name, CreatedDate FROM FeedItem WHERE ParentId = 'a07xx00000ABCDE' ORDER BY CreatedDate DESC LIMIT 20" \
  --target-org gus \
  --json

# Post to Chatter using WI from git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org gus \
  --json | jq -r '.result.records[0].Id')

sf data create record \
  --sobject FeedItem \
  --values "ParentId=${WORK_ITEM_ID} Body='Feature implementation completed and ready for review'" \
  --target-org gus
```

**Key Points**:
- `ParentId` is the Salesforce record Id (e.g., `a07xx00000ABCDE` for Work Items)
- `Body` contains the Chatter post text (plain text or basic formatting)
- You don't need `Type='TextPost'` - it's the default for FeedItem
- Returns the FeedItem Id (e.g., `0D5xx00000FGHIJ`) on success
- For comments, use `FeedComment` object with `FeedItemId` and `CommentBody`

### Pattern 4: Managing Sprints and Builds

**Use case**: Create and manage sprint/build records

```bash
# Create a new Sprint
sf data create record \
  --sobject ADM_Sprint__c \
  --values "Name='Sprint 42' Start_Date__c=2024-01-15 End_Date__c=2024-01-29 Status__c='Planned'" \
  --target-org my-org

# Create a Build (Scheduled Build)
sf data create record \
  --sobject ADM_Build__c \
  --values "Name='Release 1.0' Scheduled_Date__c=2024-02-01 Status__c='Scheduled'" \
  --target-org my-org

# Assign work items to sprint
sf data update record \
  --sobject ADM_Work__c \
  --where "Status__c='Ready for Development' AND Sprint__c = null" \
  --values "Sprint__c='a1Fxx000002EFGH'" \
  --target-org my-org
```

### Pattern 5: REST API Direct Calls

**Use case**: Make custom REST API calls for operations not covered by standard commands

```bash
# Get Work Item details via REST API
sf api request rest \
  "/services/data/v56.0/sobjects/ADM_Work__c/a07xx00000ABCDE" \
  --target-org my-org

# Update multiple fields via PATCH
sf api request rest \
  "/services/data/v56.0/sobjects/ADM_Work__c/a07xx00000ABCDE" \
  --method PATCH \
  --body '{"Status__c": "Fixed", "Resolved_On__c": "2024-01-15"}' \
  --target-org my-org

# Query using REST API
sf api request rest \
  "/services/data/v56.0/query?q=SELECT+Id,Name+FROM+ADM_Work__c+LIMIT+10" \
  --target-org my-org
```

### Pattern 6: Finding Record IDs

**Use case**: Locate record IDs for references (Users, Epics, Sprints, Product Tags)

```bash
# Find user ID by name
sf data query \
  --query "SELECT Id, Name, Email FROM User WHERE Name LIKE '%John Doe%'" \
  --target-org my-org

# Find Epic by name
sf data query \
  --query "SELECT Id, Name FROM ADM_Epic__c WHERE Name LIKE '%Authentication%'" \
  --target-org my-org

# Find Sprint by name
sf data query \
  --query "SELECT Id, Name, Start_Date__c, End_Date__c FROM ADM_Sprint__c WHERE Name = 'Sprint 42'" \
  --target-org my-org

# Find Product Tag
sf data query \
  --query "SELECT Id, Name FROM ADM_Product_Tag__c WHERE Name LIKE '%Platform%'" \
  --target-org my-org
```

### Pattern 7: Bulk Data Export

**Use case**: Export large datasets for analysis or backup

```bash
# Export all work items for a sprint
sf data export bulk \
  --sobject ADM_Work__c \
  --query "SELECT Id, Subject__c, Status__c, Priority__c, Assignee__r.Name, Story_Points__c FROM ADM_Work__c WHERE Sprint__c = 'a1Fxx000002EFGH'" \
  --output-file sprint_42_items.csv \
  --wait 10 \
  --target-org my-org

# Export all open bugs
sf data export bulk \
  --sobject ADM_Work__c \
  --query "SELECT Id, Subject__c, Status__c, Priority__c, Found_in_Build__r.Name FROM ADM_Work__c WHERE Type__c = 'Bug' AND Status__c NOT IN ('Fixed', 'Not a Bug')" \
  --output-file open_bugs.csv \
  --target-org my-org
```

### Pattern 8: Complex Field Updates with HTML

**Use case**: Update rich text fields with HTML content

```bash
# Update work item description with HTML
sf data update record \
  --sobject ADM_Work__c \
  --record-id a07xx00000ABCDE \
  --values "Description__c='<p><strong>Overview</strong></p><ul><li>Item 1</li><li>Item 2</li></ul><p>Additional details here.</p>'" \
  --target-org my-org

# Create work item with formatted description
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='Database migration' \
           Description__c='<p><strong>Steps:</strong></p><ol><li>Backup current data</li><li>Run migration script</li><li>Verify integrity</li></ol>' \
           Status__c='New' \
           Type__c='User Story'" \
  --target-org my-org
```

### Pattern 9: Inferring WI Number from Git Branch

**Use case**: Automatically determine WI number from current git branch name

**IMPORTANT**: The WI number (e.g., W-12345678) is stored in the `Name` field, NOT the `Id` field. You must query by `Name` to get the actual Salesforce record `Id`.

```bash
# ❌ Bad: Asking user for WI number when it's in the branch
echo "What's the WI number?"

# ✅ Good: Extract WI number from git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

# Common branch patterns that contain WI numbers:
# - W-12345678
# - wi-12345678
# - 12345678-feature-name
# - feature/W-12345678
# - bugfix/12345678-fix-issue

# Query work item by Name field (NOT Id) to get the record details
# The Name field contains 'W-12345678', the Id field contains Salesforce record ID
sf data query \
  --query "SELECT Id, Name, Subject__c, Status__c FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org gus \
  --json

# Get the Salesforce record Id from the WI Name
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
  --target-org gus \
  --json | jq -r '.result.records[0].Id')

# ❌ WRONG: Using WI number as if it were the Salesforce Id
sf data update record \
  --sobject ADM_Work__c \
  --record-id "W-${WI_NUMBER}" \
  --values "Status__c='In Progress'"  # This will fail!

# ✅ CORRECT: Use the actual Salesforce record Id from the query
sf data update record \
  --sobject ADM_Work__c \
  --record-id "$WORK_ITEM_ID" \
  --values "Status__c='In Progress'" \
  --target-org gus

# Add Chatter post to the WI using the Salesforce record Id
sf data create record \
  --sobject FeedItem \
  --values "ParentId='${WORK_ITEM_ID}' Body='Starting work on this feature' Type='TextPost'" \
  --target-org gus
```

**Benefits**:
- No need to manually specify WI numbers when working in feature branches
- Reduces errors from copying/pasting wrong WI numbers
- Enables automation based on git workflow
- Makes scripts more context-aware

**Key Points**:
- WI number (W-12345678) is in the `Name` field, NOT the `Id` field
- Always query `WHERE Name = 'W-...'` to find work items
- Extract the `Id` field from query results for record operations
- Use `--json` flag for easier parsing with `jq`

---

## Quick Reference

### Common Objects

```
Object API Name        | Description              | Key Fields
-----------------------|--------------------------|----------------------------------
ADM_Work__c            | Work Items/Stories/Bugs  | Subject__c, Status__c, Priority__c, Assignee__c
ADM_Epic__c            | Epics                    | Name, Status__c, Description__c
ADM_Sprint__c          | Sprints                  | Name, Start_Date__c, End_Date__c, Status__c
ADM_Build__c           | Scheduled Builds         | Name, Scheduled_Date__c, Status__c
ADM_Product_Tag__c     | Product Tags             | Name
FeedItem               | Chatter Posts            | ParentId, Body, Type
FeedComment            | Chatter Comments         | FeedItemId, CommentBody
User                   | Users                    | Name, Email, Username
```

### Common Status Values

```
Object      | Status Field   | Common Values
------------|----------------|----------------------------------------------
Work Items  | Status__c      | New, In Progress, Code Review, Fixed, Closed
Epics       | Status__c      | New, In Progress, Completed
Sprints     | Status__c      | Planned, Active, Completed
Builds      | Status__c      | Scheduled, In Progress, Released
```

### Key Guidelines

```
✅ DO: Always specify --target-org to avoid ambiguity
✅ DO: Use --result-format json for programmatic processing
✅ DO: Query for IDs before creating related records
✅ DO: Use bulk operations for updating multiple records
✅ DO: Include required fields when creating records
✅ DO: Use HTML formatting for rich text fields
✅ DO: Always use sf CLI tool directly for all operations
✅ DO: Infer WI number from git branch name when not explicitly provided

❌ DON'T: Hardcode record IDs (query for them instead)
❌ DON'T: Create records without required fields
❌ DON'T: Use single updates for large datasets (use bulk)
❌ DON'T: Forget to specify API names (use __c suffix for custom fields)
❌ DON'T: Update records without verifying they exist first
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Update records without verifying they exist
sf data update record \
  --sobject ADM_Work__c \
  --record-id UNKNOWN_ID \
  --values "Status__c='Fixed'"

# ✅ CORRECT: Query first, then update
RECORD_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Subject__c='Known Subject'" \
  --result-format json --target-org my-org | jq -r '.result.records[0].Id')

sf data update record \
  --sobject ADM_Work__c \
  --record-id "$RECORD_ID" \
  --values "Status__c='Fixed'" \
  --target-org my-org
```

❌ **Hardcoding IDs**: IDs vary across orgs (sandbox vs production)
✅ **Correct approach**: Query by unique identifiers (names, external IDs)

### Common Mistakes

```bash
# ❌ Don't: Missing required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='New Story'" \
  --target-org my-org

# ✅ Correct: Include all required fields
sf data create record \
  --sobject ADM_Work__c \
  --values "Subject__c='New Story' Status__c='New' Type__c='User Story' Priority__c='P2'" \
  --target-org my-org
```

❌ **Incomplete records**: Missing required fields causes failures
✅ **Better**: Query existing records to understand required fields

```bash
# ❌ Don't: Single updates in loop
for id in $(cat work_item_ids.txt); do
  sf data update record --sobject ADM_Work__c --record-id "$id" --values "Status__c='Closed'"
done

# ✅ Correct: Use bulk update
sf data update bulk \
  --sobject ADM_Work__c \
  --file updates.csv \
  --wait 10 \
  --target-org my-org
```

❌ **Inefficient operations**: Single updates are slow and hit API limits
✅ **Better**: Bulk API for batch operations

---

## Security Considerations

**Review before creating this skill**: Check `.claude/audits/safety-checklist.md`

**Does this skill involve** (check all that apply):
- [x] Authentication or authorization
- [ ] Cryptographic operations
- [x] Data deletion or modification
- [ ] Production deployments
- [ ] Database migrations
- [ ] File system operations
- [x] Network requests
- [ ] Executable scripts

**If yes to any above, ensure**:
- [x] Sensitive operations have clear ⚠️ warnings
- [x] Examples use placeholder credentials (never real)
- [x] Destructive operations include rollback procedures
- [x] Production examples follow security best practices
- [x] Scripts validate all inputs
- [x] No hardcoded secrets or API keys
- [x] Dangerous commands clearly marked

**Security Notes**:
- ⚠️ Always verify target org before destructive operations
- ⚠️ Use `--target-org` flag to prevent accidental production updates
- ⚠️ Query before update to verify record existence
- ⚠️ Be cautious with bulk delete operations
- ⚠️ Never commit authentication tokens or credentials

---

## Related Skills

- `salesforce/agile-accelerator-workflows.md` - GUS-specific workflows and automation
- `collaboration/github/github-issues-projects.md` - Alternative project management
- `data/data-transformation.md` - Processing exported Salesforce data
- `testing/integration-testing.md` - Testing Salesforce integrations
- `api/rest-api-design.md` - Understanding Salesforce REST API patterns
- `workflow/automation-scripting.md` - Automating Salesforce operations

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
