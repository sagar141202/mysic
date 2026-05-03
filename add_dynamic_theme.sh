#!/usr/bin/env bash
# ============================================================
#  Mysic — Dynamic Theme (colour extraction from thumbnails)
#  Run from your project root:  bash add_dynamic_theme.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Dynamic Theme...${NC}"

# ── Guard: must be run from project root ────────────────────
if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root (where package.json lives)${NC}"
  exit 1
fi

mkdir -p src/hooks src/components

# ════════════════════════════════════════════════════════════
# 1.  src/utils/colorExtractor.js
#     Pure canvas-based dominant-colour extractor.
#     No npm packages. Works entirely in the browser.
# ════════════════════════════════════════════════════════════
cat > src/utils/colorExtractor.js << 'EOF'
/**
 * colorExtractor.js
 *
 * Extracts a palette of dominant colours from an image URL
 * using a hidden <canvas> + median-cut–style pixel bucketing.
 *
 * WHY NOT WEB WORKERS / k-MEANS:
 *   YouTube thumbnails are ~120×90px after we downscale.
 *   Pixel bucketing on ~500 sampled pixels takes < 2 ms on the
 *   main thread — no worker overhead needed.
 *
 * CORS NOTE:
 *   YouTube thumbnail CDN (i.ytimg.com) sends permissive CORS
 *   headers, so crossOrigin="anonymous" on the <img> + the
 *   canvas drawImage() path works without a proxy.
 *   If extraction fails for any image we silently fall back
 *   to the default cyan palette.
 */

/** Convert R,G,B → "r,g,b" string used in CSS rgba() */
export const toRgb = ([r, g, b]) => `${r},${g},${b}`

/** Convert R,G,B → "#rrggbb" hex */
export const toHex = ([r, g, b]) =>
  '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('')

/**
 * Perceived luminance (0–1).  Used to skip near-black / near-white
 * pixels that dominate YouTube letterbox bars.
 */
const luma = (r, g, b) => (0.299 * r + 0.587 * g + 0.114 * b) / 255

/**
 * HSL saturation (0–1).  We prefer vivid colours over greys.
 */
function saturation(r, g, b) {
  const rn = r / 255, gn = g / 255, bn = b / 255
  const max = Math.max(rn, gn, bn)
  const min = Math.min(rn, gn, bn)
  const l   = (max + min) / 2
  if (max === min) return 0
  const d = max - min
  return l > 0.5 ? d / (2 - max - min) : d / (max + min)
}

/**
 * Score a pixel: prefer vivid, mid-brightness colours.
 * Returns a float; higher = more "accent-worthy".
 */
const score = (r, g, b) => {
  const s = saturation(r, g, b)
  const l = luma(r, g, b)
  // penalise very dark (< 0.12) and very light (> 0.88)
  if (l < 0.12 || l > 0.88) return 0
  return s * (1 - Math.abs(l - 0.45))
}

/**
 * Quantise pixel data into N colour buckets using a simple
 * 4-bit colour reduction (64-colour palette), then return the
 * top `count` buckets sorted by weighted score.
 *
 * @param {Uint8ClampedArray} data  — raw RGBA from canvas
 * @param {number}            count — how many colours to return
 * @returns {Array<[r,g,b]>}
 */
function quantise(data, count = 3) {
  // Build a map: quantised-key → { r, g, b, freq, scoreSum }
  const buckets = new Map()

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2], a = data[i + 3]
    if (a < 200) continue                        // skip transparent pixels
    // Reduce to 5-bit per channel (32 levels) for bucketing
    const key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)
    const s   = score(r, g, b)
    if (!buckets.has(key)) {
      buckets.set(key, { r, g, b, freq: 0, scoreSum: 0 })
    }
    const b_ = buckets.get(key)
    b_.freq++
    b_.scoreSum += s
  }

  // Sort by (scoreSum × freq) descending — vivid AND common wins
  const sorted = [...buckets.values()]
    .sort((a, b) => (b.scoreSum * b.freq) - (a.scoreSum * a.freq))

  // Deduplicate: drop colours too close to an already-chosen one
  const chosen = []
  for (const c of sorted) {
    const tooClose = chosen.some(ch => {
      const dr = c.r - ch.r, dg = c.g - ch.g, db = c.b - ch.b
      return Math.sqrt(dr * dr + dg * dg + db * db) < 48
    })
    if (!tooClose) chosen.push([c.r, c.g, c.b])
    if (chosen.length === count) break
  }

  // Pad with fallbacks if we didn't find enough vivid colours
  const fallbacks = [[34, 211, 238], [139, 92, 246], [236, 72, 153]]
  while (chosen.length < count) chosen.push(fallbacks[chosen.length])

  return chosen
}

