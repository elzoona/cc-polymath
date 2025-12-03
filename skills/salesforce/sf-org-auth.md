---
name: salesforce-org-auth
description: Authenticate and manage Salesforce orgs using sf CLI
---

# Salesforce Org Authentication

**Scope**: Org authentication, connection management, and user information retrieval
**Lines**: ~180
**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)

---

## When to Use This Skill

Activate this skill when:
- Logging into Salesforce orgs
- Managing multiple org connections
- Switching between orgs
- Retrieving current user information
- Getting org details and configuration
- Troubleshooting authentication issues

---

## Core Concepts

### Concept 1: Authentication Methods

**Available Methods**:
- **Web login flow**: Interactive browser-based OAuth
- **JWT bearer flow**: Non-interactive for CI/CD
- **Access token**: Direct token authentication
- **SFDX auth URL**: Import existing authentication

```bash
# Web login (most common - interactive)
sf org login web --alias gus

# Web login with custom instance
sf org login web --alias production --instance-url https://login.salesforce.com

# JWT bearer flow (for CI/CD)
sf org login jwt --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file server.key \
  --username user@example.com \
  --alias ci-org

# Access token login
sf org login access-token --instance-url https://gus.my.salesforce.com \
  --alias gus
```

### Concept 2: Managing Multiple Orgs

**Org Management Commands**:

```bash
# List all authenticated orgs
sf org list

# List with JSON output for scripting
sf org list --json

# Display current org details
sf org display --target-org gus

# Display with verbose output (includes auth URL)
sf org display --target-org gus --verbose

# Set default org
sf config set target-org=gus

# Open org in browser
sf org open --target-org gus

# Logout from org
sf org logout --target-org gus

# Logout from all orgs
sf org logout --all
```

---

## Patterns

### Pattern 1: Getting Current User Information

**Use case**: Dynamically retrieve the logged-in user's email and other details for queries

**IMPORTANT**: Never hardcode user emails (like `user@gus.com`). Always fetch the current user's email dynamically from the authenticated org.

```bash
# ❌ Bad: Hardcoding user email
USER_EMAIL="user@gus.com"

# ✅ Good: Get current user email from authenticated org (by alias)
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .username')

# Alternative: Get from most recently used org
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs | sort_by(.lastUsed) | reverse | .[0].username')

# Alternative: Get user details from org display user
USER_INFO=$(sf org display user --target-org gus --json)
USER_EMAIL=$(echo "$USER_INFO" | jq -r '.result.email')
USER_ID=$(echo "$USER_INFO" | jq -r '.result.id')
USER_NAME=$(echo "$USER_INFO" | jq -r '.result.username')

# Get user's org details
ORG_INFO=$(sf org display --target-org gus --json)
ORG_ID=$(echo "$ORG_INFO" | jq -r '.result.id')
INSTANCE_URL=$(echo "$ORG_INFO" | jq -r '.result.instanceUrl')

echo "Logged in as: $USER_EMAIL"
echo "User ID: $USER_ID"
echo "Org ID: $ORG_ID"
echo "Instance: $INSTANCE_URL"
```

**Benefits**:
- Works across different users and orgs without code changes
- No need to hardcode usernames or emails
- Scripts are portable and can be shared with team members
- Safer - prevents accidentally using wrong user credentials

**Key Points**:
- Use `sf org list --json` to get username from authenticated orgs
- Use `sf org display user --json` for complete user details including ID
- Filter by org alias when multiple orgs are authenticated
- Use User ID (`Assignee__c`) in queries instead of email when possible (more efficient)
- Always validate that the user info was retrieved successfully before using

### Pattern 2: Error Handling for Authentication

**Use case**: Validate authentication and provide helpful error messages

