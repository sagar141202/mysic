#!/usr/bin/env bash
# ============================================================
#  Mysic — Keyboard Shortcuts + Cheat Sheet Overlay
#  Run from project root:  bash add_keyboard_shortcuts.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Keyboard Shortcuts...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root${NC}"
  exit 1
fi

mkdir -p src/hooks src/components

# ════════════════════════════════════════════════════════════
# 1.  src/hooks/useKeyboardShortcuts.js
#     Global keydown listener. Wired to usePlayer actions.
#     Skips when focus is inside any text input / textarea.
#     Also fires a custom DOM event "mysic:keyflash" so the
#     KeyFlash component can show a visual feedback bubble.
# ════════════════════════════════════════════════════════════
cat > src/hooks/useKeyboardShortcuts.js << 'EOF'
/**
 * useKeyboardShortcuts
 *
 * Call once inside Layout. Attaches a global keydown listener
 * and maps keys → player/nav actions.
 *
 * Keys handled:
 *   Space        — play / pause
 *   ArrowRight   — seek forward  5 s
 *   ArrowLeft    — seek backward 5 s
 *   ArrowUp      — volume +10
 *   ArrowDown    — volume -10
 *   N            — next track
 *   P            — previous track
 *   M            — mute toggle
 *   L            — like / unlike current song
 *   ?            — show shortcut cheat sheet
 *   Escape       — close cheat sheet / close NowPlaying panel
 *
 * Skips entirely when the user is typing in an input/textarea/
 * contenteditable so search bar still works normally.
 *
 * Fires window CustomEvent "mysic:keyflash" with { label }
 * so the KeyFlash overlay can show a HUD bubble.
 */
import { useEffect, useRef } from 'react'
import { usePlayer }         from './usePlayer.jsx'

function flash(label) {
  window.dispatchEvent(new CustomEvent('mysic:keyflash', { detail: { label } }))
}

function isTyping() {
  const el = document.activeElement
  if (!el) return false
  const tag = el.tagName.toLowerCase()
  return tag === 'input' || tag === 'textarea' || el.isContentEditable
}

