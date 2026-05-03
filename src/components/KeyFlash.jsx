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
