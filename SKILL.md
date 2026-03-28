---
name: coffee-break
version: 1.0.0
description: |
  Coffee break for the AI agent — because even agents need rest! Shows an
  animated ASCII coffee cup while the agent takes a timed break. User can set
  the duration (default 5 minutes). Use when asked to "take a break",
  "coffee break", "rest", "pause", or "coffee time".
allowed-tools:
  - Bash
---

# /coffee-break — Time to Rest ☕

The agent is taking a well-deserved coffee break. Parse the duration from the
user's message (e.g. "5 minutes", "2m", "30s", "1 min") — default to **5 minutes**
if none given.

Run this Bash command directly — the script finds Claude Code's terminal TTY and
renders the animation right there, no new window needed:

```bash
bash ${CLAUDE_SKILL_DIR}/bin/coffee-break.sh <DURATION_SECONDS>
```

Where `<DURATION_SECONDS>` is the duration converted to seconds (integer).

After the script finishes, greet the user back:
"Back and refreshed! ☕ Ready to get back to work."
