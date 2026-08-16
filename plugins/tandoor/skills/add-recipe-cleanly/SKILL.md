---
name: add-recipe-cleanly
description: "Create a recipe in Tandoor without polluting the food vocabulary. Creating a recipe silently get-or-creates a Food and a Unit for every ingredient name, so careless names permanently add junk entries. Covers checking for existing foods first, naming conventions, and what belongs in the note field. Triggers: 'add a recipe', 'create a recipe in tandoor', 'save this recipe', 'import this recipe'."
---

<!-- plugin: tandoor 0.7.0 -->

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

Resolve a whole recipe in **one call** with `queries`:
`tandoor_food_search(queries: ["garlic", "onion", "smoked paprika"])` returns
`{matches: {query: [...]}}`. One fetch beats one round trip per ingredient.

`tandoor_food_search` reports a total `count`, and sets `truncated` with a
`next_offset` when there is more. **Do not treat a truncated page as the whole
vocabulary** — a slice that happens to end at `Yogurt` looks complete, and
believing it means creating a duplicate of everything past the cutoff.

Do the same for units with `tandoor_unit_search`. If the recipe says `tbsp` and
the instance already uses `tablespoon`, use the existing one.

**Units rot the same way foods do, and the damage is quieter.** They are
get-or-created from ingredient names with no confirmation, they have no aisle to
make a new one look obviously unfinished, and a duplicate silently loses
conversion. Check `base_unit`: `lb` carries base_unit `pound` and converts, so
creating a separate `pound` produces a unit that converts to nothing. This is not
hypothetical — `tablespoon` and `teaspoon` existed for a long time beside `tbsp`
and `tsp`, carrying no `base_unit` between them, and 146 ingredient rows across
the library converted to nothing as a result.

`tandoor_unit_merge` fixes duplicates — merge **into** the one that has a
`base_unit`, since that is the one that converts. It repoints every ingredient
before deleting the source, so it repairs the recipes as it goes. It is
destructive and there is no undo, so confirm the direction first.

**Counting is a unit: `no.`** — `1 no. Yellow Onion`, `10 no. Tortilla`. It is the
single sanctioned unit for countable items. It keeps the amount column even and
it does not pluralise awkwardly.

That is not a licence to invent units. The rule is: **one convention, applied
everywhere.** `piece`, `whole`, `onion`, `jalapeno` as units are the pollution
this skill exists to prevent, and half a library one way and half the other is
worse than either alone. `no.` is the exception because it is established and
named here; nothing else is.

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
- Add a **supermarket aisle** by passing it on the food itself —
  `{"name": "Hot Sauce", "aisle": "Condiments and Sauces"}`. Without one the food
  drops out of aisle-grouped shopping lists. It is applied only to foods this call
  actually creates, so an existing curated aisle is never overwritten — to
  categorise a food that already exists, use `tandoor_food_update`.
  **Take the aisle name verbatim from `tandoor_aisle_search`.** Aisles are never
  created on demand: an unrecognised one is reported, not accepted, so a typo'd
  `Condiments & Sauces` cannot quietly become a second aisle.

## Tagging and timing

Pass `keywords` as existing names from `tandoor_keyword_search` — unknown ones are
reported rather than created, because the tree is a curated three-parent structure
(`Course`, `Main Ingredient`, `Occasion`) and a typo would grow a fourth root.
Never harvest tag names off unrelated recipes; that is the same bad proxy that
produced a duplicate unit.

Set `working_time` and `waiting_time` only when the source states them. A guessed
time is indistinguishable from a real one once stored.

## Step 4 — check afterwards

`tandoor_recipe_create` returns a **`created: {foods, units}`** block naming
exactly what it added to the vocabulary, and `aisles` saying which aisles were
set. Read it. That is the whole check — you do not need to infer newness from null
aisles or high ids.

If `created` is non-empty, confirm each addition was genuinely intended and that
none is a near-duplicate of something that already existed under a different
spelling. `created.units` deserves the closer look, for the reasons in step 1.

## Payload shape

`food` and `unit` accept a bare string or `{"name": ...}`; omit either where the
line genuinely has none. Omitted `amount` is 0, and fractions may be `"1/2"` or
`0.5`. A section heading is `is_header: true` with its text in `note` and no food.

Where a section maps cleanly onto a step, prefer **`steps[].name`** (`"For the
chicken"`) over a header ingredient row — it is the same information without a
fake ingredient carrying it.

**Never reshape real data to satisfy the API.** If something is rejected, the fix
is in the payload, never in the recipe: don't drop a section header to avoid an
error, and above all don't invent a unit like `piece` for a line that has none —
that is exactly the pollution this skill exists to prevent. Rejections name the
offending ingredient, so fix that line and resend.

## Revising a recipe — never delete and recreate

Iterating on a recipe with someone is the normal case. The first import is rarely
the final one, and **`tandoor_recipe_update` edits in place, steps included.**

```
tandoor_recipe_get(id) → edit the steps array → tandoor_recipe_update(id, steps=[…])
```

`tandoor_recipe_get` returns steps in exactly the shape `tandoor_recipe_update`
accepts — `step_id`, `name`, `time`, `order`, `show_ingredients_table`,
`instruction`, `ingredients` — so it is a closed loop. Read it, change what's
wrong, send it back.

**Keep `step_id` on every step.** Steps are matched by it: one carrying its id is
edited in place, one without it is deleted and re-created. Both produce the right
recipe, so the difference is invisible in the response — but re-creation renumbers
every step and resets step columns the payload does not mention. That is how
`show_ingredients_table` reverts to `true` after each rewrite, putting a duplicate
ingredient table back beside instructions that already carry their quantities.

Delete-and-recreate is the wrong instinct and it is expensive: it churns the
recipe id (breaking meal plans, shopping lists and bookmarks), strands orphaned
`cookbook_step` rows, and costs a re-fetched thumbnail plus re-applied keywords
every cycle. One session did it five times for changes that were each a sentence.

**`steps` is the complete new list.** Anything omitted is deleted — so fetch first
and edit the array you got back, never assemble a partial one. The response
reports `steps: {before, after}`, and if the count shrank it warns and hands back
the text of what was removed, so the mistake is recoverable by resending.

Also available:

- `tandoor_food_update` / `tandoor_unit_update` — rename, fix a plural, set an
  aisle, or give a unit the `base_unit` that makes it convert. **Merging is not
  editing**: merge folds a record into another that is already correct; these make
  a record correct.
  Renaming onto a name that already exists is a collision, not an edit — food and
  unit names are unique per space. `tandoor_food_update` catches it and names the
  id to merge into, because the answer is almost always that the two are duplicates
  and the rename was the wrong operation. A rename target with zero uses is
  invisible in every recipe but still occupies the name.
- `tandoor_recipe_delete` — for a recipe that is *unwanted*. One that is merely
  wrong is fixed above. Destructive, no trash.

## The guard, and when `force` is the answer

Names that look like un-split ingredient lines are refused before anything is
written. The guard consults the vocabulary first, so a name that **already
exists** is never refused — it comes back under `warnings` as a cleanup candidate
instead. Nothing is blocked, and nothing new is created.

So `force: true` is only ever for a genuinely new name you are sure about. It
switches the check off for the **whole payload**, which means reaching for it to
get one established name through would also disable it for the parsing accidents
sitting alongside.

## Field limits worth knowing

`description` is capped at **512 characters** — a database column, not a
preference. Keep global provenance there (what the source was, that amounts were
converted, that servings were inferred) and put step-specific provenance in that
step's instruction as an italic line. `format-recipe-source` has the split.
