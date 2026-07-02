---
name: frontend-presentation
description: Build a distinctive, animation-rich HTML talk deck AND a synced speaker-notes presenter in one folder — a single-file 16:9 deck plus a large-font notes window that mirror each other across two screens, with in-slide staged builds, projection-grade readability, and live pacing. Use whenever the user wants to make a presentation, talk, lecture, defense, or pitch deck, rehearse or present one, convert a PPT to web, or wants speaker notes that stay in sync with the slides. Builds on the frontend-slides aesthetic approach; reach for THIS skill when the talk needs presenter notes, dual-screen delivery, or per-slide build animation.
---

# Frontend Presentation

Build a **talk** — not just slides. One folder gives you a zero-dependency, animation-rich
**deck** (`index.html`) and a synced **speaker-notes** presenter (`notes.html`) driven by a tiny
local server. Slides full-screen on one monitor, large-font notes on another; advancing in either
window moves both. Narration lives in `notes.md` next to the deck — plain markdown, the single
source of truth, editable mid-rehearsal.

This builds on the **frontend-slides** aesthetic philosophy (distinctive design, no "AI slop",
discover the look through previews). The additions that make it a presentation *system*:

1. **Notes are a first-class artifact** — `notes.md` in the deck folder, 1:1 with slides, served live.
2. **Dual-screen presenter** — deck + notes windows synced via `BroadcastChannel`; either drives both.
3. **In-slide staged builds** — reveal beats within one slide, gated to that slide.
4. **Readability-first** — projection-grade type and contrast by default.
5. **Live pacing** — the notes window shows where the clock *should* be (T) and your projected finish (E).

## Bundled files

- `runtime/present.py` — static server + `GET /notes.json` (parses `notes.md` fresh per request).
- `runtime/notes.html` — the presenter notes view (auto-fit big type, next-slide peek, themes, pacing, sync).
- `runtime/present.sh` — launcher: starts the server, opens two chromeless Chrome windows.
- `template/index.html` — a minimal, readable starter deck wired with the stage, reveals, a generic
  in-slide build, and the sync hook. **The aesthetic here is a placeholder — replace it.**
- `template/notes.md` — narration scaffold in the expected format.

## Workflow

### 0 · Scaffold the talk folder
Pick/confirm a working folder for this talk (default: a new subfolder in the user's cwd). Copy the
bundled `template/` contents (`index.html`, `notes.md`, `assets/`) into it, then copy the **runtime
files** (`present.py`, `notes.html`, `present.sh`) **flat into that same folder** — beside
`index.html`/`notes.md`, **not** as a `runtime/` subfolder. `present.py` serves *its own* directory
(`directory=dirname(__file__)`), so if it sits one level down in `runtime/` it serves that subfolder
and `/index.html` 404s. Correct final layout, all in one flat folder:
`index.html · notes.md · notes.html · present.py · present.sh · assets/`.

### 1 · Discover the aesthetic (frontend-slides Phase 2, briefly)
Don't ask abstract style questions. Generate **3 distinct single-slide previews** (typography, color,
motion) as standalone HTML and open them; let the user pick or mix. Converge on something
**distinctive** — avoid generic fonts (Inter/Arial/Space Grotesk) and timid palettes. If
frontend-slides is installed, its `STYLE_PRESETS.md` / template pack are good preview sources; if not,
design the three previews directly. Apply the winner as the deck's CSS variables + fonts.

### 2 · Build the deck (`index.html`)
Single HTML file, inline CSS/JS, **zero dependencies**. Keep the engine from `template/index.html`
(stage scaling, hash nav, reveals, `data-build`, sync hook) and restyle/author content on top.

- **Fixed 16:9 stage (non-negotiable):** a 1920×1080 `#stage` scaled as a whole to the viewport.
  Author every slide at 1920×1080 in px. Never reflow slide content to the device.
- **One `<section class="slide">` per page.** A `.pad` box (`inset` margins) holds content so layout
  is predictable. Page number is 1-based (`location.hash`).
- **Reveal choreography:** `.reveal` + `.d1..d6` stagger elements in when a slide becomes `.visible`.
- **In-slide staged builds:** add `data-build="N"` to a section; style hidden→shown states by `.s1..sN`
  on the section root (see the `#build` example). The controller advances stages with arrows/space via a
  **capture-phase** listener gated to the current slide — it `stopImmediatePropagation()`s so the deck's
  own next/prev is suppressed until the build is exhausted, then the last press changes slides; back-arrow
  steps the build in reverse. Re-entering a slide resets the stage (0 forward, max backward). Use builds
  for: revealing list items one beat at a time, or **zoom-and-settle** (show one figure large, then shrink
  it into place as the next appears). Don't over-animate — a build per slide at most, only where beats matter.
