#!/usr/bin/env bash
# Launch the presenter: deck + speaker-notes, synced across two chromeless windows.
# notes.md (served live via /notes.json) is the single source of truth for narration.
# Run it from anywhere — it serves the folder it lives in.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PRESENT_PORT:-8765}"
HOST="localhost"          # MUST match in both windows so BroadcastChannel sync works
BROWSER="${PRESENT_BROWSER:-Google Chrome}"
PROFILE="${PRESENT_PROFILE:-$HOME/.present-profile}"   # dedicated Chrome profile (own instance)
MIN="${PRESENT_MIN:-}"    # target talk length in minutes -> notes pacing (T/E); blank = default
cd "$DIR" || { echo "cannot cd to $DIR"; exit 1; }

# 0. close a previous presenter instance (scoped to our profile — never touches your normal Chrome)
pkill -f "user-data-dir=$PROFILE" 2>/dev/null && { echo "closed previous presenter windows"; sleep 0.6; } || true

# 1. free the port
PIDS=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null || true)
if [ -n "$PIDS" ]; then echo "stopping server on :$PORT ($PIDS)"; kill $PIDS 2>/dev/null || true; sleep 1; fi

# 2. start the server
echo "starting present.py on :$PORT ..."
nohup python3 present.py > present.log 2>&1 &
SERVER_PID=$!
echo "  pid $SERVER_PID   (log: present.log)"

# 3. wait until it answers
for _ in $(seq 1 40); do
  curl -fsS "http://$HOST:$PORT/notes.json" >/dev/null 2>&1 && { echo "  server up."; break; }
  sleep 0.2
done

SLIDES="http://$HOST:$PORT/index.html"
NOTES="http://$HOST:$PORT/notes.html"
[ -n "$MIN" ] && NOTES="$NOTES?min=$MIN"

# 4. two CHROMELESS windows (Chrome --app: no tabs/URL bar). Shared profile = one instance = sync works.
CHROME="/Applications/$BROWSER.app/Contents/MacOS/$BROWSER"
OPENED=0
if [[ "$OSTYPE" == darwin* && -x "$CHROME" ]]; then
  COMMON=(--user-data-dir="$PROFILE" --no-first-run --no-default-browser-check
          --disable-session-crashed-bubble --disable-features=Translate
          --autoplay-policy=no-user-gesture-required)
  nohup "$CHROME" "${COMMON[@]}" --window-position=0,0 --window-size=1280,720 --app="$SLIDES" >/dev/null 2>&1 & disown
  sleep 1.6
  nohup "$CHROME" "${COMMON[@]}" --window-position=160,160 --window-size=1180,720 --app="$NOTES" >/dev/null 2>&1 & disown
  OPENED=1
fi

if [ "$OPENED" = 1 ]; then cat <<EOF

  ──────────────────────────────────────────────────────────────
  Presenter ready — two chromeless windows (no tabs / no URL bar).
    Slides : $SLIDES
    Notes  : $NOTES
  1. Drag the NOTES window to your second monitor.
  2. Press  F  inside each window for fullscreen (F again to exit).
  Keys (either window, both follow):
    F    fullscreen        ← → / space / PgUp-Dn / Home / End   navigate
    V    swap this window slides <-> notes      D   notes light/dark
    R    reload notes from notes.md (+ deck)     T   reset timer (click timer = pause)
    O    solo — keep THIS window, close the other (e.g. deck only, single screen)
  Stop the server:  kill $SERVER_PID    (or: lsof -ti:$PORT | xargs kill)
  ──────────────────────────────────────────────────────────────
EOF
else cat <<EOF

  Chrome not found at: $CHROME  (set PRESENT_BROWSER, or open these yourself in two windows)
    Slides : $SLIDES
    Notes  : $NOTES
  Chromeless fullscreen:  chrome --app="$SLIDES"
  Stop the server:  kill $SERVER_PID
EOF
fi
