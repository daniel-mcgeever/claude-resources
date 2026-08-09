---
name: canonicalise-food-vocabulary
description: "Find and merge duplicate foods in Tandoor without losing data or reintroducing the mess. Covers how to spot duplicates, which name survives, why merge direction matters, and pairing every merge with a FOOD_ALIAS so the next import doesn't recreate it. Triggers: 'duplicate foods', 'clean up the food list', 'merge foods', 'the vocabulary is messy', 'onion vs onions', 'canonicalise ingredients'."
---

<!-- plugin: tandoor 0.6.0 -->

# Skill: canonicalise-food-vocabulary

Merging is **destructive**. `tandoor_food_merge` deletes the source food outright
and re-points every ingredient that referenced it. There is no undo through the
API. Everything below exists to stop a well-meant cleanup from doing damage.

Requires the `tandoor-admins` group. If `tandoor_food_merge` isn't in your tool
list, say so and stop — do not attempt a workaround.

## The rule that matters most

**Propose the full list, get explicit approval, then apply.** Never merge as you
go. A batch that looks obvious in isolation is exactly where the wrong direction
slips through, and you cannot walk it back.

## Step 1 — pull the vocabulary

`tandoor_food_search` with an empty query returns everything, each with its id,
name and supermarket aisle. Work from the whole list; sampling hides the
duplicates that matter.

## Step 2 — cluster candidates

Group names that mean the same ingredient. Normalise before comparing:

- **Singularise first.** `Potatoes` and `Potato` only cluster if you strip the
  plural — a naive substring match misses every plural pair.
- **Ignore case and punctuation.** `Parmigiano-Reggiano` and `Parmigiano Reggiano`
  are the same thing.
- **Strip leading quantities and stray characters.** `(100g) granulated sugar`,
  `• Granulated sugar` and `Granulated Sugar` are one food.
- **Strip trailing prose.** `lemon juice - freshly squeezed` is just lemon juice.
- **Watch for descriptor-only differences.** `freshly grated parmesan`,
  `shredded parmesan cheese` and `Parmesan Cheese` all collapse — a word-set
  comparison misses these because the extra words differ.

## Step 3 — choose the surviving name, carefully

This is where merges go wrong. The survivor should be:

- **Natural English word order** — `Dried Basil`, never `Basil dried`. Likewise
  `Balsamic Vinegar`, `Butternut Squash`, `Red Onion`, `Whole Milk`,
  `Unsalted Butter`, `Red Wine Vinegar`.
- **Title Case**, with no bullets, quantities or prose in the name.
- **Not singularised if it's a mass noun.** `Oats` stays `Oats`.
- **Hyphenated only if the established name already is.** Don't invent one.

Two traps worth stating outright:

- **Keep deliberate qualifiers.** `Egg (Large)` and `Egg (Medium)` are separate
  on purpose. `Peanut Butter (Creamy)` keeps its qualifier. Merging these
  destroys a distinction someone made intentionally.
- **Compound nouns are not reversals.** `Egg White` is correct English — it is
  not a mis-ordered `White Egg`. Reorder only when the trailing word is genuinely
  a modifier.

Where a cluster contains an established, well-formed food and some import
artifacts, **merge the artifacts into the established one** — it carries the
supermarket aisle and any properties already set. Then rename the survivor if its
own name needs correcting.

## Step 4 — apply, then immediately alias

For each approved pair, `tandoor_food_merge(source_id, target_id)`.

Then, for **every** merged-away name, create an alias so a future import maps it
to the canonical food instead of recreating the duplicate:

```
tandoor_automation_create(type="FOOD_ALIAS", param_1="<the old name>", param_2="<canonical name>")
```

Skipping this is the single most common way a cleanup undoes itself — the next
import silently rebuilds everything you just merged.

## Step 5 — check what you left behind

After merging, look for foods that are now unused and were only ever parse
artifacts. **Check before deleting**: a name that looks like a fragment may still
be attached to an ingredient, and deleting it breaks that recipe. If it's still
in use it needs repairing, not removing.

Also confirm every surviving food still has a supermarket aisle — a food without
one drops silently out of aisle-grouped shopping lists.

## Related

Units suffer the same problem (`tbsp` / `Tbsp` / `tablespoons`), and the parser
will sometimes treat a word like `garlic` or `bay` as a unit. Those need
`NEVER_UNIT` automations rather than food merges.
