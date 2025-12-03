---
name: discover-salesforce
description: Automatically discover Salesforce CLI (sf) skills when working with Salesforce orgs, Agile Accelerator (GUS), SOQL queries, work items (WI, wis, wi, WIs), user stories, sprints, epics, or Chatter. Activates for Salesforce integration and automation tasks.
---

# Salesforce Skills Discovery

Provides automatic access to comprehensive Salesforce CLI (sf) operations and Agile Accelerator (GUS) workflows.

## When This Skill Activates

This skill auto-activates when you're working with:
- Salesforce CLI (sf) commands
- Agile Accelerator (GUS) work items (WI), user stories, bugs
- SOQL queries and data operations
- Salesforce orgs and authentication
- Creating or updating Salesforce records
- Sprints, epics, and builds
- Chatter posts and comments
- Bulk data operations
- Salesforce REST API integration
- Any mention of WI (Work Items)

## Available Skills

### Quick Reference

The Salesforce category contains **7 focused skills**:

1. **sf-org-auth** - Authentication, org management, and user information
2. **sf-soql-queries** - SOQL queries and data retrieval
3. **sf-record-operations** - Creating and updating individual records
4. **sf-work-items** - Managing work items, sprints, epics, and builds (GUS)
5. **sf-chatter** - Chatter posts, comments, and feed interactions
6. **sf-bulk-operations** - Bulk updates, exports, and large-scale operations
7. **sf-automation** - Git integration, WI inference, and automated workflows

**Note**: All examples dynamically detect your default org using `sf config get target-org`. You should set your default org with `sf config set target-org=<your-alias>`. Examples in the skills show how to fetch the default org dynamically to avoid hardcoding org aliases.

### Load Full Category Details

For complete descriptions and workflows:

```bash
cat ~/.claude/skills/salesforce/INDEX.md
```

This loads the full Salesforce category index with:
- Detailed skill descriptions
- Usage triggers for each skill
- Common workflow combinations
- Cross-references to related skills

### Load Specific Skills

Load individual skills as needed:

```bash
# Authentication and org management
cat ~/.claude/skills/salesforce/sf-org-auth.md

# SOQL queries and data retrieval
cat ~/.claude/skills/salesforce/sf-soql-queries.md

# Create/update individual records
cat ~/.claude/skills/salesforce/sf-record-operations.md

# Work items, sprints, and epics
cat ~/.claude/skills/salesforce/sf-work-items.md

# Chatter posts and comments
cat ~/.claude/skills/salesforce/sf-chatter.md

# Bulk operations and exports
cat ~/.claude/skills/salesforce/sf-bulk-operations.md

# Git integration and automation
cat ~/.claude/skills/salesforce/sf-automation.md
```

## Common Workflows

### Create User Story
**Sequence**: Get user → Query IDs → Create work item → Add Chatter update

```bash
cat ~/.claude/skills/salesforce/sf-org-auth.md        # Get current user
cat ~/.claude/skills/salesforce/sf-soql-queries.md    # Query for IDs
cat ~/.claude/skills/salesforce/sf-work-items.md      # Create work item
cat ~/.claude/skills/salesforce/sf-chatter.md          # Add Chatter post
```

### Sprint Planning
**Sequence**: Create sprint → Query backlog → Bulk assign items

```bash
cat ~/.claude/skills/salesforce/sf-work-items.md        # Create sprint
cat ~/.claude/skills/salesforce/sf-soql-queries.md      # Query backlog
cat ~/.claude/skills/salesforce/sf-bulk-operations.md   # Bulk assign
```

### Bulk Status Update
**Sequence**: Query work items → Export CSV → Bulk update → Verify

```bash
cat ~/.claude/skills/salesforce/sf-soql-queries.md       # Query items
cat ~/.claude/skills/salesforce/sf-bulk-operations.md    # Bulk update
```

### Git Integration
**Sequence**: Extract WI from branch → Query details → Update status → Post to Chatter

```bash
cat ~/.claude/skills/salesforce/sf-automation.md        # WI inference
cat ~/.claude/skills/salesforce/sf-soql-queries.md      # Query WI
cat ~/.claude/skills/salesforce/sf-work-items.md        # Update status
cat ~/.claude/skills/salesforce/sf-chatter.md            # Post update
```

### Work Item Reporting
**Sequence**: Query with related data → Export to CSV → Analyze

```bash
cat ~/.claude/skills/salesforce/sf-soql-queries.md       # Complex queries
cat ~/.claude/skills/salesforce/sf-bulk-operations.md    # Export data
```

## Skill Selection Guide

**Use sf-org-auth when:**
- Logging into Salesforce orgs
- Managing multiple org connections
- Getting current user email/ID dynamically
- Switching between environments

**Use sf-soql-queries when:**
- Querying Salesforce data
- Finding record IDs (Users, Epics, Sprints, etc.)
- Building reports or dashboards
- Working with related objects