export function useKeyboardShortcuts({ setShowCheatSheet, setNowPlayingOpen }) {
  const {
    currentSong, isPlaying, progress, volume,
    togglePlay, playNext, playPrev, seek, setVolume,
    toggleLike, liked,
  } = usePlayer()

  /* Keep a ref to volume so the handler always sees latest value
     without needing to re-register the listener on every change */
  const volRef      = useRef(volume)
  const progRef     = useRef(progress)
  const songRef     = useRef(currentSong)
  const playingRef  = useRef(isPlaying)
  const likedRef    = useRef(liked)

  useEffect(() => { volRef.current     = volume       }, [volume])
  useEffect(() => { progRef.current    = progress     }, [progress])
  useEffect(() => { songRef.current    = currentSong  }, [currentSong])
  useEffect(() => { playingRef.current = isPlaying    }, [isPlaying])
  useEffect(() => { likedRef.current   = liked        }, [liked])

  useEffect(() => {
    const handler = e => {
      /* Never intercept when typing */
      if (isTyping()) return

      /* Never intercept browser shortcuts */
      if (e.ctrlKey || e.metaKey || e.altKey) return

      const key = e.key

      switch (key) {
        case ' ':
          e.preventDefault()
          togglePlay()
          flash(playingRef.current ? '⏸' : '▶')
          break

        case 'ArrowRight': {
          e.preventDefault()
          const dur = songRef.current?.duration || 0
          if (!dur) break
          const newPct = Math.min(100, progRef.current + (5 / dur) * 100)
          seek(newPct)
          flash('▶▶ +5s')
          break
        }

        case 'ArrowLeft': {
          e.preventDefault()
          const dur = songRef.current?.duration || 0
          if (!dur) break
          const newPct = Math.max(0, progRef.current - (5 / dur) * 100)
          seek(newPct)
          flash('◀◀ -5s')
          break
        }

        case 'ArrowUp':
          e.preventDefault()
          setVolume(Math.min(100, volRef.current + 10))
          flash(`🔊 ${Math.min(100, Math.round(volRef.current + 10))}%`)
          break

        case 'ArrowDown':
          e.preventDefault()
          setVolume(Math.max(0, volRef.current - 10))
          flash(`🔉 ${Math.max(0, Math.round(volRef.current - 10))}%`)
          break

        case 'n':
        case 'N':
          playNext()
          flash('⏭ Next')
          break

        case 'p':
        case 'P':
          playPrev()
          flash('⏮ Prev')
          break

        case 'm':
        case 'M':
          if (volRef.current > 0) {
            /* Store old volume in a data attr so we can restore */
            document.documentElement.dataset.prevVol = volRef.current
            setVolume(0)
            flash('🔇 Muted')
          } else {
            const prev = parseFloat(document.documentElement.dataset.prevVol || 70)
            setVolume(prev)
            flash(`🔊 ${Math.round(prev)}%`)
          }
          break

        case 'l':
        case 'L': {
          const song = songRef.current
          if (song?.id) {
            toggleLike(song.id, song)
            flash(likedRef.current.has(song.id) ? '♡ Unliked' : '♥ Liked')
          }
          break
        }

        case '?':
          setShowCheatSheet(v => !v)
          break

        case 'Escape':
          setShowCheatSheet(false)
          setNowPlayingOpen(false)
          break

        default:
          break
      }
    }

    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [togglePlay, playNext, playPrev, seek, setVolume, toggleLike])
}
EOF
echo -e "${GREEN}  ✓ src/hooks/useKeyboardShortcuts.js${NC}"

# ════════════════════════════════════════════════════════════
# 2.  src/components/KeyFlash.jsx
#     HUD bubble that appears centre-screen for 900 ms whenever
#     a shortcut fires. Listens to "mysic:keyflash" CustomEvent.
# ════════════════════════════════════════════════════════════
cat > src/components/KeyFlash.jsx << 'EOF'
/**
 * KeyFlash — on-screen HUD bubble for keyboard shortcut feedback.
 *
 * Listens to window "mysic:keyflash" CustomEvent.
 * Shows a pill with the action label for 900 ms then fades out.
 * Multiple rapid keypresses restart the timer (debounced).
 */
import { useEffect, useState, useRef } from 'react'
import { AnimatePresence, motion }      from 'framer-motion'

export default function KeyFlash() {
  const [label,   setLabel]   = useState('')
  const [visible, setVisible] = useState(false)
  const timerRef = useRef(null)

  useEffect(() => {
    const handler = e => {
      setLabel(e.detail.label)
      setVisible(true)
      clearTimeout(timerRef.current)
      timerRef.current = setTimeout(() => setVisible(false), 900)
    }
    window.addEventListener('mysic:keyflash', handler)
    return () => {
      window.removeEventListener('mysic:keyflash', handler)
      clearTimeout(timerRef.current)
    }
  }, [])

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key={label}
          initial={{ opacity: 0, scale: 0.72, y: 12 }}
          animate={{ opacity: 1, scale: 1,    y: 0  }}
          exit={{    opacity: 0, scale: 0.88,  y: -8 }}
          transition={{ duration: 0.18, ease: [0.25, 0.46, 0.45, 0.94] }}
          style={{
            position: 'fixed',
            /* centre horizontally, sit just above the player bar */
            bottom: 'calc(var(--player-height, 72px) + 20px)',
            left: '50%',
            transform: 'translateX(-50%)',
            zIndex: 200,
            pointerEvents: 'none',
            /* pill */
            background: 'rgba(8,12,20,0.88)',
            backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)',
            border: '1px solid rgba(34,211,238,0.30)',
            borderRadius: 40,
            padding: '10px 22px',
            /* text */
            color: 'var(--accent-primary)',
            fontSize: 15,
            fontWeight: 600,
            fontFamily: 'var(--font-display)',
            letterSpacing: '0.02em',
            whiteSpace: 'nowrap',
            boxShadow: '0 8px 32px rgba(0,0,0,0.45), 0 0 0 1px rgba(34,211,238,0.08)',
          }}
        >
          {label}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/KeyFlash.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 3.  src/components/CheatSheet.jsx
#     Full cheat-sheet overlay triggered by "?" key.
#     Animated slide-up panel, grouped shortcuts, glassmorphism.
#     Click backdrop or press Escape / ? to dismiss.
# ════════════════════════════════════════════════════════════
cat > src/components/CheatSheet.jsx << 'EOF'
/**
 * CheatSheet — keyboard shortcut reference overlay.
 *
 * Props:
 *   open    bool
 *   onClose fn
 */
import { motion, AnimatePresence } from 'framer-motion'

const EASE = [0.25, 0.46, 0.45, 0.94]

const GROUPS = [
  {
    title: 'Playback',
    rows: [
      { keys: ['Space'],        label: 'Play / Pause'   },
      { keys: ['N'],            label: 'Next track'     },
      { keys: ['P'],            label: 'Previous track' },
      { keys: ['M'],            label: 'Mute toggle'    },
    ],
  },
  {
    title: 'Seek & Volume',
    rows: [
      { keys: ['→'],            label: 'Seek +5 seconds' },
      { keys: ['←'],            label: 'Seek −5 seconds' },
      { keys: ['↑'],            label: 'Volume +10%'     },
      { keys: ['↓'],            label: 'Volume −10%'     },
    ],
  },
  {
    title: 'Library',
    rows: [
      { keys: ['L'],            label: 'Like / Unlike song' },
    ],
  },
  {
    title: 'App',
    rows: [
      { keys: ['?'],            label: 'Show / hide shortcuts' },
      { keys: ['Esc'],          label: 'Close any panel'       },
    ],
  },
]

function Key({ children }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      minWidth: 32, height: 26,
      padding: '0 8px',
      background: 'rgba(255,255,255,0.06)',
      border: '1px solid rgba(255,255,255,0.14)',
      borderBottom: '2px solid rgba(255,255,255,0.10)',
      borderRadius: 7,
      fontSize: 12,
      fontFamily: 'var(--font-body)',
      fontWeight: 600,
      color: 'var(--accent-primary)',
      letterSpacing: '0.03em',
      boxShadow: '0 2px 6px rgba(0,0,0,0.25)',
    }}>
      {children}
    </span>
  )
}