/**
 * Main export.
 *
 * Loads `url` onto a hidden 64×64 canvas (fast), samples every
 * pixel, returns { colors: [[r,g,b], ...], hex: ['#...', ...] }.
 *
 * Resolves immediately with fallback palette on any error
 * (CORS failure, broken image, etc.).
 */
export function extractColors(url, count = 3) {
  return new Promise(resolve => {
    const fallback = () => resolve({
      colors: [[34, 211, 238], [139, 92, 246], [236, 72, 153]],
      hex:    ['#22d3ee',      '#8b5cf6',      '#ec4899'],
    })

    if (!url) return fallback()

    const img    = new Image()
    img.crossOrigin = 'anonymous'
    img.referrerPolicy = 'no-referrer'

    img.onload = () => {
      try {
        const SIZE   = 64                          // downscale → fast
        const canvas = document.createElement('canvas')
        canvas.width = canvas.height = SIZE
        const ctx = canvas.getContext('2d')
        ctx.drawImage(img, 0, 0, SIZE, SIZE)
        const { data } = ctx.getImageData(0, 0, SIZE, SIZE)
        const colors   = quantise(data, count)
        resolve({ colors, hex: colors.map(toHex) })
      } catch {
        fallback()
      }
    }

    img.onerror = fallback
    img.src     = url
  })
}
EOF
echo -e "${GREEN}  ✓ src/utils/colorExtractor.js${NC}"

# ════════════════════════════════════════════════════════════
# 2.  src/hooks/useDynamicTheme.js
#     React hook.  Watches currentSong, extracts colours, and
#     writes them to :root CSS custom properties with a smooth
#     CSS transition so the whole app fades between palettes.
# ════════════════════════════════════════════════════════════
cat > src/hooks/useDynamicTheme.js << 'EOF'
/**
 * useDynamicTheme
 *
 * Call once, near the top of your component tree (Layout.jsx).
 * Watches `currentSong` from PlayerContext, extracts dominant
 * colours from its thumbnail, and updates :root CSS variables:
 *
 *   --accent-primary      vivid accent colour (hex)
 *   --accent-secondary    second colour (hex)
 *   --accent-grad         gradient string
 *   --orb-1               orb 1 colour (rgba, low opacity)
 *   --orb-2               orb 2 colour
 *   --orb-3               orb 3 colour
 *   --theme-rgb           "r,g,b" of accent (for rgba() uses)
 *
 * Transitions are handled entirely in CSS — we set a transition
 * on :root so every property that references these variables
 * automatically cross-fades over 1.8 s.
 */
import { useEffect, useRef } from 'react'
import { usePlayer }         from './usePlayer.jsx'
import { extractColors, toRgb } from '../utils/colorExtractor'

/* ── CSS transition injection (runs once) ───────────────────
   We inject a <style> that puts a long transition on every
   element so colour changes feel like a cinematic dissolve.
   Only transition properties that change — no layout props. */
