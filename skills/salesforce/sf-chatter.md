---
name: salesforce-chatter
description: Create and manage Chatter posts and comments in Salesforce
---

# Salesforce Chatter Operations

**Scope**: Creating Chatter posts, comments, and feed interactions
**Lines**: ~180
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Posting updates to Chatter feeds
- Adding comments to work items
- Automating Chatter notifications
- Creating progress updates
- Documenting decisions on records
- Sharing information with team members

---

## Core Concepts

### Concept 1: Chatter Objects

**FeedItem** - Main Chatter posts
**FeedComment** - Comments on posts
**ParentId** - The record to post on (Work Item, Epic, User, etc.)

**Key Fields**:
```
FeedItem:
  ParentId       - Record ID to post on (required)
  Body           - Post text content (required)
  Type           - TextPost (default), LinkPost, ContentPost

FeedComment:
  FeedItemId     - The post ID to comment on (required)
  CommentBody    - Comment text (required)
```

### Concept 2: Post Types

**TextPost** (default):
- Plain text or basic formatting
- Most common type
- Simple status updates

**LinkPost**:
- Shares URLs with preview
- Requires LinkUrl field

**ContentPost**:
- Shares Salesforce files
- Requires ContentDocumentId

---

## Patterns

### Pattern 1: Creating Basic Chatter Posts

**Use case**: Post updates to work item feeds

```bash
# Simple text post
sf data create record \
  --sobject FeedItem \
  --values "ParentId='a07xx00000ABCDE' Body='Started work on this feature'" \
  --target-org gus

# Multi-line post with details
sf data create record \
  --sobject FeedItem \
  --values "ParentId='a07xx00000ABCDE' Body='Phase 1.2 complete:
- S3 Storage Service implemented
- 32 tests passing
- File size validation added
- CI configuration updated'" \
  --target-org gus

# Post with structured update
sf data create record \
  --sobject FeedItem \
  --values "ParentId='a07xx00000ABCDE' \
           Body='Implementation Status:

✅ Backend API complete
✅ Database schema migrated
⏳ Frontend integration in progress
⏳ Testing pending

Ready for review by EOD.'" \
  --target-org gus
```

### Pattern 2: Adding Comments to Posts

**Use case**: Comment on existing Chatter posts

```bash
# Create a comment
sf data create record \
  --sobject FeedComment \
  --values "FeedItemId='0D5xx00000FGHIJ' CommentBody='LGTM - approved for merge'" \
  --target-org gus

# Comment with @mention (use User ID for @mention)
sf data create record \
  --sobject FeedComment \
  --values "FeedItemId='0D5xx00000FGHIJ' CommentBody='Thanks for the update! Please coordinate with {005xx000001X8Uz} for testing.'" \
  --target-org gus

# Comment with feedback
sf data create record \
  --sobject FeedComment \
  --values "FeedItemId='0D5xx00000FGHIJ' \
           CommentBody='Great work! A few questions:
1. Did you test edge cases?
2. Is documentation updated?
3. Any performance concerns?'" \
  --target-org gus
```

### Pattern 3: Automated Status Updates

**Use case**: Post Chatter updates from CI/CD or automation

```bash
# Post build success notification
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org gus | jq -r '.result.records[0].Id')

sf data create record \
  --sobject FeedItem \
  --values "ParentId='${WORK_ITEM_ID}' \
           Body='✅ Build #${BUILD_NUMBER} passed
All tests: 156/156 ✓
Coverage: 94%
Ready for deployment'" \
  --target-org gus

# Post failure notification
sf data create record \
  --sobject FeedItem \
  --values "ParentId='${WORK_ITEM_ID}' \
           Body='❌ Build #${BUILD_NUMBER} failed
Failed tests: 3/156
See: ${BUILD_URL}
Please investigate.'" \
  --target-org gus
```

### Pattern 4: Post from Git Branch Context

**Use case**: Automatically post to WI based on current git branch

```bash
# Extract WI number from branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WI_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]{8}' | head -1)

if [ -n "$WI_NUMBER" ]; then
  # Query for work item
  QUERY_RESULT=$(sf data query \
    --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-${WI_NUMBER}'" \
    --target-org gus \
    --json)

  WORK_ITEM_ID=$(echo "$QUERY_RESULT" | jq -r '.result.records[0].Id')

  if [ -n "$WORK_ITEM_ID" ] && [ "$WORK_ITEM_ID" != "null" ]; then
    # Post update to work item
    sf data create record \
      --sobject FeedItem \
      --values "ParentId=${WORK_ITEM_ID} \
               Body='Feature implementation completed and ready for review

Branch: ${BRANCH}
Commits: $(git log --oneline -n 5 | head -5)'" \
      --target-org gus

    echo "Posted update to W-${WI_NUMBER}"
  else
    echo "Work item W-${WI_NUMBER} not found"
  fi
else
  echo "No WI number found in branch: $BRANCH"
fi
```