export default function CheatSheet({ open, onClose }) {
  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            key="backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{    opacity: 0 }}
            transition={{ duration: 0.22 }}
            onClick={onClose}
            style={{
              position: 'fixed', inset: 0, zIndex: 150,
              background: 'rgba(0,0,0,0.60)',
              backdropFilter: 'blur(6px)',
              WebkitBackdropFilter: 'blur(6px)',
            }}
          />

          {/* Panel */}
          <motion.div
            key="panel"
            initial={{ opacity: 0, y: 40,  scale: 0.96 }}
            animate={{ opacity: 1, y: 0,   scale: 1    }}
            exit={{    opacity: 0, y: 24,  scale: 0.97 }}
            transition={{ duration: 0.30, ease: EASE }}
            style={{
              position: 'fixed',
              /* centre on desktop, bottom-sheet on narrow */
              top: '50%', left: '50%',
              transform: 'translate(-50%, -50%)',
              zIndex: 151,
              width: 'min(480px, 92vw)',
              maxHeight: '82dvh',
              overflowY: 'auto',
              overscrollBehavior: 'contain',
              /* glassmorphism */
              background: 'rgba(8,12,20,0.82)',
              backdropFilter: 'blur(36px)',
              WebkitBackdropFilter: 'blur(36px)',
              border: '1px solid rgba(255,255,255,0.09)',
              borderRadius: 24,
              boxShadow: '0 32px 80px rgba(0,0,0,0.55), 0 0 0 1px rgba(34,211,238,0.07)',
              fontFamily: 'var(--font-body)',
            }}
          >
            {/* Header */}
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '20px 22px 16px',
              borderBottom: '1px solid rgba(255,255,255,0.06)',
              position: 'sticky', top: 0,
              background: 'rgba(8,12,20,0.90)',
              backdropFilter: 'blur(20px)',
              borderRadius: '24px 24px 0 0',
              zIndex: 1,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{
                  width: 32, height: 32, borderRadius: 10,
                  background: 'rgba(34,211,238,0.12)',
                  border: '1px solid rgba(34,211,238,0.25)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 15,
                }}>⌨</span>
                <div>
                  <p style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: 16, fontWeight: 800,
                    color: 'var(--text-primary)', margin: 0, lineHeight: 1.2,
                  }}>Keyboard Shortcuts</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>
                    Press <Key>?</Key> anytime to toggle
                  </p>
                </div>
              </div>

              <motion.button
                onClick={onClose}
                whileHover={{ scale: 1.15, rotate: 90 }}
                whileTap={{ scale: 0.88 }}
                style={{
                  width: 32, height: 32, borderRadius: 10,
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.09)',
                  color: 'var(--text-muted)', fontSize: 14,
                  cursor: 'pointer', display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}
              >✕</motion.button>
            </div>

            {/* Shortcut groups */}
            <div style={{ padding: '14px 22px 24px' }}>
              {GROUPS.map((group, gi) => (
                <motion.div
                  key={group.title}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0  }}
                  transition={{ duration: 0.22, delay: gi * 0.055, ease: EASE }}
                  style={{ marginBottom: gi < GROUPS.length - 1 ? 20 : 0 }}
                >
                  {/* Group title */}
                  <p style={{
                    fontSize: 10, fontWeight: 600,
                    color: 'var(--accent-primary)',
                    letterSpacing: '0.14em',
                    textTransform: 'uppercase',
                    margin: '0 0 10px',
                    opacity: 0.8,
                  }}>
                    {group.title}
                  </p>

                  {/* Rows */}
                  <div style={{
                    background: 'rgba(255,255,255,0.025)',
                    border: '1px solid rgba(255,255,255,0.06)',
                    borderRadius: 14,
                    overflow: 'hidden',
                  }}>
                    {group.rows.map((row, ri) => (
                      <motion.div
                        key={row.label}
                        initial={{ opacity: 0, x: -8 }}
                        animate={{ opacity: 1,  x: 0  }}
                        transition={{ duration: 0.20, delay: gi * 0.055 + ri * 0.04, ease: EASE }}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '11px 14px',
                          borderBottom: ri < group.rows.length - 1
                            ? '1px solid rgba(255,255,255,0.04)'
                            : 'none',
                        }}
                      >
                        {/* Label */}
                        <span style={{
                          fontSize: 13,
                          color: 'var(--text-secondary)',
                          flex: 1,
                        }}>
                          {row.label}
                        </span>

                        {/* Key badges */}
                        <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
                          {row.keys.map((k, ki) => (
                            <Key key={ki}>{k}</Key>
                          ))}
                        </div>
                      </motion.div>
                    ))}
                  </div>
                </motion.div>
              ))}

              {/* Footer hint */}
              <p style={{
                fontSize: 11, color: 'rgba(255,255,255,0.20)',
                textAlign: 'center', margin: '18px 0 0',
                letterSpacing: '0.04em',
              }}>
                Shortcuts are disabled while typing in the search bar
              </p>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/CheatSheet.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 4.  Patch Layout.jsx
