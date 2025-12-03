---
name: salesforce-org-auth
description: Authenticate and manage Salesforce orgs using sf CLI. Use for login, org management, user information, and GUS authentication.
keywords: salesforce, gus, authentication, login, org, user info, sf cli, connect, session
---

# Salesforce Org Authentication

**Scope**: Org authentication, connection management, and user information retrieval
**Lines**: ~348
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
sf org login web --alias my-org

# Web login with custom instance
sf org login web --alias production --instance-url https://login.salesforce.com

# JWT bearer flow (for CI/CD)
sf org login jwt --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file server.key \
  --username user@example.com \
  --alias ci-org

# Access token login
sf org login access-token --instance-url https://my-org.my.salesforce.com \
  --alias my-org
```

### Concept 2: Managing Multiple Orgs

**Org Management Commands**:

```bash
# List all authenticated orgs
sf org list

# List with JSON output for scripting
sf org list --json

# Get default org dynamically
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  # If no config default, check for org marked as default
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    # Fall back to first available org
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Display current org details (only if DEFAULT_ORG is set)
if [ -n "$DEFAULT_ORG" ]; then
  sf org display --target-org "$DEFAULT_ORG"
else
  echo "No default org found. Set one with: sf config set target-org=<alias>"
fi

# Display with verbose output (includes auth URL)
sf org display --target-org "$DEFAULT_ORG" --verbose

# Set default org
sf config set target-org=my-org

# Open org in browser
sf org open --target-org "$DEFAULT_ORG"

# Logout from org
sf org logout --target-org "$DEFAULT_ORG"

# Logout from all orgs
sf org logout --all
```

---

## Patterns

### Pattern 1: Getting Current User Information

**Use case**: Dynamically retrieve the logged-in user's email and other details for queries

**IMPORTANT**: Never hardcode user emails or org aliases. Always fetch the current user's email and default org dynamically from the authenticated org.

```bash
# ❌ Bad: Hardcoding user email or org alias
USER_EMAIL="user@example.com"
DEFAULT_ORG="gus"

# ✅ Good: Get default org dynamically
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')

# If no default org is set, check for marked default or use first available
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

# Get current user email from default org
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')

# Alternative: Get user details from org display user
USER_INFO=$(sf org display user --target-org "$DEFAULT_ORG" --json)
USER_EMAIL=$(echo "$USER_INFO" | jq -r '.result.email')
USER_ID=$(echo "$USER_INFO" | jq -r '.result.id')
USER_NAME=$(echo "$USER_INFO" | jq -r '.result.username')

# Get user's org details
ORG_INFO=$(sf org display --target-org "$DEFAULT_ORG" --json)
ORG_ID=$(echo "$ORG_INFO" | jq -r '.result.id')
INSTANCE_URL=$(echo "$ORG_INFO" | jq -r '.result.instanceUrl')

echo "Default Org: $DEFAULT_ORG"
echo "Logged in as: $USER_EMAIL"
echo "User ID: $USER_ID"
echo "Org ID: $ORG_ID"
echo "Instance: $INSTANCE_URL"
```

**Benefits**:
- Works across different users and orgs without code changes
- No need to hardcode usernames, emails, or org aliases
- Scripts are portable and can be shared with team members
- Safer - prevents accidentally using wrong user credentials or org
- Automatically adapts to the user's default org configuration

**Key Points**:
- Use `sf config get target-org --json` to get the default org dynamically
- Use `sf org list --json` to get username from authenticated orgs
- Use `sf org display user --json` for complete user details including ID
- Fall back to most recently used org if no default org is set
- Use User ID (`Assignee__c`) in queries instead of email when possible (more efficient)
- Always validate that the user info and org were retrieved successfully before using

### Pattern 2: Error Handling for Authentication

**Use case**: Validate authentication and provide helpful error messages

```bash
# Get default org with validation
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')

if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

if [ -z "$DEFAULT_ORG" ] || [ "$DEFAULT_ORG" = "null" ]; then
  echo "Error: No default org configured and no authenticated orgs found."
  echo "Run: sf org login web --alias my-org"
  echo "Then: sf config set target-org=my-org"
  exit 1
fi

# Get user email with validation
USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')

if [ -z "$USER_EMAIL" ] || [ "$USER_EMAIL" = "null" ]; then
  echo "Error: Could not retrieve user email for org: $DEFAULT_ORG"
  echo "Run: sf org login web --alias $DEFAULT_ORG"
  exit 1
fi

echo "Querying work items for: $USER_EMAIL (org: $DEFAULT_ORG)"

# Check if org is still connected
ORG_STATUS=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .connectedStatus')

if [ "$ORG_STATUS" != "Connected" ]; then
  echo "Error: Org '$DEFAULT_ORG' is not connected. Status: $ORG_STATUS"
  echo "Please re-authenticate: sf org login web"
  exit 1
fi
```

### Pattern 3: Multi-Org Workflows

**Use case**: Work with multiple orgs (dev, staging, production)

```bash
# Setup multiple orgs with meaningful aliases
sf org login web --alias dev
sf org login web --alias staging
sf org login web --alias prod

# Set default org
sf config set target-org=dev

# Function to query across multiple orgs
query_all_orgs() {
  local query="$1"
  for org in dev staging prod; do
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
✅ DO: Use meaningful aliases for orgs (e.g., prod, staging, dev)
✅ DO: Set a default org with sf config set target-org
✅ DO: Dynamically fetch default org and user email/ID instead of hardcoding
✅ DO: Check org connection status before operations
✅ DO: Use --json flag for programmatic processing
✅ DO: Validate extracted values before using them
✅ DO: Store multiple org connections for different environments
```

**Common Mistakes to Avoid:**
```
❌ DON'T: Hardcode user emails, org aliases, or org URLs
❌ DON'T: Assume an org is still authenticated
❌ DON'T: Skip validation of jq output (check for null/empty)
❌ DON'T: Use generic aliases like "org1" (use descriptive names)
❌ DON'T: Commit auth URLs or tokens to version control
```

---

## Anti-Patterns

### Critical Violations

```bash
# ❌ NEVER: Hardcode user credentials or org aliases
USER_EMAIL="user@example.com"
USER_ID="005xx000001X8Uz"
DEFAULT_ORG="gus"

# ✅ CORRECT: Fetch dynamically
DEFAULT_ORG=$(sf config get target-org --json | jq -r '.result[0].value // empty')
if [ -z "$DEFAULT_ORG" ]; then
  DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[] | select(.isDefaultUsername == true) | .alias' | head -1)
  if [ -z "$DEFAULT_ORG" ]; then
    DEFAULT_ORG=$(sf org list --json | jq -r '.result.nonScratchOrgs[0].alias // empty')
  fi
fi

USER_EMAIL=$(sf org list --json | jq -r --arg org "$DEFAULT_ORG" '.result.nonScratchOrgs[] | select(.alias == $org or .username == $org) | .username')
USER_ID=$(sf org display user --target-org "$DEFAULT_ORG" --json | jq -r '.result.id')
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
