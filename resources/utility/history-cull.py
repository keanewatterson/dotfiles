#!/usr/bin/env python3
# history-cull.py — stop gap cruft remover

import re
from pathlib import Path

HISTFILE = Path.home() / ".config/zsh/.zsh_history"

# Extended noise patterns for post-hoc removal
NOISE_PATTERNS = [
    r"^cd(\s+\S+)?$",  # bare cd or cd <path>
    r"^git add\s+(?!.*&&)",  # git add without compound
    r"^cat\s+\S+$",  # bare cat (no pipe)
    r"^alias(\s+\|.*)?$",  # alias and alias | grep
    r"^(man|which|clear|wc)\s*",  # lookup commands
    r"^echo\s+\S+$",  # bare echo (variable inspection)
]

compiled = [re.compile(p) for p in NOISE_PATTERNS]

lines = HISTFILE.read_text(errors="replace").splitlines()
kept = []
removed = 0

i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith(": ") and ";" in line:
        cmd = line.split(";", 1)[1]
        if any(p.match(cmd) for p in compiled):
            removed += 1
            i += 1
            continue
    kept.append(line)
    i += 1

HISTFILE.write_text("\n".join(kept) + "\n")
print(f"Culled {removed} entries, kept {len(kept)} lines")