```bash
# Get user email with validation
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .username')

if [ -z "$USER_EMAIL" ] || [ "$USER_EMAIL" = "null" ]; then
  echo "Error: Could not retrieve user email. Is the org authenticated?"
  echo "Run: sf org login web --alias gus"
  exit 1
fi

echo "Querying work items for: $USER_EMAIL"

# Check if org is still connected
ORG_STATUS=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .connectedStatus')

if [ "$ORG_STATUS" != "Connected" ]; then
  echo "Error: Org 'gus' is not connected. Status: $ORG_STATUS"
  echo "Please re-authenticate: sf org login web --alias gus"
  exit 1
fi
```

### Pattern 3: Multi-Org Workflows

**Use case**: Work with multiple orgs (dev, staging, production)

```bash
# Setup multiple orgs with meaningful aliases
sf org login web --alias gus-dev
sf org login web --alias gus-staging
sf org login web --alias gus-prod

# Function to query across multiple orgs
query_all_orgs() {
  local query="$1"
  for org in gus-dev gus-staging gus-prod; do
    echo "=== Results from $org ==="
    sf data query --query "$query" --target-org "$org" || echo "Failed for $org"
  done
}

# Use the function
query_all_orgs "SELECT Id, Name FROM ADM_Work__c WHERE Status__c = 'New' LIMIT 5"

# Get org info for all authenticated orgs
sf org list --json | jq -r '.result.nonScratchOrgs[] | "\(.alias): \(.username) - \(.instanceUrl)"'
```

---

## Quick Reference

### Common Commands

```bash
# Authentication
sf org login web --alias <alias>              # Login via browser
sf org list                                    # List all orgs
sf org display --target-org <alias>           # Show org details
sf org open --target-org <alias>              # Open org in browser
sf org logout --target-org <alias>            # Logout from org

# User Information
sf org display user --target-org <alias>      # Show current user details
sf org display user --json                     # JSON output for scripting

# Configuration
sf config set target-org=<alias>              # Set default org
sf config get target-org                       # Get default org
```

### Org Information Available via JSON

From `sf org list --json`:
- `username` - User's email/username
- `alias` - Org alias
- `orgId` - Organization ID
- `instanceUrl` - Salesforce instance URL
- `connectedStatus` - Connection status
- `lastUsed` - Last access timestamp

From `sf org display user --json`:
- `id` - User's Salesforce ID (use for queries)
- `username` - Username
- `email` - User's email
- `profileName` - User's profile
- `alias` - Org alias

---

## Best Practices

**Essential Practices:**
```
✅ DO: Use meaningful aliases for orgs (e.g., gus, gus-prod, gus-dev)
✅ DO: Dynamically fetch user email/ID instead of hardcoding
✅ DO: Check org connection status before operations
✅ DO: Use --json flag for programmatic processing
✅ DO: Validate extracted values before using them
✅ DO: Store multiple org connections for different environments
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Hardcode user emails or org URLs
❌ DON'T: Assume an org is still authenticated
❌ DON'T: Skip validation of jq output (check for null/empty)
❌ DON'T: Use generic aliases like "org1" (use descriptive names)
❌ DON'T: Commit auth URLs or tokens to version control
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Hardcode user credentials
USER_EMAIL="user@gus.com"
USER_ID="005xx000001X8Uz"

# ✅ CORRECT: Fetch dynamically
USER_EMAIL=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.alias == "gus") | .username')
USER_ID=$(sf org display user --target-org gus --json | jq -r '.result.id')
```

---

## Security Considerations

**Security Notes**:
- ⚠️ Never commit authentication tokens or auth URLs
- ⚠️ Use `--verbose` flag carefully (exposes auth URL)
- ⚠️ Validate org alias before operations
- ⚠️ Logout from shared/public machines
- ⚠️ Use JWT for CI/CD instead of storing passwords
- ⚠️ Rotate access tokens regularly

---

## Related Skills

- `sf-soql-queries.md` - Query data using authenticated orgs
- `sf-record-operations.md` - Create/update records
- `sf-work-items.md` - Work with GUS objects
- `sf-bulk-operations.md` - Bulk data operations

---

**Last Updated**: 2025-12-03
**Format Version**: 1.0 (Atomic)