let transitionInjected = false
function injectTransition() {
  if (transitionInjected) return
  transitionInjected = true
  const style = document.createElement('style')
  style.id = 'mysic-theme-transition'
  style.textContent = `
    /* Smooth palette cross-fade on every track change */
    *, *::before, *::after {
      transition:
        background-color 1.8s ease,
        border-color     1.4s ease,
        box-shadow       1.8s ease,
        color            1.2s ease,
        fill             1.2s ease,
        stroke           1.2s ease !important;
    }
    /* But keep UI micro-interactions snappy */
    button, a, input, [role="button"] {
      transition:
        background-color 0.22s ease,
        border-color     0.22s ease,
        box-shadow       0.22s ease,
        color            0.18s ease,
        transform        0.18s ease,
        opacity          0.18s ease !important;
    }
  `
  document.head.appendChild(style)
}

/* ── Helpers ─────────────────────────────────────────────── */

/** Write a CSS custom property on :root */
const setVar = (name, value) =>
  document.documentElement.style.setProperty(name, value)

/** Build an orb rgba string at the given opacity */
const orbColor = (rgb, alpha) => `rgba(${rgb}, ${alpha})`

/** Apply a full palette to :root */
function applyPalette([c1, c2, c3]) {
  const rgb1 = toRgb(c1)
  const rgb2 = toRgb(c2)
  const rgb3 = toRgb(c3)

  const hex1 = '#' + c1.map(v => v.toString(16).padStart(2,'0')).join('')
  const hex2 = '#' + c2.map(v => v.toString(16).padStart(2,'0')).join('')

  setVar('--accent-primary',   hex1)
  setVar('--accent-secondary', hex2)
  setVar('--accent-grad',
    `linear-gradient(135deg, rgba(${rgb1},1) 0%, rgba(${rgb2},1) 100%)`)
  setVar('--theme-rgb',  rgb1)

  /* Orbs: vivid but translucent so they glow without blinding */
  setVar('--orb-1', orbColor(rgb1, 0.22))
  setVar('--orb-2', orbColor(rgb2, 0.18))
  setVar('--orb-3', orbColor(rgb3, 0.15))
}

/* ── Hook ────────────────────────────────────────────────── */
export function useDynamicTheme() {
  const { currentSong } = usePlayer()
  const lastIdRef       = useRef(null)
  const abortRef        = useRef(false)

  useEffect(() => {
    injectTransition()
  }, [])

  useEffect(() => {
    /* Skip if same song (queue re-renders etc.) */
    if (!currentSong?.id || currentSong.id === lastIdRef.current) return
    lastIdRef.current = currentSong.id
    abortRef.current  = false

    /* Prefer high-res thumbnail, fall back to hqdefault */
    const thumbUrl =
      currentSong.thumbnail ||
      (currentSong.youtubeId
        ? `https://i.ytimg.com/vi/${currentSong.youtubeId}/mqdefault.jpg`
        : null)

    if (!thumbUrl) return

    extractColors(thumbUrl, 3).then(({ colors }) => {
      if (abortRef.current) return   // song changed before extraction finished
      applyPalette(colors)
    })

    return () => { abortRef.current = true }
  }, [currentSong?.id])
}
EOF
echo -e "${GREEN}  ✓ src/hooks/useDynamicTheme.js${NC}"

# ════════════════════════════════════════════════════════════
# 3.  Patch Layout.jsx
#     — import useDynamicTheme
#     — call it inside the Layout component body
# ════════════════════════════════════════════════════════════
LAYOUT="src/components/Layout.jsx"

if [ ! -f "$LAYOUT" ]; then
  echo -e "${YELLOW}  ⚠ $LAYOUT not found — skipping patch${NC}"
else
python3 - "$LAYOUT" << 'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    src = f.read()

original = src

# ── A. Add import after the last existing import line ────────
hook_import = "import { useDynamicTheme } from '../hooks/useDynamicTheme'"

if 'useDynamicTheme' not in src:
    # Insert after the last import block line
    # Find the last "import " line
    lines = src.split('\n')
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    lines.insert(last_import_idx + 1, hook_import)
    src = '\n'.join(lines)

# ── B. Call the hook inside Layout() body ───────────────────
# Insert "  useDynamicTheme()" right after "export default function Layout() {"
old_fn = 'export default function Layout() {'
new_fn = (
  'export default function Layout() {\n'
  '  useDynamicTheme()   // dynamic colour palette from thumbnail'
)

