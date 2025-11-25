# Getting Started with cc-polymath

## What is cc-polymath?

cc-polymath is a Claude Code plugin that provides **447 production-ready skills** across 31+ domains, organized through an intelligent three-tier discovery system. Instead of loading thousands of lines of documentation upfront, skills auto-discover based on your work and activate only when needed.

**The Problem**: Traditional approaches force you to either load everything (overwhelming context) or remember what exists (cognitive overhead).

**The Solution**: Skills automatically activate when you mention relevant keywords like "React", "PostgreSQL", or "REST API". You can also use explicit commands like `/discover-frontend` for manual control. This hybrid approach gives you both convenience and control while using 98% less context than loading all skills upfront.

## Installation (30 seconds)

Open Claude Code and install the plugin:

```
/plugin marketplace add rand/cc-polymath
/plugin install cc-polymath@cc-polymath
```

Wait for the confirmation message:
```
✓ Plugin cc-polymath installed successfully
```

That's it! Skills are now available and will auto-discover as you work.

## Verification (10 seconds)

Verify your installation is working correctly:

```bash
bash ~/.claude/plugins/cc-polymath/scripts/verify-install.sh
```

Expected output:
```
━━━ cc-polymath Installation Verification ━━━

✓ Plugin directory exists
✓ Found .claude-plugin/plugin.json
✓ Found skills/README.md
✓ Found commands/skills.md
✓ Found 28 gateway skills
✓ Skills catalog readable (31 categories)
✓ File permissions OK

━━━ Summary ━━━
Passed: 6
Failed: 0

✓ Installation verified successfully!
```

If you see any failures, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Your First 5 Minutes

Let's get you productive immediately with a guided walkthrough.

### Minute 1: Discover What's Available

Check which skills are recommended for your current project:

```
/skills
```

You'll see personalized recommendations based on the files in your directory. For example, if you have a `package.json`, you'll see frontend skills recommended.

**Example output**:
```
RECOMMENDED FOR THIS PROJECT:
→ discover-frontend
  cat ~/.claude/plugins/cc-polymath/skills/discover-frontend/SKILL.md

→ discover-testing
  cat ~/.claude/plugins/cc-polymath/skills/discover-testing/SKILL.md

CATEGORIES (447 skills):
Frontend (10) | Database (11) | API (7) | Testing (6) | Diagrams (8) | ML (33)
[...]
```

### Minute 2: Try a Gateway Skill

Load a gateway skill manually to see how it works:

```
/discover-frontend
```

This loads the frontend gateway skill, giving you quick access to React, Next.js, TypeScript, and more. Gateway skills are lightweight (~200 lines) and provide overview + quick reference.

**What you get**:
- Quick reference for common patterns
- Links to specific skills
- Auto-context for follow-up questions

### Minute 3: Browse a Category

Explore all skills in a specific category:

```
/skills database
```

You'll see a detailed breakdown of all 11 database skills with descriptions:
```
DATABASE SKILLS (11 total)
Keywords: PostgreSQL, MongoDB, Redis, query optimization

SKILLS:
1. database-selection - Choose the right database for your use case
2. postgres-query-optimization - EXPLAIN plans, indexes, performance
3. postgres-schema-design - Designing schemas, relationships, data types
4. mongodb-patterns - Document modeling, aggregation pipelines
5. redis-patterns - Caching strategies, data structures
[...]
```

### Minute 4: Test Auto-Discovery

Here's where the magic happens. Just start working naturally:

**Try this**: "I need to build a REST API for user authentication"

**What happens**:
1. The `discover-api` skill auto-discovers based on keywords "REST API"
2. Claude loads relevant API design patterns
3. Follow-up questions get context-aware answers about authentication

**You didn't need to**:
- Remember the skill exists
- Type a command to load it
- Search through documentation

Skills just appear when you need them.

### Minute 5: Create a Diagram

Let's make something visual:

**Ask**: "Create a flowchart showing a typical login flow"

**What happens**:
1. `discover-diagrams` skill auto-discovers
2. Claude creates a Mermaid flowchart
3. You get a visual diagram in your conversation

**Result**: Professional flowchart in seconds, ready to add to your README.

---

## Quick Command Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `/plugin list` | Show installed plugins | Check cc-polymath version |
| `/skills` | Project recommendations | See skills relevant to current directory |
| `/skills [category]` | Browse category | `/skills frontend` or `/skills database` |
| `/skills [search]` | Search for skills | `/skills postgres` or `/skills react` |
| `/skills list` | Show all categories | See all 31 categories |
| `/discover-api` | Load API skills | REST, GraphQL, authentication |
| `/discover-frontend` | Load frontend skills | React, Next.js, TypeScript |
| `/discover-database` | Load database skills | SQL, NoSQL, optimization |
| `/discover-ml` | Load ML/AI skills | Embeddings, RAG, evaluation |
| `/discover-diagrams` | Load diagram skills | Mermaid flowcharts, sequence diagrams |

