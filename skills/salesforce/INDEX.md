# Salesforce Skills

Comprehensive skills for working with Salesforce CLI (sf) and Agile Accelerator (GUS).

## Category Overview

**Total Skills**: 10
**Focus**: Salesforce CLI, Agile Accelerator (GUS), SOQL, Record Management, Chatter
**Use Cases**: Creating work items, managing sprints, querying data, bulk operations, API integration, automation
**Default Org**: Examples dynamically detect your default org using `sf config get target-org` - set it with `sf config set target-org=<your-alias>`

## Skills in This Category

### sf-org-auth.md
**Description**: Authenticate and manage Salesforce orgs using sf CLI
**Lines**: ~180
**Use When**:
- Logging into Salesforce orgs
- Managing multiple org connections
- Retrieving current user information
- Getting org details and configuration
- Troubleshooting authentication issues

**Key Concepts**: Web/JWT login, org management, user information, multi-org workflows

---

### sf-soql-queries.md (NAVIGATION FILE)
**Description**: Navigation guide to SOQL query skills (basics, advanced, troubleshooting)
**Lines**: ~230
**Use When**:
- Deciding which SOQL skill file to use
- Understanding the SOQL skill organization
- Quick reference for field names and critical rules

**Key Concepts**: Skill navigation, quick start guides, common workflows

**⚠️ NOTE**: This is a navigation file. Use the specialized skill files below for actual queries:
- `sf-soql-basics.md` - Core concepts and basic queries
- `sf-soql-advanced.md` - Complex queries and aggregation
- `sf-soql-troubleshooting.md` - Error handling and anti-patterns

---

### sf-soql-basics.md
**Description**: Basic SOQL queries, field discovery, and fundamental patterns for Salesforce
**Lines**: ~350
**Use When**:
- Starting with SOQL queries (learn basics first)
- Querying simple data (users, work items by ID, basic lookups)
- Learning field verification (mandatory describe workflow)
- Looking up team memberships
- Finding record IDs

**Key Concepts**: MANDATORY field discovery, basic SOQL syntax, relationship names, verified field names, output formats

---

### sf-soql-advanced.md
**Description**: Advanced SOQL queries for GUS - work items, aggregation, date filters, and tooling API
**Lines**: ~350
**Use When**:
- Querying work items by various criteria (assignee, sprint, epic, status)
- Aggregating data (counts, sums, grouped results)
- Filtering by dates (date ranges, relative dates)
- Querying metadata (Apex classes, triggers using Tooling API)
- Complex multi-condition queries

**Key Concepts**: Work item queries, aggregation (COUNT, SUM), date filters, tooling API

---

