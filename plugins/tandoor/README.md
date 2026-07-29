# tandoor

Tandoor Recipes for Claude Code — recipe, meal-planning and shopping-list tools,
plus an agent that understands the curated food-vocabulary conventions.

## What you get

- **`tandoor` MCP server** at `https://mcp.towneygorm.cc/tandoor`, authenticated
  through Authentik. Nothing is pasted — the gateway implements Dynamic Client
  Registration, so signing in happens in a browser on first use.
- **`tandoor-agent`**, which knows the vocabulary rules (natural word order,
  Title Case, preserved qualifiers) and treats food merges as destructive
  operations that need approval first.
- **Recipe capture from any source** — paste an Instagram Reel or TikTok link, a
  PDF, a photo of a cookbook page, or a photo of a handwritten card, and
  `format-recipe-source` turns it into a draft that `add-recipe-cleanly` files
  without polluting the food vocabulary.

## Install

```
/plugin marketplace add daniel-mcgeever/claude-resources
/plugin install tandoor
```

On first tool call a browser opens for Authentik sign-in. After that the session
refreshes silently.

## Access tiers

Your Authentik group membership decides which tools appear. The tool list is
filtered per user, so a missing tool means "not authorised", not "broken".

| Group | Tools |
|---|---|
| `tandoor-users` | `food_search`, `recipe_search`, `recipe_get`, `shopping_list`, `media_fetch` |
| `tandoor-admins` | the above plus `food_merge`, `automation_create`, `recipe_create` |

Membership of `mcp-users` is required to reach the gateway at all — it is the
single kill-switch across every MCP behind it.

## Notes

- This is a **Claude Code** plugin. Claude Desktop reaches the same server by
  adding `https://mcp.towneygorm.cc/tandoor` as a custom connector instead.
- `food_merge` deletes the source food and re-points its ingredients. There is
  no undo through the API.
- Server source lives in a separate private repo (`daniel/tandoor-mcp`); this
  plugin only carries the client-side configuration and the agent.
