#!/usr/bin/env bash
# ============================================================
#  Mysic — Mini-Player (floating PiP pill)
#  Run from project root:  bash add_mini_player.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Mini-Player...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root${NC}"
  exit 1
fi

mkdir -p src/components

# ════════════════════════════════════════════════════════════
# 1.  src/components/MiniPlayer.jsx
#
#     A floating 300×76px pill, fixed bottom-right.
#     Fully draggable via pointer events (works mouse + touch).
#     Shows: album art · title · artist · prev · play/pause · next
#     + a thin progress bar along the bottom edge.
#     + a dismiss (×) button top-right.
#     Springs back inside viewport if dragged off-screen.
#     Entrance: slide up from bottom-right.
#     Exit: slide down + fade.
# ════════════════════════════════════════════════════════════
cat > src/components/MiniPlayer.jsx << 'EOF'
/**
 * MiniPlayer — floating Picture-in-Picture pill.
 *
 * Props:
 *   onClose  fn  — called when the × is pressed; parent hides it
 *   onExpand fn  — called when user clicks the pill body;
 *                  parent can re-open NowPlaying / scroll to player
 */
import { useRef, useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence }                   from 'framer-motion'
import { usePlayer }                                 from '../hooks/usePlayer.jsx'
import AlbumArt                                      from './AlbumArt'

const EASE   = [0.25, 0.46, 0.45, 0.94]
const W      = 300   /* pill width  */
const H      = 76    /* pill height */
const MARGIN = 18    /* min distance from viewport edge */

/* ── tiny control button ── */
function PillBtn({ children, onClick, primary = false, title }) {
  const [hov, setHov] = useState(false)
  return (
    <button
      title={title}
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        width: 34, height: 34, borderRadius: '50%', border: 'none',
        flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary
          ? 'var(--accent-grad)'
          : hov ? 'rgba(255,255,255,0.10)' : 'rgba(255,255,255,0.04)',
        color:  primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 13 : 11,
        cursor: 'pointer',
        transition: 'background 0.15s',
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
        boxShadow: primary ? '0 3px 12px rgba(34,211,238,0.40)' : 'none',
      }}
    >
      {children}
    </button>
  )
}

