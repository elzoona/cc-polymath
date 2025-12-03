---
name: salesforce-soql-queries
description: Query Salesforce data using SOQL and sf CLI. Use for GUS work items, epics, sprints, teams, Agile Accelerator queries, and any Salesforce object queries.
keywords: salesforce, gus, soql, query, work items, epic, sprint, team, agile accelerator, ADM_Work__c, ADM_Epic__c, ADM_Sprint__c, ADM_Scrum_Team_Member__c, user, field verification
---

# Salesforce SOQL Queries (Navigation)

**Scope**: Navigation guide to SOQL skill files
**Last Updated**: 2025-12-03
**Format Version**: 2.0 (Split into focused skill files)

---

## Overview

This skill has been split into three focused files for better organization and faster loading:

1. **sf-soql-basics.md** - Start here for core concepts and basic queries
2. **sf-soql-advanced.md** - Complex queries, aggregation, and advanced patterns
3. **sf-soql-troubleshooting.md** - Error handling, anti-patterns, and debugging

---

## Which Skill File Should I Use?

### Use sf-soql-basics.md When:
- **Starting with SOQL queries** - Learn the basics first
- **Querying simple data** - Users, work items by ID, basic lookups
- **Learning field verification** - Understand the mandatory describe workflow
- **Looking up team memberships** - Find which teams a user belongs to
- **Finding record IDs** - Locate User IDs, Epic IDs, etc.

**Key Concepts**: MANDATORY field discovery, basic SOQL syntax, relationship names, verified field names, output formats

**Example Patterns**:
- Discovering object fields (MANDATORY FIRST STEP)
- Querying team memberships
- Finding record IDs
- Basic work item queries

---

### Use sf-soql-advanced.md When:
- **Querying work items by various criteria** - Assignee, sprint, epic, status
- **Aggregating data** - Counts, sums, grouped results
- **Filtering by dates** - Date ranges, relative dates (THIS_WEEK, LAST_N_DAYS)
- **Querying metadata** - Apex classes, triggers using Tooling API
- **Complex multi-condition queries** - Multiple filters and relationships

**Key Concepts**: Work item queries, aggregation (COUNT, SUM), date filters, tooling API

**Example Patterns**:
- Querying work items by assignee, sprint, epic, type
- Complex queries with aggregation (counts, sums, grouped data)
- Date filtering (relative and absolute)
- Using Tooling API for metadata

---

### Use sf-soql-troubleshooting.md When:
- **Debugging SOQL query errors** - INVALID_FIELD, relationship errors, operator errors
- **Understanding common mistakes** - Why queries fail and how to fix them
- **Learning anti-patterns** - What NOT to do in SOQL queries
- **Troubleshooting field verification** - Field doesn't exist errors
- **Fixing relationship queries** - Wrong relationship name errors

**Key Concepts**: Critical violations, common field errors, query performance, troubleshooting workflow

**Critical Violations Covered**:
1. Querying fields without verification (MOST COMMON)
2. Assuming relationship names match object names (VERY COMMON)
3. Using shell special characters (! in queries)
4. Using LIKE on ID/reference fields
5. Not validating query results

---

## Quick Start Guide

### I'm New to SOQL
**Start with**: [sf-soql-basics.md](sf-soql-basics.md)
- Read Concept 1 (MANDATORY field discovery)
- Read Concept 2 (Basic SOQL syntax)
- Read Concept 3 (Relationship names)
- Try Pattern 1 (Discovering object fields)

### I Need to Query Work Items
**Start with**: [sf-soql-basics.md](sf-soql-basics.md) for simple queries, then [sf-soql-advanced.md](sf-soql-advanced.md) for complex filtering
- sf-soql-basics.md: Basic work item queries by ID or simple criteria
- sf-soql-advanced.md: Pattern 1 (Querying work items by assignee, sprint, epic)

### I'm Getting Errors
**Start with**: [sf-soql-troubleshooting.md](sf-soql-troubleshooting.md)
- Critical Violation #1: Field doesn't exist errors
- Critical Violation #2: Relationship name errors
- Critical Violation #3: Shell escaping errors
- Critical Violation #4: LIKE on ID fields errors
- Common Field Errors section

### I Need Aggregation or Complex Queries
**Start with**: [sf-soql-advanced.md](sf-soql-advanced.md)
- Pattern 2 (Complex queries with aggregation)
- Pattern 3 (Querying with date filters)
- Pattern 4 (Using Tooling API)

---

## Common Workflows