- **Build-driven switcher (screenshot walkthroughs):** when a slide is "N steps, N screenshots", never
  shrink the images into N side-by-side cards — they become unreadable. Show ONE big visual and let the
  build stages SWAP it in place: stack `.shot` images absolutely in a frame, toggle by `.s0/.s1/.s2` on
  the section root, and dim/highlight the matching talking points (`.vp`) in sync (see the `.switch`
  example slide). Same arrow keys as a normal build, no extra JS — `data-build="N-1"` for N shots.
- **Readability (projection-grade), enforce by default:**
  - Body text ≥ 28px (on the 1920 stage); slide titles 44–104px. If text needs to be smaller to fit, the
    slide has too much on it — cut it, the script goes in the notes.
  - High contrast ink-on-background; one dominant color with a sharp accent. Test legibility small.
  - **One idea per slide.** Lead with the keyword, not the sentence. Bold the load-bearing words.
- **Convert from PPT:** extract text/images per slide, then rebuild each as a styled `.slide` (don't
  embed the raster export). Keep the 1:1 page order so notes line up.

### 3 · Write the notes (`notes.md`)
Narration is a deliverable, not an afterthought. Under `### Slices`, one numbered item per deck page,
each with an indented ```fenced``` block:

```
### Slices
1. Short title [optional tag]
	```
	What you actually say. **Bold** a keyword (renders bold in the notes view). [bracketed] cues
	and todo: lines read as stage directions.
	```
2. ...
```

- **Strict 1:1 mapping:** slice N ↔ deck page N. When you add/remove/reorder a slide, update the notes
  in lockstep (renumber). Pages past the last slice (e.g. a Q&A appendix) just have no note — fine.
- Keep each slice to what's spoken on that slide. Put detail on the slide *after* a zoom into it onto
  the slide it zooms from, etc. — narration should track what's on screen.
- The user's own voice/wording wins. Don't pad. Match their phrasing when they dictate a line.

### 4 · Present
Run the launcher from the talk folder:

```bash
bash runtime/present.sh                 # or: PRESENT_MIN=30 bash runtime/present.sh  (30-min target)
```

It starts the server and opens two chromeless windows (Chrome `--app` mode). Tell the user:
1. Drag the **notes** window to the second monitor.
2. Press **F** in each window for real fullscreen (F again to exit).
3. Keys (either window, both follow): **← →** / space / PgUp-Dn / Home / End navigate · **V** swap a
   window between deck/notes · **D** notes light/dark · **R** reload notes from `notes.md` (and the
   deck) · **T** reset timer (click the timer to pause) · **O** solo — keep the window you press it in
   and close the other (e.g. deck-only on a single screen; either window can send it).
4. **Pacing:** the notes bar shows **T** (where the clock should read on this slide, narration
   word-count spread across the target length) and **E** (projected total at current pace — green
   under, red over); the live clock tints ahead/behind. Set the target with `PRESENT_MIN=<minutes>`.

Report the URLs and server PID so they can stop it (`kill <pid>` or `lsof -ti:8765 | xargs kill`).

## How the pieces fit (for edits)
- The deck broadcasts its page on `BroadcastChannel('present-sync')` and follows peers; **R** broadcasts
  a reload. The notes window listens on the same channel and re-pulls `/notes.json` on R (it does *not*
  full-reload, so the elapsed timer survives) — a structural deck change needs a real deck refresh.
- Both windows must use the **same host** (`localhost`) or the channel origins won't match.
- `present.py` is a plain static server plus `/notes.json`; it reads `notes.md` from its own folder on
  every request. No build step, no restart needed for content edits — just refresh / press R.
- Headless check while authoring (macOS): `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  --headless=new --disable-gpu --window-size=1920,1080 --screenshot=/tmp/p.png "file://$PWD/index.html#3"`
  (`?st=N#page` if you wire the `data-build` test hook from the template).

## Defaults & taste
- Reuse what's here before adding anything. No frameworks, no slide libraries — the engine is ~60 lines.
- Distinctive over templated; readable over dense; sparse slides + rich notes over wall-of-text slides.
- Keep narration em-dash-free if the user writes that way; mirror the user's voice, don't impose one.
