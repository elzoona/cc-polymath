#!/usr/bin/env bash
# demo-skills.sh - Interactive demonstration of key cc-polymath skills
#
# Usage: bash ~/.claude/plugins/cc-polymath/scripts/demo-skills.sh
#
# This script provides an interactive walkthrough showcasing 5 key skills
# to help new users understand what cc-polymath offers. All operations
# are read-only (no modifications to your system).

set -e

PLUGIN_DIR="$HOME/.claude/plugins/cc-polymath"

# Check if plugin is installed
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Error: cc-polymath plugin not found at $PLUGIN_DIR"
    echo ""
    echo "Install with: /plugin marketplace add rand/cc-polymath
/plugin install cc-polymath@cc-polymath"
    exit 1
fi

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cc-polymath Interactive Demo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This demo showcases 5 key skills to get you started."
echo "Each demo is read-only and safe to run."
echo ""
echo "Press ENTER to continue..."
read -r

# Demo 1: Gateway Skill
clear
echo "━━━ Demo 1/5: Gateway Skills ━━━"
echo ""
echo "Gateway skills are lightweight entry points that auto-discover"
echo "based on keywords in your prompts."
echo ""
echo "Let's preview the 'discover-frontend' gateway skill:"
echo ""
echo "────────────────────────────────────────────────────"
if [ -f "$PLUGIN_DIR/skills/discover-frontend/SKILL.md" ]; then
    head -20 "$PLUGIN_DIR/skills/discover-frontend/SKILL.md"
else
    echo "Error: discover-frontend/SKILL.md not found"
fi
echo "────────────────────────────────────────────────────"
echo ""
echo "This gateway triggers when you mention: React, Next.js, TypeScript"
echo ""
echo "To load it manually:"
echo "  /discover-frontend"
echo ""
echo "Or it auto-discovers when you ask about frontend topics!"
echo ""
echo "Press ENTER to continue..."
read -r

# Demo 2: Practical Skill
clear
echo "━━━ Demo 2/5: Visual Documentation ━━━"
echo ""
echo "The 'mermaid-flowcharts' skill helps you create diagrams quickly."
echo ""
echo "Preview:"
echo ""
echo "────────────────────────────────────────────────────"
if [ -f "$PLUGIN_DIR/skills/diagrams/mermaid-flowcharts.md" ]; then
    head -25 "$PLUGIN_DIR/skills/diagrams/mermaid-flowcharts.md"
else
    echo "Error: mermaid-flowcharts.md not found"
fi
echo "────────────────────────────────────────────────────"
echo ""
echo "Try it yourself:"
echo "  Ask Claude: 'Create a flowchart showing user authentication flow'"
echo ""
echo "You'll get a professional Mermaid diagram in seconds!"
echo ""
echo "Press ENTER to continue..."
read -r

# Demo 3: Decision-Making Skill
clear
echo "━━━ Demo 3/5: Database Selection ━━━"
echo ""
echo "The 'database-selection' skill helps you choose the right database."
echo ""
echo "Preview:"
echo ""
echo "────────────────────────────────────────────────────"
if [ -f "$PLUGIN_DIR/skills/database/database-selection.md" ]; then
    head -20 "$PLUGIN_DIR/skills/database/database-selection.md"
else
    echo "Error: database-selection.md not found"
fi
echo "────────────────────────────────────────────────────"
echo ""
echo "This skill provides decision frameworks for:"
echo "  • SQL vs NoSQL"
echo "  • PostgreSQL vs MongoDB vs Redis"
echo "  • When to use each database type"
echo ""
echo "To use it:"
echo "  1. Auto-discover: Ask 'Which database should I use for...?'"
echo "  2. Manual load: /discover-database"
echo ""
echo "Press ENTER to continue..."
read -r

# Demo 4: Design Skill
clear
echo "━━━ Demo 4/5: REST API Design ━━━"
echo ""
echo "The 'rest-api-design' skill teaches API best practices."
echo ""
echo "Preview:"
echo ""
echo "────────────────────────────────────────────────────"
if [ -f "$PLUGIN_DIR/skills/api/rest-api-design.md" ]; then
    head -20 "$PLUGIN_DIR/skills/api/rest-api-design.md"
else
    echo "Error: rest-api-design.md not found"
fi
echo "────────────────────────────────────────────────────"
echo ""
echo "Covers:"
echo "  • Resource modeling"
echo "  • HTTP verbs and status codes"
echo "  • Pagination, filtering, sorting"
echo "  • Versioning strategies"
echo ""
echo "To use it:"
echo "  1. Auto-discover: Ask 'Help me design a REST API for...'"
echo "  2. Manual load: /discover-api"
echo ""
echo "Press ENTER to continue..."
read -r

# Demo 5: Discovery Command
clear
echo "━━━ Demo 5/5: Skills Discovery ━━━"
echo ""
echo "The /skills command helps you discover relevant skills."
echo ""
echo "Usage examples:"
echo "  /skills              - See project-specific recommendations"
echo "  /skills api          - Browse API skills"
echo "  /skills postgres     - Search for 'postgres'"
echo "  /skills list         - Show all categories"
echo ""
echo "Let's see what gateway categories are available:"
echo ""
echo "────────────────────────────────────────────────────"
if [ -d "$PLUGIN_DIR/skills" ]; then
    gateway_count=0
    for dir in "$PLUGIN_DIR/skills"/discover-*; do
        if [ -d "$dir" ]; then
            gateway=$(basename "$dir" | sed 's/discover-//')
            echo "  • $gateway"
            ((gateway_count++))
            if [ $gateway_count -ge 20 ]; then
                echo "  ... and more"
                break
            fi
        fi
    done
else
    echo "Error: skills/ directory not found"
fi
echo "────────────────────────────────────────────────────"
echo ""
echo "Press ENTER to finish..."
read -r

# Summary
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Demo Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You've seen:"
echo "  1. Gateway skills (auto-discovery)"
echo "  2. Visual documentation (Mermaid diagrams)"
echo "  3. Decision-making (database selection)"
echo "  4. Design patterns (REST APIs)"
echo "  5. Discovery tools (/skills command)"
echo ""
echo "Next steps:"
echo "  • Try /skills in Claude Code"
echo "  • Read: $PLUGIN_DIR/docs/GETTING_STARTED.md"
echo "  • Examples: $PLUGIN_DIR/docs/FIRST_CONVERSATIONS.md"
echo ""
echo "Explore 447 skills across 31 categories!"
echo ""
echo "Happy coding! 🚀"
