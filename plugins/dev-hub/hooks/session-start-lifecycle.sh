#!/usr/bin/env bash
# Advisory SessionStart pointer — surfaces the claude-resources lifecycle so an
# agent knows it exists before it branches. Plain stdout becomes session context.
cat <<'EOF'
dev-hub plugin — this project follows the claude-resources lifecycle. If your
work will touch the dev-hub plugin or its skills/commands, invoke the
`project-lifecycle` skill BEFORE creating a branch. Key rules: backend capability
ships to prod before the plugin; "merge to main" is not "published"; use matching
branch names across the app and claude-resources repos.
EOF
