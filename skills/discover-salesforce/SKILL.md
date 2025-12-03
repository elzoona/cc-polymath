---
name: discover-salesforce
description: Automatically discover Salesforce CLI (sf) skills when working with Salesforce orgs, Agile Accelerator (GUS), SOQL queries, work items (WI), user stories, sprints, or Chatter. Activates for Salesforce integration and automation tasks.
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

The Salesforce category contains 1 comprehensive skill:

1. **sf-cli-operations** - Complete guide to Salesforce CLI operations, SOQL, record management, bulk operations, and Agile Accelerator workflows

**Note**: All examples use `gus` as the default org alias. This refers to your Salesforce org where Agile Accelerator (GUS) is configured. If your org has a different alias, simply replace `--target-org gus` with your org alias throughout.

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

Load the Salesforce CLI operations skill:

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

## Common Workflows

### Create User Story
**Sequence**: Query dependencies → Create work item → Add Chatter update

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

Use Pattern 1 (Creating User Stories with Dependencies) and Pattern 6 (Finding Record IDs).

### Sprint Planning
**Sequence**: Create sprint → Query backlog → Bulk assign items

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

Use Pattern 4 (Managing Sprints and Builds) and Pattern 2 (Bulk Status Updates).

### Bulk Status Update
**Sequence**: Query work items → Export CSV → Bulk update → Verify

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

Use Pattern 2 (Bulk Status Updates) and Pattern 7 (Bulk Data Export).

### Work Item Reporting
**Sequence**: Query with related data → Export to CSV → Analyze

```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```

Use Pattern 7 (Bulk Data Export) and SOQL query patterns from Concept 2.

## Skill Selection Guide

**Use sf-cli-operations when:**
- Creating or updating work items in Agile Accelerator (GUS)
- Performing bulk operations on Salesforce data
- Querying Salesforce using SOQL
- Managing sprints, epics, and builds
- Posting updates to Chatter feeds
- Automating Salesforce workflows
- Integrating Salesforce with other tools
- Exporting data for reporting and analysis

**Common Operations:**
- **Authentication**: `sf org login web`, `sf org list`, `sf org display`
- **Queries**: `sf data query` with SOQL syntax
- **Record Creation**: `sf data create record` with `--sobject` and `--values`
- **Record Updates**: `sf data update record` by ID or field match
- **Bulk Operations**: `sf data update bulk`, `sf data export bulk`
- **REST API**: `sf api request rest` for custom operations

**Common Objects:**
- `ADM_Work__c` - Work Items (Stories, Bugs, Tasks)
- `ADM_Epic__c` - Epics
- `ADM_Sprint__c` - Sprints
- `ADM_Build__c` - Scheduled Builds
- `ADM_Product_Tag__c` - Product Tags
- `FeedItem` - Chatter Posts
- `FeedComment` - Chatter Comments
- `User` - Salesforce Users

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
3. **Load specific skills**: Use bash command above to load the comprehensive sf-cli-operations skill
4. **Follow patterns**: Use the 8+ patterns for common Salesforce operations
5. **Combine skills**: Load related skills for comprehensive Salesforce integration

## Progressive Loading

This gateway skill (~250 lines, ~2.5K tokens) enables progressive loading:
- **Level 1**: Gateway loads automatically (you're here now)
- **Level 2**: Load category INDEX.md (~3K tokens) for full overview
- **Level 3**: Load sf-cli-operations.md (~4K tokens) for complete guide

Total context: 2.5K + 3K + 4K = ~10K tokens for complete Salesforce expertise.

## Quick Start Examples

**"Create a user story in GUS"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Pattern 1: Creating User Stories with Dependencies

**"Query work items for a sprint"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Concept 2: SOQL Queries and Pattern 6: Finding Record IDs

**"Update status for multiple work items"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Pattern 2: Bulk Status Updates

**"Create a sprint and assign work items"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Pattern 4: Managing Sprints and Builds

**"Add a comment to Chatter"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Pattern 3: Creating Chatter Posts

**"Export work items for reporting"**:
```bash
cat ~/.claude/skills/salesforce/sf-cli-operations.md
```
See Pattern 7: Bulk Data Export

## Best Practices

**Always:**
- **Use `sf` CLI tool directly** for all Salesforce operations
- Infer WI number from git branch name when not explicitly provided (see Pattern 9)
- Specify `--target-org gus` (or your org alias) to avoid ambiguity
- Query for IDs before creating related records
- Use bulk operations for multiple record updates
- Verify target org before destructive operations
- Include all required fields when creating records

**Never:**
- Hardcode record IDs (they vary across orgs)
- Update records without verifying they exist first
- Use single updates in loops (use bulk operations)
- Forget API name suffixes (`__c` for custom fields)
- Commit authentication tokens or credentials

**Security:**
- ⚠️ Always verify target org before updates
- ⚠️ Query before update to verify record existence
- ⚠️ Be cautious with bulk delete operations
- ⚠️ Use `--target-org` flag for all operations
- ⚠️ Never commit credentials to version control

---

**Next Steps**: Run `cat ~/.claude/skills/salesforce/INDEX.md` to see full category details, or load `sf-cli-operations.md` for the complete Salesforce CLI guide.
