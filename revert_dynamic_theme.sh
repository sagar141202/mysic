#!/usr/bin/env bash
# ============================================================
#  Mysic — Revert Dynamic Theme
#  Run from your project root:  bash revert_dynamic_theme.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Reverting Dynamic Theme...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root${NC}"
  exit 1
fi

# ── 1. Delete created files ──────────────────────────────────
for f in "src/utils/colorExtractor.js" "src/hooks/useDynamicTheme.js"; do
  if [ -f "$f" ]; then
    rm "$f"
    echo -e "${GREEN}  ✓ Deleted $f${NC}"
  else
    echo -e "${YELLOW}  ⚠ $f not found — skipping${NC}"
  fi
done

# ── 2. Unpatch Layout.jsx ────────────────────────────────────
LAYOUT="src/components/Layout.jsx"
if [ -f "$LAYOUT" ]; then
python3 - "$LAYOUT" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# Remove the import line
src = src.replace("import { useDynamicTheme } from '../hooks/useDynamicTheme'\n", '', 1)

# Remove the hook call line (with the comment)
src = src.replace(
  "\n  useDynamicTheme()   // dynamic colour palette from thumbnail", '', 1)

if src == original:
    print('  ⚠  Layout.jsx — nothing to revert (already clean)')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Layout.jsx reverted')
PYEOF
else
  echo -e "${YELLOW}  ⚠ $LAYOUT not found — skipping${NC}"
fi

# ── 3. Unpatch AlbumArt.jsx ──────────────────────────────────
ALBUMART="src/components/AlbumArt.jsx"
if [ -f "$ALBUMART" ]; then
python3 - "$ALBUMART" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# Remove the import line
src = src.replace("import { extractColors } from '../utils/colorExtractor'\n", '', 1)

# Replace the expanded onLoad back to the original one-liner
expanded = r"onLoad=\{e => \{[^}]+setLoaded\(true\)[^}]+if \(size === 'xl'[^}]+\}[^}]+\}[^}]+\}\}"
simple   = "onLoad={() => setLoaded(true)}"
result   = re.sub(expanded, simple, src, flags=re.DOTALL)

if result == original:
    print('  ⚠  AlbumArt.jsx — nothing to revert (already clean)')
else:
    with open(path, 'w') as f: f.write(result)
    print('  ✓  AlbumArt.jsx reverted')
PYEOF
else
  echo -e "${YELLOW}  ⚠ $ALBUMART not found — skipping${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Dynamic Theme fully reverted!              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
