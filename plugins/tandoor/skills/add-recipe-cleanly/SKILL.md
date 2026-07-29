---
name: add-recipe-cleanly
description: "Create a recipe in Tandoor without polluting the food vocabulary. Creating a recipe silently get-or-creates a Food and a Unit for every ingredient name, so careless names permanently add junk entries. Covers checking for existing foods first, naming conventions, and what belongs in the note field. Triggers: 'add a recipe', 'create a recipe in tandoor', 'save this recipe', 'import this recipe'."
---

# Skill: add-recipe-cleanly

Requires the `tandoor-admins` group. If `tandoor_recipe_create` isn't in your
tool list, say so and stop.

## Why this needs care

`tandoor_recipe_create` **get-or-creates a Food and a Unit for every ingredient
name you pass**. There is no confirmation step. Pass `2 cloves garlic` as a food
name and you permanently add a food called `2 cloves garlic` sitting alongside
the real `Garlic`.

This is how a curated vocabulary degrades — not through bulk imports, which get
reviewed, but through one-off recipe additions that nobody checks afterwards.

## Step 1 — resolve every ingredient against what exists

Before creating anything, run `tandoor_food_search` for each ingredient and reuse
the existing food where there is one. Search on the **head noun**, not the full
phrase: searching `garlic` finds `Garlic`; searching `2 cloves garlic, minced`
finds nothing and tempts you into creating it.

Do the same for units. If the recipe says `tbsp` and the instance already uses
`tablespoon`, use the existing one.

## Step 2 — split each ingredient line into its parts

An ingredient is **amount + unit + food + note**. Everything that isn't a
measurement or the ingredient itself belongs in the note:

| Source line | amount | unit | food | note |
|---|---|---|---|---|
| `2 cloves garlic, minced` | 2 | clove | Garlic | minced |
| `1 tbsp butter, melted` | 1 | tablespoon | Butter | melted |
| `2 Tbsp butter ($0.22)` | 2 | tablespoon | Butter | $0.22 |
| `salt, to taste` | — | — | Salt | to taste |
| `20–30 g Parmesan` | 20 | g | Parmesan Cheese | 20–30 g |

Preparation words (`chopped`, `minced`, `grated`, `melted`), costs, and ranges
all go in the note. None of them belong in a food name.

**Section headings are not ingredients.** A source line like `For the sauce:` or
`To serve` is a group heading, not something to create a food for.

## Step 3 — name any genuinely new food correctly

Only create a food when the search genuinely found nothing. Then:

- **Natural English word order** — `Dried Basil`, not `Basil dried`.
- **Title Case**, singular unless it's a mass noun (`Oats` stays plural).
- **No quantities, bullets, prose or trailing punctuation** in the name.
- Add a **supermarket aisle** if you can, or the food drops out of aisle-grouped
  shopping lists.

## Step 4 — check afterwards

After creating, `tandoor_food_search` for anything suspicious — names containing
digits, starting with punctuation, or longer than a few words. Those are the
signature of a mis-split ingredient line, and they are much cheaper to fix now
than after they have spread across other recipes.