**Pro tip**: Most of the time you won't need commands! Skills auto-discover based on what you're working on. Use commands when you want explicit control or want to browse.

## How Skills Work

### Two Ways to Access Skills

**1. Auto-Discovery (Recommended)**

Skills automatically activate based on what you're working on:

- Mention "React" → `discover-frontend` skill activates
- Mention "PostgreSQL" → `discover-database` skill activates
- Mention "REST API" → `discover-api` skill activates

**No commands needed.** Just work naturally and skills appear when relevant.

**2. Manual Commands (When You Want Control)**

Use slash commands for explicit control:

- `/discover-frontend` → Manually load frontend skills
- `/skills database` → Browse all database skills
- `/skills postgres` → Search for PostgreSQL-specific skills

**Best for**: Browsing, exploring, or when auto-discovery doesn't trigger.

### Three-Tier Progressive Loading

cc-polymath uses a smart three-tier system to minimize context usage:

**Tier 1: Gateway Skills** (~200 lines each)
- Lightweight entry points
- Auto-discover based on keywords
- Provide quick reference + links
- Example: `discover-frontend` gives you React, Next.js overview

**Tier 2: Category Indexes** (~500 lines each)
- Comprehensive skill listings
- Loaded when browsing or planning
- Show all skills in a domain
- Example: `frontend/INDEX.md` lists all 10 frontend skills

**Tier 3: Individual Skills** (~320 lines average)
- Complete implementation guides
- Loaded on-demand when specifically needed
- Deep technical content
- Example: `rest-api-design.md` has full REST patterns

**Result**: Loading 3-5 gateway skills uses ~2-5K tokens vs 143K tokens if you loaded all 447 skills upfront. That's **98% context savings**.

### Under the Hood

**Skills are "model-invoked"**:
- Claude intelligently decides when to use them based on conversation context
- The skill's `description` field contains keywords that trigger activation
- No manual file loading needed (though commands can do it explicitly)

**Commands execute bash**:
- Slash commands like `/discover-frontend` run bash commands
- They execute `cat ~/.claude/plugins/cc-polymath/skills/discover-frontend/SKILL.md`
- Output loads into Claude's context
- Both auto-discovery and commands work together seamlessly

## What's Covered

cc-polymath provides 447 skills across these domains:

**Core Development**:
- **Frontend** (10): React, Next.js, TypeScript, state management, a11y
- **Backend** (31): Python, Rust, Go, Zig, servers, APIs
- **Mobile** (10): SwiftUI, Swift concurrency, React Native
- **Databases** (11): PostgreSQL, MongoDB, Redis, query optimization
- **Testing** (6): Unit, integration, e2e, TDD, coverage
- **API Design** (7): REST, GraphQL, auth, rate limiting

**Infrastructure & DevOps**:
- **Containers** (5): Docker, Kubernetes, security
- **CI/CD** (4): GitHub Actions, pipelines, automation
- **Observability** (8): Logging, metrics, tracing, alerts
- **Debugging** (14): GDB, LLDB, profiling, memory analysis
- **Build Systems** (8): Make, CMake, Gradle, Maven, Bazel
- **Cloud** (13): AWS, GCP, serverless, edge computing

**Specialized**:
- **ML/AI** (33): Embeddings, RAG, LLM evaluation, model training
- **Mathematics** (19): Linear algebra, calculus, topology, category theory
- **Diagrams** (8): Mermaid flowcharts, sequence, ER, architecture
- **Cryptography**: TLS, certificates, encryption, PKI
- **Protocols**: HTTP, TCP, QUIC, network optimization

**... and 25+ more categories**

## Common Workflows

### Building a Web App

```bash
# Auto-discovers as you work, or load explicitly:
/discover-frontend   # React, Next.js, TypeScript
/discover-api        # REST/GraphQL design
/discover-database   # Database selection
/discover-testing    # Testing strategies
```

### Debugging Performance Issues

```bash
/discover-debugging       # GDB, LLDB, profiling
/discover-observability   # Metrics, tracing, logging
/skills postgres          # If database-related
```

### Working with Data

```bash
/discover-database    # SQL, NoSQL, optimization
/discover-data        # ETL, streaming, pipelines
/discover-caching     # Redis, CDN strategies
```

