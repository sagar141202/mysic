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
