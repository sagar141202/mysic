#!/usr/bin/env bash
# ============================================================
#  Mysic — Fix MiniPlayer import in Layout.jsx
#  Run from project root:  bash fix_miniplayer_import.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Fixing MiniPlayer import...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run from project root${NC}"; exit 1
fi

LAYOUT="src/components/Layout.jsx"

python3 - "$LAYOUT" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f: src = f.read()

if 'MiniPlayer' in src:
    print('  ✓ MiniPlayer already imported — nothing to do')
    sys.exit(0)

# Find the last "import ... from '...'" line and insert after it
lines = src.split('\n')
last_import_idx = 0
for i, line in enumerate(lines):
    if line.startswith('import '):
        last_import_idx = i

lines.insert(last_import_idx + 1, "import MiniPlayer    from './MiniPlayer'")
src = '\n'.join(lines)

with open(path, 'w') as f: f.write(src)
print('  ✓ MiniPlayer import added to Layout.jsx')
PYEOF

# Verify
python3 -c "
src = open('src/components/Layout.jsx').read()
assert 'MiniPlayer' in src, 'STILL MISSING'
print('  ✓ Verified: MiniPlayer import present')
"

echo ""
echo -e "${GREEN}  Done! Restart dev server:  npm run dev${NC}"
