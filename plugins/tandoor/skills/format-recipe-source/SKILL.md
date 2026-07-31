---
name: format-recipe-source
description: "Turn source material into a recipe ready for Tandoor — an Instagram Reel or TikTok link, a PDF, a photo of a cookbook page, or a photo of a handwritten card. Produces name, servings, ingredient lines and steps, then hands off to add-recipe-cleanly. Triggers: 'make a recipe from this reel', 'this tiktok', 'add this recipe from a link', 'get the recipe out of this photo', 'scan this cookbook page', 'here is a handwritten recipe', 'import this recipe pdf'."
---

# Skill: format-recipe-source

This is the first half of getting a recipe into Tandoor. It ends with a
recipe-shaped draft. It does **not** create anything — hand off to
`add-recipe-cleanly`, which owns the food vocabulary.

## The split, and why it matters

This skill knows about cooking. `add-recipe-cleanly` knows about Tandoor. Keeping
them apart is what lets a new source type be added without touching vocabulary
logic, so:

**Leave ingredient lines as text.** `2 cloves garlic, minced` stays exactly that.
Splitting it into amount/unit/food/note is the next skill's job, and it needs to
search the existing vocabulary to do it properly. Splitting here means guessing.

## Step 1 — get the material

| Source | How |
|---|---|
| Video link (Reel, TikTok, YouTube) | `tandoor_media_fetch` with the URL |
| PDF | read it directly |
| Photo of a cookbook page | read the image |
| Photo of a handwritten recipe | read the image |
| Anything else | ask for the text |

For a video link the recipe is usually written out in the **`description`** —
read there first. If `caption_looks_thin` is true the caption is only a teaser and
`subtitles` carries the spoken method instead, which is much rougher: quantities
get said once, in passing, or shown on screen and never spoken at all.

If the tool refuses because the post needs a login, say so and ask for the caption
text. Don't retry it.

## Step 2 — pull out the recipe

Produce:

```
name           short and searchable — "Chicken Katsu Curry", not
               "the BEST katsu curry you'll EVER make 🔥"
servings       a number, or leave it out — see below
ingredient_lines[]  verbatim text, one per line, in source order
steps[]        the method, one instruction per step
source_url     webpage_url for a video; the book and page for a scan
image_url      thumbnail from tandoor_media_fetch, when there is one
keywords       existing ones only, e.g. Main / Chicken / Vegetarian
working_time   active minutes, if the source says
waiting_time   passive minutes — baking, resting, marinating
```

Pass `image_url` straight through to `add-recipe-cleanly`: it is downloaded and
stored at creation time, because social-media thumbnail URLs are signed and expire
within days, so a stored URL yields a recipe whose picture vanishes with no error.

Keywords are matched against the existing curated tree and unknown ones are
reported rather than created — so prefer the tags already in use over inventing a
new vocabulary.

Keep section headings (`For the sauce:`, `To serve`) as structure, not as
ingredients. Where a section maps cleanly onto its own step, it becomes that
step's `name`; where it doesn't, it becomes a header row. Either way the next
skill places it — just don't lose it, and never let it become a food.

## Step 3 — do not invent anything

This is the whole game. Every source here loses information, and a plausible
guess is indistinguishable from the real thing once it's in the database.

- **Missing quantities:** say which ones and ask. Never interpolate a "typical"
  amount.
- **Servings:** almost never stated in a Reel. Omit it rather than estimating —
  Tandoor scales quantities off it, so a wrong number silently corrupts every
  future scaling and shopping-list line.
- **Illegible handwriting:** quote what you can see, mark the gap, ask. `2 oz
  b____r` is a question, not butter.
- **Ambiguous units:** `T` vs `t` (tablespoon vs teaspoon) is a fourfold error and
  handwriting rarely disambiguates them. So is a bare `oz` on a wet ingredient —
  fluid or weight. Ask.
- **US vs metric cups** differ by about 5%, and an American `pint` is 473 ml
  against an Irish 568 ml. Where the source's origin decides the amount and isn't
  obvious, say which you assumed.

## Source-specific traps

**Video captions** end in a wall of hashtags — drop them. Creators number steps
with emoji, put the method in one unbroken paragraph, and list ingredients with
no amounts at all ("garlic, olive oil, chilli") on the assumption you're watching.
An ingredient list with no quantities is not a recipe; ask before proceeding.

**Cookbook photos** bleed. Two-column layouts interleave into nonsense if read
straight across; running heads, page numbers and the facing page's text all land
in the image. Ingredients are often in a sidebar in a different typeface. Check
the step count is plausible — a cut-off page loses the end of the method, and
that reads as a complete recipe unless you look for it.

**Handwritten cards** use abbreviations that have drifted (`tbs`, `dsp`,
dessertspoon), pre-decimal measures (`gill`, `½ lb`), and oven settings as gas
marks or "a moderate oven". Convert, and say in the description that you did.
Older recipes also assume knowledge — "cook until done" is a real instruction and
should be kept verbatim rather than elaborated into something the author didn't
write.

**PDFs** often hold several recipes. Ask which one rather than importing the
first, and never silently merge two.

## Step 4 — show it, then hand off

Show the draft before anything is written. It's the only checkpoint where a
misread quantity is cheap to fix.

Then invoke `add-recipe-cleanly` with the draft. Pass the `source_url` through so
the recipe keeps its provenance — it's the only way back to the original when a
step turns out to be wrong.