export default function MiniPlayer({ onClose, onExpand }) {
  const {
    currentSong, isPlaying, progress,
    togglePlay, playNext, playPrev,
  } = usePlayer()

  /* ── Draggable state ── */
  /* Start position: bottom-right corner with margin */
  const startPos = useCallback(() => ({
    x: window.innerWidth  - W - MARGIN,
    y: window.innerHeight - H - MARGIN - 80, /* 80 = approx player bar height */
  }), [])

  const [pos,      setPos]      = useState(startPos)
  const [dragging, setDragging] = useState(false)
  const dragStart  = useRef({ mx: 0, my: 0, px: 0, py: 0 })
  const pillRef    = useRef(null)

  /* Clamp to viewport */
  const clamp = useCallback((x, y) => ({
    x: Math.max(MARGIN, Math.min(window.innerWidth  - W - MARGIN, x)),
    y: Math.max(MARGIN, Math.min(window.innerHeight - H - MARGIN, y)),
  }), [])

  /* ── Pointer drag handlers ── */
  const onPointerDown = useCallback(e => {
    /* Only drag on the pill body, not on buttons */
    if (e.target.closest('button')) return
    e.currentTarget.setPointerCapture(e.pointerId)
    setDragging(true)
    dragStart.current = { mx: e.clientX, my: e.clientY, px: pos.x, py: pos.y }
  }, [pos])

  const onPointerMove = useCallback(e => {
    if (!dragging) return
    const dx = e.clientX - dragStart.current.mx
    const dy = e.clientY - dragStart.current.my
    setPos(clamp(dragStart.current.px + dx, dragStart.current.py + dy))
  }, [dragging, clamp])

  const onPointerUp = useCallback(e => {
    e.currentTarget?.releasePointerCapture?.(e.pointerId)
    setDragging(false)
  }, [])

  /* Re-clamp if window resizes */
  useEffect(() => {
    const onResize = () => setPos(p => clamp(p.x, p.y))
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [clamp])

  /* Re-position to default spot when first shown */
  useEffect(() => { setPos(startPos()) }, [startPos])

  const accentHex = currentSong.color || '#22d3ee'

  return (
    <motion.div
      ref={pillRef}
      /* Entrance from below, exit downward */
      initial={{ opacity: 0, y: 40, scale: 0.92 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: 40, scale: 0.92 }}
      transition={{ duration: 0.30, ease: EASE }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      style={{
        position:  'fixed',
        left:      pos.x,
        top:       pos.y,
        width:     W,
        height:    H,
        zIndex:    300,
        cursor:    dragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        /* Glass pill */
        background:           'rgba(8,12,20,0.90)',
        backdropFilter:       'blur(28px)',
        WebkitBackdropFilter: 'blur(28px)',
        border:               `1px solid rgba(255,255,255,0.10)`,
        borderRadius:         22,
        boxShadow:            `0 16px 48px rgba(0,0,0,0.55), 0 0 0 1px ${accentHex}18, inset 0 1px 0 rgba(255,255,255,0.06)`,
        fontFamily:           'var(--font-body)',
        overflow:             'hidden',
        display:              'flex',
        flexDirection:        'column',
        transition:           'box-shadow 0.3s ease',
      }}
    >
      {/* Ambient colour glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse 80% 60% at 10% 50%, ${accentHex}14 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }} />

      {/* ── Main row ── */}
      <div
        style={{
          flex: 1,
          display: 'flex', alignItems: 'center',
          gap: 10, padding: '0 10px 0 12px',
          position: 'relative', zIndex: 1,
        }}
      >
        {/* Album art — click to expand */}
        <div
          onClick={onExpand}
          title="Open Now Playing"
          style={{ cursor: 'pointer', flexShrink: 0 }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={currentSong.id}
              initial={{ opacity: 0, scale: 0.80 }}
              animate={{ opacity: 1, scale: 1    }}
              exit={{    opacity: 0, scale: 0.80 }}
              transition={{ duration: 0.20, ease: EASE }}
            >
              <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Track info — click to expand */}
        <div
          onClick={onExpand}
          style={{ flex: 1, minWidth: 0, cursor: 'pointer' }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={`t-${currentSong.id}`}
              initial={{ opacity: 0, y: 4  }}
              animate={{ opacity: 1, y: 0  }}
              exit={{    opacity: 0, y: -4 }}
              transition={{ duration: 0.18 }}
            >
              <p style={{
                fontSize: 12, fontWeight: 600,
                color: 'var(--text-primary)',
                margin: 0, whiteSpace: 'nowrap',
                overflow: 'hidden', textOverflow: 'ellipsis',
              }}>
                {currentSong.title}
              </p>
              <p style={{
                fontSize: 10, color: 'var(--text-muted)',
                margin: 0, whiteSpace: 'nowrap',
                overflow: 'hidden', textOverflow: 'ellipsis',
              }}>
                {currentSong.artist}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 2, flexShrink: 0 }}>
          <PillBtn title="Previous" onClick={e => { e.stopPropagation(); playPrev() }}>
            &#9198;
          </PillBtn>
          <PillBtn primary title={isPlaying ? 'Pause' : 'Play'} onClick={e => { e.stopPropagation(); togglePlay() }}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </PillBtn>
          <PillBtn title="Next" onClick={e => { e.stopPropagation(); playNext() }}>
            &#9197;
          </PillBtn>
        </div>

        {/* Dismiss button */}
        <motion.button
          title="Close mini-player"
          onClick={e => { e.stopPropagation(); onClose() }}
          whileHover={{ scale: 1.18, rotate: 90 }}
          whileTap={{   scale: 0.85 }}
          style={{
            position: 'absolute', top: 6, right: 8,
            width: 18, height: 18, borderRadius: '50%',
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            color: 'var(--text-muted)', fontSize: 9,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          ✕
        </motion.button>
      </div>

      {/* ── Progress bar along bottom edge ── */}
      <div style={{
        height: 3,
        background: 'rgba(255,255,255,0.06)',
        flexShrink: 0, position: 'relative', zIndex: 1,
      }}>
        <motion.div
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
          style={{
            height: '100%',
            background: 'var(--accent-grad)',
            borderRadius: '0 2px 2px 0',
          }}
        />
      </div>
    </motion.div>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/MiniPlayer.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 2.  Patch Player.jsx
#
#     Add a "Pop out" (⊡) icon button to the right-side icon
#     row (the two existing ☰ ⊞ buttons at lines 277-282).
#     We insert it as a new Btn-less motion.button right after
#     the existing two icon buttons — takes an `onMiniPlayer`
#     prop passed down from Layout.
# ════════════════════════════════════════════════════════════
PLAYER="src/components/Player.jsx"

if [ ! -f "$PLAYER" ]; then
  echo -e "${YELLOW}  ⚠ $PLAYER not found — skipping patch${NC}"
else
python3 - "$PLAYER" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Add onMiniPlayer to Desktop Player props ────────────
old_props = "export default function Player({ mobile = false, onNowPlayingClick, screenSize = 'desktop' }) {"
new_props  = "export default function Player({ mobile = false, onNowPlayingClick, onMiniPlayer, screenSize = 'desktop' }) {"
if 'onMiniPlayer' not in src:
    src = src.replace(old_props, new_props, 1)

# ── B. Add pop-out button after the existing two icon buttons
# The existing block is:
#   {['\u2630', '\u229E'].map(icon => (
#     <motion.button key={icon} ...>{icon}</motion.button>
#   ))}
# We append our button right after the closing ))}
old_icons = (
    "          {['\\u2630', '\\u229E'].map(icon => (\n"
    "            <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }}\n"
    "              style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s', WebkitTapHighlightColor: 'transparent' }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >{icon}</motion.button>\n"
    "          ))}"
)
new_icons = (
    "          {['\\u2630', '\\u229E'].map(icon => (\n"
    "            <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }}\n"
    "              style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s', WebkitTapHighlightColor: 'transparent' }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >{icon}</motion.button>\n"
    "          ))}\n"
    "          {/* Mini-player pop-out */}\n"
    "          {onMiniPlayer && (\n"
    "            <motion.button\n"
    "              title='Pop out mini-player'\n"
    "              onClick={onMiniPlayer}\n"
    "              whileHover={{ scale: 1.15 }}\n"
    "              whileTap={{ scale: 0.90 }}\n"
    "              style={{\n"
    "                background: 'none', border: 'none',\n"
    "                color: 'var(--text-muted)', fontSize: 14,\n"
    "                cursor: 'pointer', transition: 'color 0.2s',\n"
    "                WebkitTapHighlightColor: 'transparent',\n"
    "              }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >\n"
    "              &#x229F;\n"
    "            </motion.button>\n"
    "          )}"
)
if 'Mini-player pop-out' not in src:
    src = src.replace(old_icons, new_icons, 1)

if src == original:
    print('  ⚠  Player.jsx — nothing changed (already patched?)')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Player.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Player.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 3.  Patch Layout.jsx
#
#     - Import MiniPlayer + AnimatePresence (already imported)
#     - Add showMini state
#     - Pass onMiniPlayer={() => setShowMini(true)} to all
#       three <Player> instances (desktop / tablet / mobile)
#     - Render <AnimatePresence><MiniPlayer /></AnimatePresence>
#       at the root level so it floats over everything
# ════════════════════════════════════════════════════════════
LAYOUT="src/components/Layout.jsx"

if [ ! -f "$LAYOUT" ]; then
  echo -e "${YELLOW}  ⚠ $LAYOUT not found — skipping patch${NC}"
else
python3 - "$LAYOUT" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Add MiniPlayer import after last existing import ────
last_import = "import PlaylistsPage from '../pages/PlaylistsPage'"

# Check if keyboard shortcuts were already added (CheatSheet import may be last)
if 'CheatSheet' in src:
    last_import = "import CheatSheet  from './CheatSheet'"
elif 'KeyFlash' in src:
    last_import = "import KeyFlash    from './KeyFlash'"
elif 'useKeyboardShortcuts' in src:
    last_import = "import { useKeyboardShortcuts } from '../hooks/useKeyboardShortcuts'"

mini_import = "\nimport MiniPlayer  from './MiniPlayer'"
if 'MiniPlayer' not in src:
    src = src.replace(last_import, last_import + mini_import, 1)

# ── B. Add showMini state after showCheatSheet (or activePage) ─
if 'showCheatSheet' in src:
    old_state = "  const [showCheatSheet, setShowCheatSheet] = useState(false)"
    new_state  = (
        "  const [showCheatSheet, setShowCheatSheet] = useState(false)\n"
        "  const [showMini,       setShowMini]       = useState(false)"
    )
else:
    old_state = "  const [activePage,     setActivePage]     = useState('Home')"
    new_state  = (
        "  const [activePage,     setActivePage]     = useState('Home')\n"
        "  const [showMini,       setShowMini]       = useState(false)"
    )
if 'showMini' not in src:
    src = src.replace(old_state, new_state, 1)

# ── C. Desktop <Player /> — add onMiniPlayer prop ─────────
old_desktop_player = "          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>\n            <Player />\n          </div>"
new_desktop_player = "          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>\n            <Player onMiniPlayer={() => setShowMini(true)} />\n          </div>"
if 'onMiniPlayer={() => setShowMini(true)}' not in src:
    src = src.replace(old_desktop_player, new_desktop_player, 1)

# ── D. Tablet <Player /> — add onMiniPlayer prop ──────────
old_tablet_player = "          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>\n            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />\n          </div>"
new_tablet_player = "          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>\n            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} />\n          </div>"
if old_tablet_player in src:
    src = src.replace(old_tablet_player, new_tablet_player, 1)

# ── E. Mobile <Player /> — add onMiniPlayer prop ──────────
old_mobile_player = "          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />"
new_mobile_player = "          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} />"
if old_mobile_player in src:
    src = src.replace(old_mobile_player, new_mobile_player, 1)

# ── F. Render MiniPlayer inside the root div ──────────────
# Insert after the KeyFlash + CheatSheet block if it exists,
# otherwise right after <YouTubePlayer />
if 'KeyFlash' in src:
    anchor = "      <CheatSheet open={showCheatSheet} onClose={() => setShowCheatSheet(false)} />"
    mini_render = (
        "\n\n"
        "      {/* Floating mini-player */}\n"
        "      <AnimatePresence>\n"
        "        {showMini && (\n"
        "          <MiniPlayer\n"
        "            onClose={() => setShowMini(false)}\n"
        "            onExpand={() => setShowMini(false)}\n"
        "          />\n"
        "        )}\n"
        "      </AnimatePresence>"
    )
else:
    anchor = "      <YouTubePlayer />"
    mini_render = (
        "\n\n"
        "      {/* Floating mini-player */}\n"
        "      <AnimatePresence>\n"
        "        {showMini && (\n"
        "          <MiniPlayer\n"
        "            onClose={() => setShowMini(false)}\n"
        "            onExpand={() => setShowMini(false)}\n"
        "          />\n"
        "        )}\n"
        "      </AnimatePresence>"
    )
if 'MiniPlayer' not in src or 'showMini &&' not in src:
    src = src.replace(anchor, anchor + mini_render, 1)

if src == original:
    print('  ⚠  Layout.jsx — nothing changed (already patched?)')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Layout.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Layout.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 4.  Summary
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Mini-Player installed successfully!            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created:${NC}"
echo -e "    + src/components/MiniPlayer.jsx"
echo ""
echo -e "  ${CYAN}Files patched:${NC}"
echo -e "    ~ src/components/Player.jsx    — ⊟ pop-out button in right toolbar"
echo -e "    ~ src/components/Layout.jsx    — showMini state + AnimatePresence render"
echo ""
echo -e "  ${CYAN}How to use:${NC}"
echo -e "    • Click the ⊟ button in the player bar (right side, after ☰ ⊞)"
echo -e "    • A 300×76px pill appears bottom-right — fully draggable"
echo -e "    • Prev / Play / Next controls inside the pill"
echo -e "    • Progress bar runs along the pill's bottom edge"
echo -e "    • Album art / title click → closes mini, focus returns to main"
echo -e "    • × button top-right of pill → dismisses it"
echo -e "    • Springs back inside viewport if dragged to edge"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
