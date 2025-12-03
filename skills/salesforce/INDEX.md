# Salesforce Skills

Comprehensive skills for working with Salesforce CLI (sf) and Agile Accelerator (GUS).

## Category Overview

**Total Skills**: 1
**Focus**: Salesforce CLI, Agile Accelerator (GUS), SOQL, Record Management, Chatter
**Use Cases**: Creating work items, managing sprints, querying data, bulk operations, API integration
**Default Org**: Examples use `gus` as the org alias - replace with your org alias if different

## Skills in This Category

### sf-cli-operations.md
**Description**: Using Salesforce CLI (sf) for managing orgs, data, and records
**Lines**: ~400
**Use When**:
- Creating or updating Salesforce records (Work Items/WI, User Stories, Bugs, Epics, Sprints)
- Querying Salesforce data using SOQL
- Managing Salesforce org authentication and connections
- Performing bulk data operations on Salesforce objects
- Interacting with Agile Accelerator (GUS) objects
- Creating Chatter posts or comments
- Updating record statuses or fields
- Executing REST API calls against Salesforce
- Working with WI (Work Items) in any context

**Key Concepts**: sf CLI, SOQL queries, record creation/updates, bulk operations, Agile Accelerator objects, Chatter integration, REST API

---

## Common Workflows

### Create User Story
**Goal**: Create a new user story in Agile Accelerator

**Sequence**:
1. `sf-cli-operations.md` - Query for Epic, Sprint, and User IDs
2. `sf-cli-operations.md` - Create work item with proper fields
3. `sf-cli-operations.md` - Add Chatter post for updates

**Example**: Creating a feature story linked to current sprint

---

### Sprint Planning
**Goal**: Set up and populate a new sprint

**Sequence**:
1. `sf-cli-operations.md` - Create sprint record
2. `sf-cli-operations.md` - Query backlog items
3. `sf-cli-operations.md` - Bulk assign items to sprint
4. `sf-cli-operations.md` - Update story points and priorities

**Example**: Planning two-week sprint with 20 stories

---

### Bulk Status Update
**Goal**: Update status for multiple work items

**Sequence**:
1. `sf-cli-operations.md` - Query work items by criteria
2. `sf-cli-operations.md` - Export to CSV
3. `sf-cli-operations.md` - Bulk update using CSV
4. `sf-cli-operations.md` - Verify updates with query

**Example**: Moving all sprint items from "Ready" to "In Progress"

---

### Work Item Reporting
**Goal**: Export work items for analysis

**Sequence**:
1. `sf-cli-operations.md` - Query work items with related data
2. `sf-cli-operations.md` - Export to CSV using bulk API
3. Process data for reporting (Excel, BI tools)

**Example**: Sprint burndown report or velocity tracking

---

## Skill Combinations

### With API Skills (`discover-api`)
- REST API calls to Salesforce
- Custom API integrations
- Webhook handling for Salesforce events
- Authentication using OAuth

**Common combos**:
- `sf-cli-operations.md` + `api/rest-api-design.md`
- `sf-cli-operations.md` + `api/api-authentication.md`

---

### With Workflow Skills (`discover-workflow`)
- Automated work item creation
- Status update automation
- Integration with CI/CD pipelines
- Scheduled bulk operations

**Common combos**:
- `sf-cli-operations.md` + `workflow/automation-scripting.md`
- `sf-cli-operations.md` + `cicd/ci-optimization.md`

---

### With Data Skills (`discover-data`)
- ETL operations with Salesforce data
- Data transformation and analysis
- Export/import workflows
- Data quality checks

**Common combos**:
- `sf-cli-operations.md` + `data/data-transformation.md`
- `sf-cli-operations.md` + `data/data-validation.md`

---

### With Collaboration Skills (`discover-collaboration`)
- Syncing GitHub issues with GUS
- Automated Chatter updates
- Cross-platform project management
- Integration dashboards

**Common combos**:
- `sf-cli-operations.md` + `collaboration/github/github-issues-projects.md`
- `sf-cli-operations.md` + `collaboration/github/github-actions-workflows.md`

---

## Quick Selection Guide

**Use sf CLI when**:
- Managing Agile Accelerator (GUS) work items
- Performing bulk operations on Salesforce data
- Automating Salesforce workflows
- Integrating Salesforce with other tools
- Querying data for reports and dashboards

**Common Objects**:
- `ADM_Work__c` - Work Items (Stories, Bugs, Tasks)
- `ADM_Epic__c` - Epics
- `ADM_Sprint__c` - Sprints
- `ADM_Build__c` - Scheduled Builds
- `ADM_Product_Tag__c` - Product Tags
- `FeedItem` - Chatter Posts
- `FeedComment` - Chatter Comments

**Authentication**:
- Use `sf org login web --alias gus` for interactive login (or your preferred alias)
- Use `--target-org gus` flag to specify org (replace `gus` with your org alias if different)
- List orgs with `sf org list`
- Open org in browser with `sf org open --target-org gus`

**Best Practices**:
- Always query for IDs before creating related records
- Use bulk operations for multiple record updates
- Include all required fields when creating records
- Verify target org before destructive operations
- Use HTML formatting for rich text fields
- Export data before bulk deletes
- **Always use `sf` CLI directly** - Do NOT use `minigus` or wrapper tools
- Infer WI number from git branch name when not explicitly provided

---

## Loading Skills

All skills are available in the `skills/salesforce/` directory:

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

**Pro tip**: Start by authenticating to your org, then query for necessary record IDs before creating or updating records.

---

**Related Categories**:
- `discover-api` - REST API patterns and authentication
- `discover-workflow` - Automation and scripting
- `discover-data` - Data transformation and ETL
- `discover-collaboration` - GitHub and project management
- `discover-testing` - Integration testing strategies