### sf-soql-troubleshooting.md
**Description**: Common SOQL errors, anti-patterns, and troubleshooting for Salesforce queries
**Lines**: ~450
**Use When**:
- Debugging SOQL query errors (INVALID_FIELD, relationship errors, operator errors)
- Understanding common mistakes (why queries fail and how to fix them)
- Learning anti-patterns (what NOT to do in SOQL queries)
- Troubleshooting field verification (field doesn't exist errors)
- Fixing relationship queries (wrong relationship name errors)

**Key Concepts**: Critical violations, common field errors, query performance, troubleshooting workflow

---

### sf-record-operations.md
**Description**: Create and update Salesforce records using sf CLI
**Lines**: ~200
**Use When**:
- Creating new Salesforce records
- Updating existing records
- Working with individual records (not bulk)
- Setting field values on records
- Using REST API for custom operations

**Key Concepts**: Creating records, updating by ID/field match, REST API, validation

---

### sf-work-items.md
**Description**: Manage Agile Accelerator (GUS) work items, sprints, and epics
**Lines**: ~220
**Use When**:
- Creating user stories, bugs, or tasks in GUS
- Managing sprints and sprint planning
- Working with epics and product tags
- Managing scheduled builds
- Sprint planning and backlog management

**Key Concepts**: Work item types, sprints, epics, builds, status workflows, sprint reporting

---

### sf-chatter.md
**Description**: Create and manage Chatter posts and comments in Salesforce
**Lines**: ~180
**Use When**:
- Posting updates to Chatter feeds
- Adding comments to work items
- Automating Chatter notifications
- Creating progress updates
- Documenting decisions on records

**Key Concepts**: FeedItem, FeedComment, post types, automated updates, querying feeds

---

### sf-bulk-operations.md
**Description**: Perform bulk data operations on Salesforce objects
**Lines**: ~150
**Use When**:
- Updating multiple records at once
- Exporting large datasets
- Bulk status changes
- Mass data migrations
- Avoiding API limit issues

**Key Concepts**: Bulk API, CSV operations, bulk updates/exports, bulk creation

---

### sf-automation.md
**Description**: Automate Salesforce operations with git integration and CI/CD
**Lines**: ~170
**Use When**:
- Integrating Salesforce with git workflows
- Inferring WI numbers from branch names
- Automating Chatter updates from CI/CD
- Building automated workflows
- Creating git hooks for Salesforce operations

**Key Concepts**: WI inference, git integration, CI/CD workflows, automated status transitions

---

## Common Workflows

### Create User Story
**Goal**: Create a new user story in Agile Accelerator

**Sequence**:
1. `sf-org-auth.md` - Get current user info
2. `sf-soql-queries.md` - Query for Epic, Sprint, and User IDs
3. `sf-work-items.md` - Create work item with proper fields
4. `sf-chatter.md` - Add Chatter post for updates

**Example**: Creating a feature story linked to current sprint

---

### Sprint Planning
**Goal**: Set up and populate a new sprint

**Sequence**:
1. `sf-work-items.md` - Create sprint record
2. `sf-soql-queries.md` - Query backlog items
3. `sf-bulk-operations.md` - Bulk assign items to sprint
4. `sf-work-items.md` - Update story points and priorities

**Example**: Planning two-week sprint with 20 stories

---

### Bulk Status Update
**Goal**: Update status for multiple work items

**Sequence**:
1. `sf-soql-queries.md` - Query work items by criteria
2. `sf-bulk-operations.md` - Export to CSV
3. `sf-bulk-operations.md` - Bulk update using CSV
4. `sf-soql-queries.md` - Verify updates with query

**Example**: Moving all sprint items from "Ready" to "In Progress"

---

### Automated Git Workflow
**Goal**: Automate WI updates based on git events

**Sequence**:
1. `sf-automation.md` - Extract WI from branch name
2. `sf-soql-queries.md` - Query work item details
3. `sf-work-items.md` - Update work item status
4. `sf-chatter.md` - Post commit info to Chatter

**Example**: Auto-update WI to "In Progress" on first commit

---

### Work Item Reporting
**Goal**: Export work items for analysis

**Sequence**:
1. `sf-soql-queries.md` - Query work items with related data
2. `sf-bulk-operations.md` - Export to CSV using bulk API
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
- `sf-record-operations.md` + `api/rest-api-design.md`
- `sf-org-auth.md` + `api/api-authentication.md`

---

### With Workflow Skills (`discover-workflow`)
- Automated work item creation
- Status update automation
- Integration with CI/CD pipelines
- Scheduled bulk operations

**Common combos**:
- `sf-automation.md` + `workflow/automation-scripting.md`
- `sf-bulk-operations.md` + `cicd/ci-optimization.md`

---

### With Data Skills (`discover-data`)
- ETL operations with Salesforce data
- Data transformation and analysis
- Export/import workflows
- Data quality checks

**Common combos**:
- `sf-bulk-operations.md` + `data/data-transformation.md`
- `sf-soql-queries.md` + `data/data-validation.md`

---

### With Collaboration Skills (`discover-collaboration`)
- Syncing GitHub issues with GUS
- Automated Chatter updates
- Cross-platform project management
- Integration dashboards

**Common combos**:
- `sf-automation.md` + `collaboration/github/github-issues-projects.md`
- `sf-chatter.md` + `collaboration/github/github-actions-workflows.md`

---

## Quick Selection Guide

**Authentication & Setup**:
- Starting fresh → `sf-org-auth.md`
- Need user info → `sf-org-auth.md`

**Querying Data**:
- New to SOQL → `sf-soql-basics.md`
- Finding records → `sf-soql-basics.md`
- Getting IDs → `sf-soql-basics.md`
- Complex queries → `sf-soql-advanced.md`
- Query errors → `sf-soql-troubleshooting.md`
- Not sure which → `sf-soql-queries.md` (navigation)

**Single Records**:
- Create/update 1-5 records → `sf-record-operations.md`
- Work with custom objects → `sf-record-operations.md`

**GUS Work Items**:
- Create user stories → `sf-work-items.md`
- Sprint planning → `sf-work-items.md`
- Epic management → `sf-work-items.md`

**Communication**:
- Post updates → `sf-chatter.md`
- Automated notifications → `sf-chatter.md`

**Bulk Operations**:
- Update 10+ records → `sf-bulk-operations.md`
- Export large datasets → `sf-bulk-operations.md`

**Automation**:
- Git integration → `sf-automation.md`
- CI/CD workflows → `sf-automation.md`
- WI from branch → `sf-automation.md`

---

## Common Objects

**Work Items (ADM_Work__c)**:
- User Stories, Bugs, Tasks, Investigations
- Key fields: Subject__c, Status__c, Priority__c, Assignee__c

**Epics (ADM_Epic__c)**:
- Feature groupings
- Key fields: Name, Health__c, Priority__c, Description__c
- Note: Uses Health__c (not Status__c)

**Sprints (ADM_Sprint__c)**:
- Iteration tracking
- Key fields: Name, Start_Date__c, End_Date__c

**Builds (ADM_Build__c)**:
- Release tracking
- Key fields: Name, External_ID__c

**Chatter (FeedItem, FeedComment)**:
- Posts and comments
- Key fields: ParentId, Body, CommentBody

**Users (User)**:
- Salesforce users
- Key fields: Name, Email, Id

---

## Best Practices

**Authentication**:
- Use meaningful aliases for orgs (e.g., prod, staging, dev)
- Set a default org with `sf config set target-org=<alias>`
- Dynamically fetch default org and user email/ID instead of hardcoding
- Validate org connection before operations

**Querying**:
- Always use LIMIT to avoid timeouts
- Query for IDs before creating related records
- Use `--result-format json` for scripting
- Validate query results before using extracted values

**Record Operations**:
- Include all required fields when creating records
- Validate record existence before updates
- Use bulk operations for 10+ records

**Work Items**:
- Link work items to sprints and epics
- Use story points for estimation
- Update status as work progresses

**Chatter**:
- Keep posts clear and concise
- Don't post sensitive information
- Validate ParentId before posting

**Bulk Operations**:
- Test with small dataset first
- Backup data before bulk deletes
- Use appropriate LIMIT in export queries

**Automation**:
- Include WI number in branch names
- Validate WI exists before operations
- Test automation in sandbox first
- Add error handling and fallbacks

---

## Loading Skills

All skills are available in the `skills/salesforce/` directory:

```bash
# Load specific skill
cat ~/.claude/skills/salesforce/sf-org-auth.md
cat ~/.claude/skills/salesforce/sf-soql-queries.md          # Navigation file
cat ~/.claude/skills/salesforce/sf-soql-basics.md           # Basic SOQL queries
cat ~/.claude/skills/salesforce/sf-soql-advanced.md         # Advanced SOQL queries
cat ~/.claude/skills/salesforce/sf-soql-troubleshooting.md  # SOQL error handling
cat ~/.claude/skills/salesforce/sf-record-operations.md
cat ~/.claude/skills/salesforce/sf-work-items.md
cat ~/.claude/skills/salesforce/sf-chatter.md
cat ~/.claude/skills/salesforce/sf-bulk-operations.md
cat ~/.claude/skills/salesforce/sf-automation.md
```

**Pro tip**: Start with `sf-org-auth.md` to authenticate, then use `sf-soql-basics.md` to learn queries and find IDs, then create/update records with the appropriate skill.

---

**Related Categories**:
- `discover-api` - REST API patterns and authentication
- `discover-workflow` - Automation and scripting
- `discover-data` - Data transformation and ETL
- `discover-collaboration` - GitHub and project management
- `discover-testing` - Integration testing strategies
- `discover-cicd` - CI/CD pipeline integration
