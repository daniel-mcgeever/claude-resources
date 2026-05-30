{
  "permissions": {
    "defaultMode": "default",
    "additionalDirectories": [
      "/home/daniel/projects/{{SLUG}}"
    ],
    "allow": [
      "Bash(git *)",
      "Bash(docker *)",
      "Bash(docker compose *)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'INPUT=$(cat); if echo \"$INPUT\" | grep -qE \"rm -rf|git reset --hard\"; then echo \"[gate] Destructive command detected — confirm? (y/n):\"; read ans </dev/tty; [ \"$ans\" = \"y\" ] || exit 1; fi; echo \"$INPUT\"'"
          }
        ]
      }
    ]
  }
}