### Workflow 1: Query User's Teams
1. **sf-soql-basics.md** - Concept 1: Run sf sobject describe for ADM_Scrum_Team_Member__c
2. **sf-soql-basics.md** - Pattern 2: Query team memberships
3. **sf-soql-troubleshooting.md** - If errors occur, check Critical Violations

### Workflow 2: Find Work Items by Epic
1. **sf-soql-basics.md** - Pattern 3: Find Epic ID by name
2. **sf-soql-advanced.md** - Pattern 1: Query work items by epic
3. **sf-soql-troubleshooting.md** - If errors occur, check field verification

### Workflow 3: Sprint Reporting
1. **sf-soql-basics.md** - Pattern 3: Find Sprint ID
2. **sf-soql-advanced.md** - Pattern 2: Aggregate story points by status
3. **sf-soql-advanced.md** - Pattern 3: Filter by date range

---

## Critical Rules (Apply to All SOQL Queries)

**⚠️ MANDATORY FIELD VERIFICATION**:
```
BEFORE writing ANY SOQL query, you MUST:
1. Run `sf sobject describe --sobject <ObjectName>`
2. Verify the exact field names exist in the output
3. Only then write your SOQL query using verified field names

This is NOT optional. This is MANDATORY.
```

**⚠️ RELATIONSHIP NAMES**:
```
Relationship names (the __r suffix) are DIFFERENT from object names.
NEVER assume the relationship name matches the object name.

Example:
- Field: Scrum_Team__c
- Object: ADM_Scrum_Team__c
- Relationship: Scrum_Team__r (NOT ADM_Scrum_Team__r!)

ALWAYS use sf sobject describe to get the relationshipName field.
```

**⚠️ COMMON MISTAKES**:
```
❌ DON'T: Query fields without sf sobject describe first
❌ DON'T: Assume relationship names match object names
❌ DON'T: Use LIKE on ID/reference fields (use = instead)
❌ DON'T: Use != in CLI queries (use <> instead - shell escapes !)
❌ DON'T: Check relationship name fields for null (check ID field instead)
❌ DON'T: Assume ANY field exists without verification
```

---

## Verified Field Names (Quick Reference)

**IMPORTANT**: These are verified but may vary by org. ALWAYS run `sf sobject describe` to verify fields in YOUR org before querying.

**ADM_Work__c (Work Items)**:
```
Id, Name, Subject__c, Status__c, Priority__c, Type__c
Story_Points__c, Assignee__c (→User), Sprint__c (→ADM_Sprint__c)
Epic__c (→ADM_Epic__c), Found_in_Build__c (→ADM_Build__c)
Product_Tag__c (→ADM_Product_Tag__c), Description__c
```

**ADM_Scrum_Team_Member__c (Team Membership)**:
```
Id, Name (auto-number: STM-######)
Member_Name__c (→User - use = not LIKE)
Scrum_Team__c (→ADM_Scrum_Team__c)
Scrum_Team_Name__c (formula field)
Internal_Email__c (NOT Email__c!)
Role__c, Active__c
```

**User (Standard Object)**:
```
Id, Name, Email, Username, IsActive
Note: No Team__c field - use ADM_Scrum_Team_Member__c junction object
```

**Related Field Notation (VERIFIED)**:
```
Assignee__r.Name            # User name
Assignee__r.Email           # User email
Sprint__r.Name              # Sprint name
Epic__r.Name                # Epic name
Scrum_Team__r.Name          # Team name (NOT ADM_Scrum_Team__r!)
```

---

## Related Skills

- `sf-org-auth.md` - Authentication and user info
- `sf-record-operations.md` - Create/update records
- `sf-work-items.md` - Work with GUS objects
- `sf-bulk-operations.md` - Export large datasets
- `sf-chatter.md` - Post Chatter updates
- `sf-automation.md` - Git integration and automation

---

## File Organization

**Skill Files**:
- [sf-soql-basics.md](sf-soql-basics.md) - ~350 lines, v1.0
- [sf-soql-advanced.md](sf-soql-advanced.md) - ~350 lines, v1.0
- [sf-soql-troubleshooting.md](sf-soql-troubleshooting.md) - ~450 lines, v1.0
- [sf-soql-queries.md](sf-soql-queries.md) - This navigation file, v2.0

**Version History**:
- v2.0 (2025-12-03): Split into focused skill files (basics, advanced, troubleshooting)
- v1.2 (2025-12-03): Added mandatory field verification and relationship name rules
- v1.1 (2025-12-03): Added keywords for GUS/team/epic discoverability
- v1.0 (2025-12-02): Initial unified skill file

---

**Last Updated**: 2025-12-03
**Format Version**: 2.0 (Navigation file for split skills)
