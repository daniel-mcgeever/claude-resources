---
name: format-recipe-source
description: "Turn source material into a recipe ready for Tandoor — an Instagram Reel or TikTok link, a PDF, a photo of a cookbook page, or a photo of a handwritten card. Produces name, servings, ingredient lines and steps, then hands off to add-recipe-cleanly. Triggers: 'make a recipe from this reel', 'this tiktok', 'add this recipe from a link', 'get the recipe out of this photo', 'scan this cookbook page', 'here is a handwritten recipe', 'import this recipe pdf'."
---

<!-- plugin: tandoor 0.8.0 -->

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
description    a short blurb about the dish, ≤512 chars — or nothing at all
working_time   active minutes
waiting_time   passive minutes — baking, resting, marinating
```

`description` has a **hard 512-character limit**; it is a database column, not a
preference. It describes the dish, not the work of importing it — see "A recipe is
a cooking document, not a changelog" below.

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

### Knife work is a step, not a note

Write these recipes as an experienced cook would: nobody heats a pan and *then*
starts jointing chicken. But the rule above — attach each line to the step that
uses it — quietly encourages exactly that, because preparation ends up in the
ingredient's `note`, where it is only discovered once the pan is already hot.

Keep the note as the **specification** (`diced into 1 cm pieces`) — that is what
scaling and shopping need. Put the **action** on the timeline, in plain words with
no quantities. The master ingredient list is on screen the whole time; the prep
step does not need to restate amounts.

Where it goes is the same critical-path question, asked about a step that was
never being counted:

- **No usable window** — a wok, a stir-fry, a risotto, any fast run of additions.
  All knife work goes into a prep step **before any heat**. In a fried rice every
  stage is 1-3 minutes back to back; there is no moment in there to dice a carrot,
  and trying is how the garlic burns.
- **A real unattended window exists** — a 20-minute simmer, a 25-minute roast.
  Prep for later steps belongs **inside** that window, said out loud: *"While that
  simmers, chop the parsley and grate the parmesan."*

The second case matters as much as the first. A blanket "prep everything first"
step is its own mistake — it front-loads twenty minutes of chopping onto a recipe
with a 25-minute roast you could have chopped during, and leaves you standing at a
cold hob. That is the taco preheat error again, pointing the other way.

Judge prep like any other step: does the food need it done before the next thing
starts, and is there anywhere else it could genuinely fit?

### Every step opens with a headline

The first line is a single sentence that says what this step *is*, bolded. It is
the only line someone reads when they glance up mid-cook, so it has to stand alone:

> **Fry the chorizo in oil, set some aside for garnish.**

Detail goes underneath, one bullet per action, short enough to take in at a glance.
Not a sentence carrying three ideas — "Add one ladle of hot stock. Stir until
absorbed." beats a clause about maintaining a gentle simmer while stirring.

### Three step shapes, chosen by how you cook the step

| The step is | Shape | Timer |
|---|---|---|
| prep, stovetop, anything you stand over | **A** | no |
| hands-on, three or more things going in at once | **C** | no |
| oven, airfryer, unwatched pot, proving, marinating | **E** | yes |

This is one decision, not two: **if it needs a timer it is shape E.** A timer is
for time you walk away from. A pan you are standing at gets its minutes bolded in
the text and no countdown, because you are already watching it. A risotto has none.

**A — headline, then bullets**

```
**Fry the chorizo in a dry pot, set some aside for garnish.**

- Casing off first — it never softens.
- Medium heat until crisp and the red oil runs.
- Lift out; **leave all the oil in the pot**.
```

**C — headline, then what goes in**

```
**Stir in the peas, parmesan and the last of the stock.**

**In:**

- {{ ingredients[0] }}
- {{ ingredients[1] }}
```

**E — headline, then the settings you walk away from**

```
**Everything into the pot, then leave it to simmer.**

**In:** …
**Heat:** gentle simmer
**Time:** **20 min**
**Done when:** the sweet potato crushes against the side of the pot.
```

`Done when:` is worth its own line on any long step — a doneness cue is what you
are actually checking against, and it is different information from an instruction.

Set `show_ingredients_table: false` on every step written this way. The quantities
are already in the text; the table repeats them.

### Never hard-code a quantity

Step instructions are Jinja2 templates rendered against **that step's own**
ingredients. A literal `**200 g**` does not scale — double the servings and the
text still says 200 g while the ingredient list says 400. It is a number that
quietly lies.

| Write | Renders |
|---|---|
| `{{ ingredients[0] }}` | `200 g Chorizo`, scaled and pluralised |
| `{{ ingredients[0].food }}` | just the name |
| `{{ scale(150) }}` | any other number, scaled |

Indexes count that step's ingredients from 0, in the order you send them — so
reordering a step's ingredients shifts every reference in its text. An out-of-range
index renders as an **empty string with no error**; `tandoor_recipe_create` and
`tandoor_recipe_update` refuse those before writing, which is the only reason they
are catchable at all.

**Times and temperatures are the exception.** Doubling a recipe does not double the
bake, so write `**20 min**` and `**220C**` plainly and never wrap them in `scale()`.

Where the source gives a time range, put the **lower bound** in `time` and keep the
range in the text: a timer firing at 10 on a 10-15 minute bake prompts the look you
would take anyway, where one firing at 15 arrives after the decision point.

### Markdown that does not render

Four things look like they should work and silently do not, because Tandoor's
sanitiser escapes `>` before the markdown parser runs and no extension is loaded
for the rest:

- **blockquotes** — `> note` renders as literal text
- **task lists** — `- [ ]` stays literal
- **strikethrough**, **subscript**, **superscript**

Available: headers, bold, italic, `code`, fenced blocks, tables, `---`, nested
lists, images, auto-linked URLs. A single newline becomes a line break.

### Metric, for an Irish kitchen

Convert US measures — `1 lb` and US cups are not what this user shops or cooks
with. Round to sensible shop amounts (450 g, not 453.6 g). Leave spoons alone,
being locale-neutral.

Convert silently. The converted amount **is** the recipe now; nobody needs to be
told what it used to be. Cup-to-weight for solids is a density approximation
rather than arithmetic, which is a reason to round to a sane shop amount, not a
reason to annotate the line.

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

### A recipe is a cooking document, not a changelog

**The test: would this line make sense to someone the recipe was shared with?**
If it only makes sense to whoever converted it, it does not belong in the recipe.

Never write:

- `1 lb in the source`, `4 cups — an approximate conversion`, `the source gives 1½ oz`
- `a mangled conversion`, `title de-shouted`, `SEO padding stripped`
- `the source only mentions this in its ingredient list`
- `servings corrected from 6 to 8`, `times derived from the method`

None of that is cooking. It is a record of editing work, and to anyone else it
reads as noise about a document they never saw. The source belongs in
`source_url`; the editing history belongs in the conversation where it happened.

`description` is a short blurb about **the dish** — what it is, what it eats like,
who it feeds. Leave it empty rather than filling it with process notes.

An italic aside on a step is for something that changes how you cook:

> *Cold stock stalls the rice on every ladle — the usual cause of a gluey risotto.*

> *Off the heat matters — mascarpone and parmesan split in a pan that is still going.*

Both earn their place because they tell you why. Compare the same notes ruined by
provenance: *"the source only mentions this in its ingredient list"* explains an
editorial decision to a reader who does not care.

The one exception is where **the source's own quantity is unsafe as written** — a
US recipe calling for 3 tbsp of "chili powder" means a mild blend, not the pure
ground chilli sold here, and following it literally ruins the dish. That warning
is about cooking, so it stays. Naming the two things is what makes it useful;
naming the *source* is not.

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