**Use sf-record-operations when:**
- Creating 1-5 records individually
- Updating specific records by ID
- Working with custom objects
- Using REST API for advanced operations

**Use sf-work-items when:**
- Creating user stories, bugs, or tasks
- Managing sprints and sprint planning
- Working with epics and product tags
- Sprint reporting

**Use sf-chatter when:**
- Posting updates to work items
- Adding comments to records
- Automating notifications from CI/CD

**Use sf-bulk-operations when:**
- Updating 10+ records at once
- Exporting large datasets (>2000 records)
- Bulk status changes
- Avoiding API rate limits

**Use sf-automation when:**
- Extracting WI numbers from git branches
- Automating Chatter posts from commits
- Creating git hooks for Salesforce
- CI/CD integration with GUS

## Integration with Other Skills

Salesforce skills commonly combine with:

**API skills** (`discover-api`):
- REST API integration with Salesforce
- OAuth authentication for Salesforce
- Custom API endpoints using Salesforce data
- Webhook handling for Salesforce events

**Workflow skills** (`discover-workflow`):
- Automated work item creation from CI/CD
- Status update automation based on deployments
- Scheduled bulk operations
- Integration with external systems

**Data skills** (`discover-data`):
- ETL operations with Salesforce data
- Data transformation and analysis
- Export/import workflows
- Data quality and validation checks

**Collaboration skills** (`discover-collaboration`):
- Syncing GitHub issues with GUS work items
- Automated Chatter updates from CI/CD
- Cross-platform project management
- Integration dashboards and reporting

**Testing skills** (`discover-testing`):
- Integration testing for Salesforce integrations
- Automated testing of Salesforce workflows
- Validation of Salesforce data operations
- CI/CD integration with Salesforce deployments

## Usage Instructions

1. **Auto-activation**: This skill loads automatically when Claude Code detects Salesforce-related work
2. **Browse skills**: Run `cat ~/.claude/skills/salesforce/INDEX.md` for full category overview
3. **Load specific skills**: Use bash commands above to load individual skills
4. **Follow patterns**: Each skill contains 5-10 patterns for common operations
5. **Combine skills**: Load related skills for comprehensive Salesforce integration

## Progressive Loading

This gateway skill (~300 lines, ~3K tokens) enables progressive loading:
- **Level 1**: Gateway loads automatically (you're here now)
- **Level 2**: Load category INDEX.md (~350 lines, ~3.5K tokens) for full overview
- **Level 3**: Load specific skill (~150-220 lines, ~1.5-2K tokens each) for detailed guidance

Total context: 3K + 3.5K + (1.5-2K per skill) = efficient skill discovery and usage.

## Quick Start Examples

**"Authenticate to Salesforce"**:
```bash
cat ~/.claude/skills/salesforce/sf-org-auth.md
```

**"Query my work items"**:
```bash
cat ~/.claude/skills/salesforce/sf-soql-queries.md
```

**"Create a user story in GUS"**:
```bash
cat ~/.claude/skills/salesforce/sf-work-items.md
```

**"Update status for multiple work items"**:
```bash
cat ~/.claude/skills/salesforce/sf-bulk-operations.md
```

**"Post update to Chatter"**:
```bash
cat ~/.claude/skills/salesforce/sf-chatter.md
```

**"Extract WI from git branch"**:
```bash
cat ~/.claude/skills/salesforce/sf-automation.md
```

**"Export work items for reporting"**:
```bash
cat ~/.claude/skills/salesforce/sf-bulk-operations.md
```

## Best Practices

**Always:**
- **Use `sf` CLI tool directly** for all Salesforce operations
- Infer WI number from git branch name when not explicitly provided
- Dynamically fetch user email/ID and default org instead of hardcoding
- Use `--target-org "$DEFAULT_ORG"` after fetching it dynamically to avoid ambiguity
- Query for IDs before creating related records
- Use bulk operations for 10+ record updates
- Verify target org before destructive operations
- Include all required fields when creating records
- Validate query results before using extracted values

**Never:**
- Hardcode record IDs (they vary across orgs)
- Hardcode user emails (fetch dynamically)
- Update records without verifying they exist first
- Use single updates in loops (use bulk operations)
- Forget API name suffixes (`__c` for custom fields, `__r` for relationships)
- Commit authentication tokens or credentials
- Skip validation of jq output (check for null/empty)

**Security:**
- ⚠️ Always verify target org before updates
- ⚠️ Query before update to verify record existence
- ⚠️ Be cautious with bulk delete operations
- ⚠️ Use `--target-org` flag for all operations
- ⚠️ Never commit credentials to version control
- ⚠️ Don't post sensitive data to Chatter
- ⚠️ Test automation in sandbox before production

---

**Next Steps**: Run `cat ~/.claude/skills/salesforce/INDEX.md` to see full category details, or load specific skills using the commands above.
