#!/usr/bin/env python3
"""
present.py — tiny presenter server for a single-file HTML deck + speaker notes.

Serves this folder statically (like `python -m http.server`) and adds ONE live
endpoint:

    GET /notes.json   -> { pages, count, slices:[{n,title,tag,body}, ...] }

Notes live in `notes.md` next to the deck and are read FRESH on every request,
so the markdown stays the single source of truth: edit a slice, press R in the
notes window, it updates. Nothing is copied or pre-built.

The notes file uses one simple format — a `### Slices` section of numbered
items, each followed by an indented ```fenced``` block of narration:

    ### Slices
    1. Title of slide 1 [optional tag]
        ```
        Narration for slide 1. **Bold** marks a keyword. [cues] read as stage directions.
        ```
    2. Title of slide 2
        ```
        ...
        ```

Slice N maps 1:1 to deck page N. Pages past the last slice (e.g. a Q&A
appendix) simply have no note.

Run:  python3 present.py        (serves http://localhost:8765)
Env:  PRESENT_PORT (default 8765) · PRESENT_NOTES (default ./notes.md)
"""
import os
import re
import json
import socket
import http.server
from urllib.parse import urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
PORT = int(os.environ.get("PRESENT_PORT", "8765"))
NOTES_MD = os.environ.get("PRESENT_NOTES", os.path.join(HERE, "notes.md"))
DECK_HTML = os.path.join(HERE, "index.html")

NUM_RE = re.compile(r"^(\d+)\.\s+(.*)$")
TAG_RE = re.compile(r"\[(.*?)\]\s*$")


def parse_slices(text):
    """Parse the `### Slices` section into [{n,title,tag,body}]."""
    lines = text.split("\n")
    start = 0
    for i, l in enumerate(lines):
        if l.strip().lower() == "### slices":
            start = i + 1
            break

    slices = []
    cur = None
    body = []
    in_fence = False

    def close():
        if cur is not None:
            cur["body"] = "\n".join(body).strip("\n")
            slices.append(cur)

    for l in lines[start:]:
        if in_fence:
            if l.strip() == "```":
                in_fence = False
            else:
                body.append(l[1:] if l.startswith("\t") else l)
            continue

        m = NUM_RE.match(l)
        if m:
            close()
            raw = m.group(2).strip()
            tag = ""
            title = raw
            tm = TAG_RE.search(raw)
            if tm:
                tag = tm.group(1).strip()
                title = raw[: tm.start()].strip()
            cur = {"n": int(m.group(1)), "title": title, "tag": tag}
            body = []
        elif l.strip() == "```":
            in_fence = True
        elif l.startswith("## ") or l.startswith("### "):
            break  # next section -> slices ended

    close()
    return slices


def deck_page_count():
    try:
        html = open(DECK_HTML, encoding="utf-8").read()
        return html.count('<section class="slide')
    except OSError:
        return 0


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=HERE, **k)

    def log_message(self, *a):
        pass  # quiet — keep the terminal clean during the talk

    def end_headers(self):
        # files change mid-rehearsal — disable caching on EVERY response so a
        # refresh always shows the latest deck/notes/assets (stale-cache bugs
        # here are invisible and maddening)
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if urlparse(self.path).path == "/notes.json":
            return self.serve_notes()
        return super().do_GET()

    def serve_notes(self):
        try:
            text = open(NOTES_MD, encoding="utf-8").read()
            slices = parse_slices(text)
            data = {"pages": deck_page_count(), "count": len(slices), "slices": slices}
            payload = json.dumps(data, ensure_ascii=False).encode("utf-8")
        except FileNotFoundError:
            payload = json.dumps({"error": f"no notes file at {NOTES_MD}", "slices": []}).encode("utf-8")
            self.send_response(200)
        except Exception as e:
            payload = json.dumps({"error": str(e), "slices": []}).encode("utf-8")
            self.send_response(500)
        else:
            self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


class Server(http.server.ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True
    address_family = socket.AF_INET6  # dual-stack: localhost->::1 AND 127.0.0.1

    def server_bind(self):
        try:
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        except (AttributeError, OSError):
            pass
        super().server_bind()


if __name__ == "__main__":
    print(f"present.py  ·  http://localhost:{PORT}")
    print(f"  deck   : {DECK_HTML}")
    print(f"  notes  : {NOTES_MD}")
    print(f"  open   : /index.html (deck) · /notes.html (notes) · /notes.json (data)")
    with Server(("::", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped.")


def _selftest():
    sample = "### Slices\n1. Hello [intro]\n\t```\n\tFirst **slide**.\n\t```\n2. Next\n\t```\n\tSecond.\n\t```\n## Appendix\n3. ignored\n"
    sl = parse_slices(sample)
    assert [s["n"] for s in sl] == [1, 2], sl
    assert sl[0]["title"] == "Hello" and sl[0]["tag"] == "intro"
    assert sl[0]["body"] == "First **slide**."
    assert len(sl) == 2  # stops at ## Appendix
    print("ok")