### Creating Documentation

```bash
/discover-diagrams    # Flowcharts, sequence, ER diagrams
/skills mermaid       # Mermaid-specific patterns
```

### ML/AI Development

```bash
/discover-ml          # Embeddings, RAG, evaluation
/skills llm           # LLM-specific patterns
/skills embeddings    # Vector databases, similarity search
```

## Next Steps

Now that you're set up and familiar with the basics, explore:

### 📚 Learn by Example
- **[FIRST_CONVERSATIONS.md](FIRST_CONVERSATIONS.md)** - See 6 complete example workflows including Next.js dashboards, Postgres optimization, REST APIs, diagrams, database selection, and ML-powered features

### 🔨 Deep Dives
- **[WALKTHROUGHS.md](WALKTHROUGHS.md)** - End-to-end project guides showing how skills compose for complex applications

### 🆘 Troubleshooting
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **Run diagnostics**: `bash ~/.claude/plugins/cc-polymath/scripts/diagnose.sh`

### ❓ Quick Answers
- **[FAQ.md](FAQ.md)** - Frequently asked questions

### 🔍 Explore Skills
```bash
/skills list          # See all 31 categories
/skills [topic]       # Search for specific topics
```

### 📖 Read More
- **[../README.md](../README.md)** - Full project documentation
- **[../PLUGIN.md](../PLUGIN.md)** - Plugin architecture details

## Tips for Success

**🎯 Start Simple**
- Let auto-discovery work first
- Use commands when you want to browse
- Don't overthink it - just work naturally

**🔍 Browse When Curious**
- `/skills list` shows everything available
- `/skills [category]` digs into specific domains
- Gateway skills provide quick overviews

**🚀 Progressive Loading**
- Start with gateway skills (lightweight)
- Load category indexes when planning
- Load individual skills when implementing

**📊 Track Context**
- Gateway skills: ~200 lines (~1K tokens)
- Category indexes: ~500 lines (~2.5K tokens)
- Individual skills: ~320 lines (~1.5K tokens)
- Loading 3-5 skills < most project files

**💡 Combine Skills**
- Skills reference each other naturally
- "API + auth + rate limiting" compose seamlessly
- Follow the links in gateway skills

**🔧 Use Scripts**
- `verify-install.sh` - Check installation
- `diagnose.sh` - Troubleshoot issues
- `demo-skills.sh` - Interactive demonstration

## Understanding the Hybrid Approach

You might wonder: "If skills auto-discover, why have commands?"

**Both approaches serve different needs**:

**Auto-Discovery**:
- ✓ Seamless, zero overhead
- ✓ Skills appear when relevant
- ✓ No need to remember what exists
- ⚠ Might not trigger for edge cases

**Manual Commands**:
- ✓ Explicit control
- ✓ Browsing and exploration
- ✓ Guaranteed to load what you want
- ⚠ Requires knowing what to load

**The Best Workflow**:
1. Start working naturally (let auto-discovery help)
2. Use `/skills [search]` when you want something specific
3. Use `/discover-*` when you want to browse a domain
4. Skills compose naturally regardless of how they're loaded

## What Makes cc-polymath Different

### vs. Loading All Documentation Upfront
- **cc-polymath**: 2-5K tokens for 3-5 gateway skills
- **Traditional**: 143K tokens for all skills
- **Savings**: 98% context reduction

### vs. Manual Skill Files
- **cc-polymath**: Auto-discovery + organization
- **Manual**: Remember what files exist, load manually
- **Benefit**: Discoverability without cognitive overhead

### vs. Monolithic Documentation
- **cc-polymath**: Atomic, composable skills
- **Monolithic**: Load entire domain guide at once
- **Benefit**: Precision loading (only what you need)

## You're Ready!

You now know:
- ✓ How to install and verify cc-polymath
- ✓ Both ways to access skills (auto + manual)
- ✓ The three-tier progressive loading system
- ✓ Common workflows for different domains
- ✓ Where to go for examples and deeper learning

**Start using cc-polymath**:
1. Try `/skills` to see what's recommended for your project
2. Ask Claude a question related to your work
3. Watch skills auto-discover and activate
4. Build something awesome!

**Questions or issues?**
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Run diagnostics: `bash ~/.claude/plugins/cc-polymath/scripts/diagnose.sh`
- See examples: [FIRST_CONVERSATIONS.md](FIRST_CONVERSATIONS.md)
- Report bugs: [GitHub Issues](https://github.com/rand/cc-polymath/issues)

Welcome to cc-polymath - happy coding! 🚀
