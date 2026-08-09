---
name: format-recipe-source
description: "Turn source material into a recipe ready for Tandoor — an Instagram Reel or TikTok link, a PDF, a photo of a cookbook page, or a photo of a handwritten card. Produces name, servings, ingredient lines and steps, then hands off to add-recipe-cleanly. Triggers: 'make a recipe from this reel', 'this tiktok', 'add this recipe from a link', 'get the recipe out of this photo', 'scan this cookbook page', 'here is a handwritten recipe', 'import this recipe pdf'."
---

<!-- plugin: tandoor 0.6.0 -->

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

But *which step* a line belongs to, and *what order* the steps go in, are cooking
decisions — so they are decided here. See "Shape it for the kitchen" below, which
is the part of this skill that most changes how good the result is.

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

**Fetch the thumbnail last, not first.** Instagram's CDN links are signed and
carry a short `oe=` expiry — a URL fetched at the start of a long session is
routinely dead by the time the recipe is created, and the create then succeeds
with no picture. If you fetched the media early and the draft took a while, run
`tandoor_media_fetch` again just before handing off.

## Step 2 — pull out the recipe

Produce:

```
name           short and searchable — "Chicken Katsu Curry", not
               "the BEST katsu curry you'll EVER make 🔥"
servings       a number, or leave it out — see below
steps[]        each with: name, instruction, time, ingredient_lines[]
source_url     webpage_url for a video; the book and page for a scan
image_url      thumbnail from tandoor_media_fetch, when there is one
keywords       existing ones only, e.g. Main / Chicken / Vegetarian
description    ≤512 characters — see "Provenance" below
working_time   active minutes
waiting_time   passive minutes — baking, resting, marinating
```

`description` has a **hard 512-character limit**; it is a database column, not a
preference. That is plenty once provenance is placed properly.

Pass `image_url` straight through: it is downloaded and stored at creation time,
because a stored URL yields a recipe whose picture vanishes with no error.

Keywords are matched against the existing curated tree and unknown ones are
reported rather than created — so prefer the tags already in use.

## Step 3 — shape it for the kitchen

A recipe that mirrors its source is not the same as a recipe that is good to cook
from. Every rule here came from a real import being corrected by the user.

### Ingredients go on the step that uses them

Sources put a full ingredient list above the method. Reproducing that gives you
one wall of thirty-one lines followed by four steps with nothing attached, and
mid-cook you are scrolling back to work out which of three garlic-ish things goes
in now.

Attach each line to the step that consumes it. Where a line is used twice (oil for
frying and oil for brushing), it appears on both, with a note saying which.

### Source ordering is not cooking ordering

Find the **critical path**: the chain of steps where each one waits on the one
before, ending at the food being ready. Everything on it keeps its order.
Everything *not* on it has slack, and belongs in the longest genuinely idle
stretch. A step whose output nothing downstream consumes — a sauce, a dressing, a
garnish, anything served cold alongside — is never on the critical path.

The two ways to get this wrong, both of which happened on the same recipe:

- **Under-correcting.** The Reel put "preheat the oven" fourth, right before
  assembly. Carried through unquestioned, you start preheating ten minutes after
  you needed to.
- **Over-correcting.** Moving the preheat to first and then filling the ten-minute
  window with the seasoning and the sauce, on the reasoning that preheat time is
  dead time. It isn't. The oven was needed at the thirty-minute mark and ready at
  ten — twenty minutes of slack — so filling that window bought nothing. The only
  truly idle stretch was the 10-15 minutes while the tacos baked, and the sauce
  was the only step nothing depended on. That is where it went.

Slack is not idleness. Ask what the *food* is waiting for, not what *you* are.

### One bullet per action

Sources write each step as a paragraph. Convert to one bullet per action, and bold
the times and temperatures. Same words, different shape — and it stays scannable
at arm's length with messy hands.

### Timers

Give each step with a timed operation a `time` in minutes. It renders as a
tappable countdown in Tandoor's cooking mode. Where the source gives a range, use
the **lower bound** and keep the full range in the text: a timer firing at 10 on a
10-15 minute bake prompts the look you would take anyway, where one firing at 15
arrives after the decision point.

### Metric, for an Irish kitchen

Convert US measures — `1 lb` and US cups are not what this user shops or cooks
with. Round to sensible shop amounts (450 g, not 453.6 g). Leave spoons alone,
being locale-neutral. Say in the description that you converted, because cup
conversions for solids are density-dependent approximations, not arithmetic.

### Countables

Use the unit `no.` — `1 no. Yellow Onion`, `10 no. Tortilla`. It is the one
sanctioned unit for counts and it keeps the amount column even. Do not invent a
second one (`piece`, `whole`, `onion`); see `add-recipe-cleanly`.

## Step 4 — do not invent anything

Every source here loses information, and a plausible guess is indistinguishable
from the real thing once it's in the database.

- **Missing quantities:** say which ones and ask. Never interpolate a "typical"
  amount.
- **Servings:** almost never stated in a Reel. Omit rather than estimate — Tandoor
  scales off it, so a wrong number silently corrupts every future scaling and
  shopping-list line.
- **Illegible handwriting:** quote what you can see, mark the gap, ask. `2 oz
  b____r` is a question, not butter.
- **Ambiguous units:** `T` vs `t` is a fourfold error and handwriting rarely
  disambiguates. So is a bare `oz` on a wet ingredient — fluid or weight. Ask.
- **US vs metric cups** differ by about 5%, and an American `pint` is 473 ml
  against an Irish 568 ml.
- **Times:** only where the source states them. A guessed time reads as a real one.

### Provenance — global in the description, local on the step

Keep the two apart, or the 512 characters get tight and the useful detail ends up
somewhere nobody reads it while cooking.

- **Global**, in `description`: what the source was, that amounts were converted
  to metric, that servings were inferred.
- **Local**, as an italic line at the end of that step's instruction: this step's
  timing was inferred, this quantity is a density approximation, this step was
  moved from where the source had it.

The reader meets a local note at the moment it matters:

> *Nothing else depends on this, which is why it sits in the bake window. The
> creator lists it but never says when to make it.*

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
marks or "a moderate oven". Convert, and say so. Older recipes also assume
knowledge — "cook until done" is a real instruction and should be kept verbatim
rather than elaborated into something the author didn't write.

**PDFs** often hold several recipes. Ask which one rather than importing the
first, and never silently merge two.

## Step 5 — show it, then hand off

Show the draft before anything is written. It's the only checkpoint where a
misread quantity is cheap to fix.

Show your **ordering reasoning** with it — one line naming the critical path and
where the off-path steps went. That decision departs from the source, so it is the
one the user most needs the chance to overrule.

Then invoke `add-recipe-cleanly` with the draft, passing `source_url` through so
the recipe keeps its provenance.