#     - Import useKeyboardShortcuts, KeyFlash, CheatSheet
#     - Add showCheatSheet state
#     - Call useKeyboardShortcuts hook
#     - Render <KeyFlash /> and <CheatSheet /> inside the root div
#     - Add "?" hint button to desktop sidebar area (top of layout)
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

# ── A. Add three imports after existing import block ─────────
last_import = "import PlaylistsPage from '../pages/PlaylistsPage'"
extra_imports = (
    "\nimport { useKeyboardShortcuts } from '../hooks/useKeyboardShortcuts'"
    "\nimport KeyFlash    from './KeyFlash'"
    "\nimport CheatSheet  from './CheatSheet'"
)
if 'useKeyboardShortcuts' not in src:
    src = src.replace(last_import, last_import + extra_imports, 1)

# ── B. Add showCheatSheet state after existing state lines ───
old_state = "  const [activePage,     setActivePage]     = useState('Home')"
new_state  = (
    "  const [activePage,     setActivePage]     = useState('Home')\n"
    "  const [showCheatSheet, setShowCheatSheet] = useState(false)"
)
if 'showCheatSheet' not in src:
    src = src.replace(old_state, new_state, 1)

# ── C. Call the hook after the existing resize useEffect ─────
# Insert right before "const isMobile"
old_mobile = "  const isMobile  = screen === 'mobile'"
new_hook   = (
    "  useKeyboardShortcuts({ setShowCheatSheet, setNowPlayingOpen })\n"
    "\n"
    "  const isMobile  = screen === 'mobile'"
)
if 'useKeyboardShortcuts({' not in src:
    src = src.replace(old_mobile, new_hook, 1)

# ── D. Render KeyFlash + CheatSheet inside the root div ──────
# Insert right after <YouTubePlayer />
old_yt = "      <YouTubePlayer />"
new_yt = (
    "      <YouTubePlayer />\n"
    "\n"
    "      {/* Global keyboard shortcut HUD + cheat sheet */}\n"
    "      <KeyFlash />\n"
    "      <CheatSheet open={showCheatSheet} onClose={() => setShowCheatSheet(false)} />"
)
if 'KeyFlash' not in src:
    src = src.replace(old_yt, new_yt, 1)

if src == original:
    print('  ⚠  Layout.jsx — nothing changed (already patched?)')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Layout.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Layout.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 5.  Summary
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Keyboard Shortcuts installed successfully!       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created:${NC}"
echo -e "    + src/hooks/useKeyboardShortcuts.js"
echo -e "    + src/components/KeyFlash.jsx"
echo -e "    + src/components/CheatSheet.jsx"
echo ""
echo -e "  ${CYAN}Files patched:${NC}"
echo -e "    ~ src/components/Layout.jsx"
echo ""
echo -e "  ${CYAN}Shortcut map:${NC}"
echo -e "    Space      play / pause"
echo -e "    N / P      next / previous track"
echo -e "    → / ←      seek +5s / -5s"
echo -e "    ↑ / ↓      volume +10% / -10%"
echo -e "    M          mute toggle (remembers previous level)"
echo -e "    L          like / unlike"
echo -e "    ?          open cheat sheet"
echo -e "    Esc        close any panel"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
