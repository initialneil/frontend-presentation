# frontend-presentation

A Claude Code **skill** for building a *talk*, not just slides.

One folder gives you two things that stay in sync:

- a zero-dependency, animation-rich **deck** (`index.html`) — a single HTML file on a fixed 16:9 stage, and
- a large-font **speaker-notes presenter** (`notes.html`) on a second screen,

driven by a tiny local server. Advance in either window and both move. The narration lives in a plain
`notes.md` beside the deck — the single source of truth, editable mid-rehearsal and reloaded with a keypress.

It adds, on top of a good-looking deck:

- **Notes as a first-class artifact** — `notes.md`, 1:1 with the slides, served live.
- **Dual-screen presenter** — deck + notes synced over `BroadcastChannel`; either drives both; one key for real fullscreen.
- **In-slide staged builds** — reveal beats within a single slide (including zoom-and-settle), gated to that slide.
- **Projection-grade readability** — big type, high contrast, one idea per slide by default.
- **Live pacing** — the notes window shows **T** (where the clock *should* be on this slide) and **E** (your projected finish at the current pace), so you can steer your speed to a target length.

## Credit

This skill builds directly on the **frontend-slides** skill (the Claude Code frontend-slides plugin) —
its philosophy of zero-dependency, animation-rich HTML decks, a fixed 1920×1080 stage, and discovering a
*distinctive* aesthetic through visual previews rather than abstract style questions. All of that is
frontend-slides' design; full credit to it. `frontend-presentation` is a derivative that keeps that
aesthetic approach and adds the presentation *system* around it: synced speaker notes, dual-screen
delivery, per-slide build animation, readability defaults, and pacing. If you only need a deck, use
frontend-slides. If your talk needs notes, two screens, or build animations, use this.

## Use it

In Claude Code, just ask — "build me a talk on X", "make a defense deck with speaker notes", "convert
this PPT to a web presentation". The skill scaffolds a folder, helps you land an aesthetic through 3
previews, builds the deck and the notes together, and gives you the presenter.

Layout of a talk folder it produces:

```
my-talk/
├── index.html      # the deck (single file, your aesthetic)
├── notes.md        # narration — one block per slide, 1:1
├── present.py      # local server: serves the folder + /notes.json (notes.md, live)
├── notes.html      # speaker-notes presenter window
├── present.sh      # launcher: server + two chromeless windows
└── assets/         # images, video, fonts
```

## Present

From the talk folder:

```bash
bash present.sh                    # default target length
PRESENT_MIN=30 bash present.sh     # 30-minute target (drives the T/E pacing)
```

It starts the server and opens two chromeless Chrome windows (slides + notes). Then:

1. Drag the **notes** window to your second monitor.
2. Press **F** in each window for real fullscreen (F again to exit).
3. Keys (work in either window — both follow):

   | key | action |
   |-----|--------|
   | `← →` / space / PgUp-Dn / Home / End | navigate |
   | `F` | toggle fullscreen |
   | `V` | swap this window between deck and notes |
   | `D` | notes light / dark theme |
   | `R` | reload notes from `notes.md` (and the deck) |
   | `T` | reset the elapsed timer (click the timer to pause) |

Both windows must use the **same host** (`localhost`) for the sync to work. Stop the server with
`kill <pid>` (printed by the launcher) or `lsof -ti:8765 | xargs kill`.

Env knobs: `PRESENT_PORT` (default 8765), `PRESENT_BROWSER` (default "Google Chrome"),
`PRESENT_MIN` (target minutes), `PRESENT_NOTES` (alternate notes file).

## The notes format

`notes.md`, under a `### Slices` heading, one numbered item per deck page with an indented fenced block:

```
### Slices
1. Short title [optional tag]
	```
	What you actually say. **Bold** a keyword; [bracketed] cues read as stage directions.
	```
2. ...
```

Slice *N* maps 1:1 to deck page *N*. Add or remove a slide → update the notes in lockstep. Pages past
the last slice (a Q&A appendix, say) simply have no note.

## Install (Claude Code)

The skill is discoverable when it lives in your personal skills dir:

```bash
ln -s "$(pwd)" ~/.claude/skills/frontend-presentation
```

(or copy the folder there). Then Claude Code can invoke it for any presentation.

## Develop

This repo is registered with **project-with-reflect** as **`frontend-presentation-repo`**
— a separate dev skill (`/frontend-presentation-repo`) that carries persistent memory of pending features,
bugs, and decisions across sessions. Use `frontend-presentation` to *make a talk*; use
`frontend-presentation-repo` to *work on this skill*.

## Layout of this repo

```
frontend-presentation/
├── SKILL.md            # the skill instructions Claude Code loads
├── README.md
├── runtime/            # the server + notes presenter + launcher, copied into each talk
│   ├── present.py
│   ├── notes.html
│   └── present.sh
└── template/           # a minimal, readable starter deck + notes (replace the aesthetic)
    ├── index.html
    ├── notes.md
    └── assets/
```

## License

MIT.
