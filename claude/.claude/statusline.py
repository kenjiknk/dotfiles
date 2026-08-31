#!/usr/bin/env python3
"""Claude Code status line: model + effort, context usage, rate limits, cost."""
import json
import os
import subprocess
import sys
import time


def c(code, text):
    return f"\033[{code}m{text}\033[0m"


DIM, CYAN, BLUE, MAGENTA, YELLOW, GREEN, RED = "2", "36;1", "34", "35", "33", "32", "31"


def human(n):
    n = float(n)
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}k"
    return f"{int(n)}"


def fmt_duration(ms):
    s = int(ms) // 1000
    if s < 60:
        return f"{s}s"
    m, s = divmod(s, 60)
    if m < 60:
        return f"{m}m{s:02d}s"
    h, m = divmod(m, 60)
    return f"{h}h{m:02d}m"


def fmt_until(epoch):
    """Compact 'time from now' until a unix timestamp."""
    d = int(epoch - time.time())
    if d <= 0:
        return "now"
    m, _ = divmod(d, 60)
    h, m = divmod(m, 60)
    days, h = divmod(h, 24)
    if days:
        return f"{days}d{h}h"
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m"


def pct_color(p):
    return GREEN if p < 50 else (YELLOW if p < 80 else RED)


def transcript_tokens(path):
    """Fallback context measure for older Claude Code without context_window."""
    if not path or not os.path.isfile(path):
        return None
    try:
        with open(path, "rb") as f:
            lines = f.readlines()
    except OSError:
        return None
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            evt = json.loads(line)
        except ValueError:
            continue
        usage = (evt.get("message") or {}).get("usage")
        if usage:
            return (
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
    return None


def git_branch(cwd):
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=1,
        )
        if out.returncode == 0:
            return out.stdout.strip() or None
    except (OSError, subprocess.SubprocessError):
        pass
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except (ValueError, OSError):
        data = {}

    parts = []

    # --- Model + reasoning effort -----------------------------------------
    model = (data.get("model") or {}).get("display_name") or (data.get("model") or {}).get("id") or "?"
    seg = f"◆ {model}"
    effort = (data.get("effort") or {}).get("level")
    if not (data.get("thinking") or {}).get("enabled", True):
        effort = "no-think"
    if effort:
        seg += c(DIM, "·") + effort
    if data.get("fast_mode"):
        seg += c(DIM, "·") + "fast"
    parts.append(c(CYAN, seg))

    # --- Version + non-default output style ------------------------------
    ver = data.get("version")
    style = (data.get("output_style") or {}).get("name")
    meta = f"v{ver}" if ver else ""
    if style and style != "default":
        meta += f" [{style}]"
    if meta:
        parts.append(c(DIM, meta))

    # --- Directory + git branch ----------------------------------------------
    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or os.getcwd()
    home = os.path.expanduser("~")
    disp = cwd.replace(home, "~", 1) if cwd.startswith(home) else cwd
    seg = c(BLUE, disp)
    br = git_branch(cwd)
    if br:
        seg += " " + c(MAGENTA, f"⎇ {br}")
    parts.append(seg)

    # --- Context window usage ---------------------------------------------
    cw = data.get("context_window") or {}
    if cw.get("context_window_size"):
        pct = cw.get("used_percentage", 0)
        used = cw.get("total_input_tokens", 0)
        size = cw["context_window_size"]
        parts.append(c(pct_color(pct), f"ctx {pct}% {human(used)}/{human(size)}"))
    else:
        limit = 1_000_000 if data.get("exceeds_200k_tokens") else 200_000
        used = transcript_tokens(data.get("transcript_path"))
        if used is not None:
            pct = used / limit * 100
            parts.append(c(pct_color(pct), f"ctx {pct:.0f}% {human(used)}/{human(limit)}"))

    # --- Rate limits: 5-hour and 7-day ----------------------------------
    rl = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        info = rl.get(key)
        if not info:
            continue
        p = info.get("used_percentage", 0)
        txt = f"{label} {p}%"
        if info.get("resets_at"):
            txt += c(DIM, f" ↻{fmt_until(info['resets_at'])}")
        parts.append(c(pct_color(p), txt))

    # --- Cost / duration / lines ------------------------------------------
    cost = data.get("cost") or {}
    if cost.get("total_cost_usd") is not None:
        parts.append(c(YELLOW, f"${cost['total_cost_usd']:.2f}"))
    if cost.get("total_duration_ms"):
        parts.append(c(DIM, fmt_duration(cost["total_duration_ms"])))
    added = cost.get("total_lines_added") or 0
    removed = cost.get("total_lines_removed") or 0
    if added or removed:
        parts.append(c(GREEN, f"+{added}") + " " + c(RED, f"-{removed}"))

    sys.stdout.write(c(DIM, " │ ").join(parts))


if __name__ == "__main__":
    main()