### Pattern 5: Querying Chatter Feed

**Use case**: Read Chatter posts and comments

```bash
# Query Chatter feed for a record
sf data query \
  --query "SELECT Id, Body, CreatedBy.Name, CreatedDate
    FROM FeedItem
    WHERE ParentId = 'a07xx00000ABCDE'
    ORDER BY CreatedDate DESC
    LIMIT 20" \
  --target-org gus

# Query comments on a post
sf data query \
  --query "SELECT CommentBody, CreatedBy.Name, CreatedDate
    FROM FeedComment
    WHERE FeedItemId = '0D5xx00000FGHIJ'
    ORDER BY CreatedDate ASC" \
  --target-org gus

# Find recent posts mentioning keywords
sf data query \
  --query "SELECT Id, Body, Parent.Name, CreatedBy.Name, CreatedDate
    FROM FeedItem
    WHERE Body LIKE '%deployment%'
    AND CreatedDate = LAST_N_DAYS:7
    ORDER BY CreatedDate DESC" \
  --target-org gus
```

### Pattern 6: Link Posts

**Use case**: Share URLs with previews

```bash
# Post with link
sf data create record \
  --sobject FeedItem \
  --values "ParentId='a07xx00000ABCDE' \
           Type='LinkPost' \
           Body='Check out the documentation' \
           LinkUrl='https://docs.example.com/feature-guide'" \
  --target-org gus

# Post PR link
PR_URL="https://github.com/org/repo/pull/123"
sf data create record \
  --sobject FeedItem \
  --values "ParentId='${WORK_ITEM_ID}' \
           Type='LinkPost' \
           Body='Pull request ready for review' \
           LinkUrl='${PR_URL}'" \
  --target-org gus
```

---

## Quick Reference

### Common Commands

```bash
# Create post
sf data create record --sobject FeedItem --values "ParentId=<Id> Body='<text>'" --target-org <alias>

# Create comment
sf data create record --sobject FeedComment --values "FeedItemId=<Id> CommentBody='<text>'" --target-org <alias>

# Query feed
sf data query --query "SELECT Body, CreatedBy.Name FROM FeedItem WHERE ParentId = '<Id>'" --target-org <alias>

# Query comments
sf data query --query "SELECT CommentBody FROM FeedComment WHERE FeedItemId = '<Id>'" --target-org <alias>
```

### Key Fields

**FeedItem (Posts)**:
```
ParentId        - Record to post on (required)
Body            - Post text (required, max 10000 chars)
Type            - TextPost, LinkPost, ContentPost
LinkUrl         - URL for LinkPost
Visibility      - AllUsers, InternalUsers (default: AllUsers)
```

**FeedComment (Comments)**:
```
FeedItemId      - Post to comment on (required)
CommentBody     - Comment text (required, max 10000 chars)
```

---

## Best Practices

**Essential Practices:**
```
✅ DO: Keep posts clear and concise
✅ DO: Use structured formatting for readability
✅ DO: Include relevant context and links
✅ DO: Validate ParentId exists before posting
✅ DO: Handle errors gracefully in automation
✅ DO: Use meaningful update messages
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Post sensitive information (passwords, tokens)
❌ DON'T: Spam feeds with automated posts
❌ DON'T: Use Chatter for private/confidential data
❌ DON'T: Forget to validate work item IDs
❌ DON'T: Post without checking if record exists
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Post without validating ParentId
sf data create record \
  --sobject FeedItem \
  --values "ParentId='UNKNOWN_ID' Body='Update'" \
  --target-org gus

# ✅ CORRECT: Validate record exists
WORK_ITEM_ID=$(sf data query \
  --query "SELECT Id FROM ADM_Work__c WHERE Name = 'W-12345678'" \
  --result-format json \
  --target-org gus | jq -r '.result.records[0].Id')

if [ -n "$WORK_ITEM_ID" ] && [ "$WORK_ITEM_ID" != "null" ]; then
  sf data create record \
    --sobject FeedItem \
    --values "ParentId='${WORK_ITEM_ID}' Body='Update'" \
    --target-org gus
else
  echo "Error: Work item not found"
fi
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Never post sensitive data (credentials, tokens, PII)
- ⚠️ Chatter posts are visible to users with record access
- ⚠️ Don't use Chatter for confidential information
- ⚠️ Validate ParentId to avoid posting to wrong records
- ⚠️ Be mindful of @mentions and notifications

---

## Related Skills

- `sf-org-auth.md` - Authentication for Chatter operations
- `sf-soql-queries.md` - Query Chatter feeds
- `sf-work-items.md` - Post updates to work items
- `sf-automation.md` - Automate Chatter from git/CI

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