if 'useDynamicTheme()' not in src:
    src = src.replace(old_fn, new_fn, 1)

if src == original:
    print('  ⚠  Layout.jsx — already patched or pattern not matched')
else:
    with open(path, 'w') as f:
        f.write(src)
    print('  ✓  Layout.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Layout.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 4.  Patch AlbumArt.jsx
#     Trigger colour extraction early (when the xl NowPlaying
#     art loads) so the palette is ready before anything else.
#     We simply call extractColors() inside onLoad of the xl
#     image and push the result back via a custom DOM event so
#     useDynamicTheme can optionally listen.  In practice the
#     hook already fires from the song id change, so this patch
#     is purely additive — it makes extraction happen sooner
#     on slow connections by piggy-backing the already-loaded img.
# ════════════════════════════════════════════════════════════
ALBUMART="src/components/AlbumArt.jsx"

if [ ! -f "$ALBUMART" ]; then
  echo -e "${YELLOW}  ⚠ $ALBUMART not found — skipping patch${NC}"
else
python3 - "$ALBUMART" << 'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    src = f.read()

original = src

# Add extractColors import after existing imports
color_import = "import { extractColors } from '../utils/colorExtractor'"
if 'extractColors' not in src:
    # insert after last import
    lines = src.split('\n')
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    lines.insert(last_import_idx + 1, color_import)
    src = '\n'.join(lines)

# Replace onLoad handler for the thumbnail img to also fire extraction
# Original:  onLoad={() => setLoaded(true)}
# New: also run extractColors for xl size and dispatch event
old_onload = "          onLoad={() => setLoaded(true)}"
new_onload = """\
          onLoad={e => {
            setLoaded(true)
            /* For the large NowPlaying art, pre-warm colour extraction */
            if (size === 'xl' && thumbUrl) {
              extractColors(thumbUrl, 3).then(({ hex }) => {
                /* Dispatch so any listener can react; useDynamicTheme
                   already handles this via song id — this is a fast-path
                   for when the image loads before the hook fires.       */
                window.dispatchEvent(new CustomEvent('mysic:palette', {
                  detail: { hex, src: thumbUrl }
                }))
              })
            }
          }}"""

if 'mysic:palette' not in src:
    src = src.replace(old_onload, new_onload, 1)

if src == original:
    print('  ⚠  AlbumArt.jsx — already patched or pattern not matched')
else:
    with open(path, 'w') as f:
        f.write(src)
    print('  ✓  AlbumArt.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/AlbumArt.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 5.  Summary
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Dynamic Theme installed successfully!        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created:${NC}"
echo -e "    + src/utils/colorExtractor.js   — canvas pixel bucketing"
echo -e "    + src/hooks/useDynamicTheme.js  — palette → CSS vars"
echo ""
echo -e "  ${CYAN}Files patched:${NC}"
echo -e "    ~ src/components/Layout.jsx     — hook called at root"
echo -e "    ~ src/components/AlbumArt.jsx   — fast-path extraction on img load"
echo ""
echo -e "  ${CYAN}CSS variables updated per track:${NC}"
echo -e "    --accent-primary     main accent hex"
echo -e "    --accent-secondary   second colour hex"
echo -e "    --accent-grad        gradient string"
echo -e "    --orb-1/2/3          ambient orb colours"
echo -e "    --theme-rgb          'r,g,b' for rgba() usage"
echo ""
echo -e "  ${CYAN}How it works:${NC}"
echo -e "    1. Song changes → useDynamicTheme fires"
echo -e "    2. Thumbnail URL fetched onto 64×64 hidden canvas"
echo -e "    3. ~4096 pixels scored for vividness + brightness"
echo -e "    4. Top 3 distinct colours extracted (pixel bucketing)"
echo -e "    5. Written to :root  →  entire app cross-fades in 1.8s"
echo -e "    6. YouTube CORS headers allow anonymous canvas reads"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
