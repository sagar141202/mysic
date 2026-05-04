/**
 * SleepTimerMenu — popover panel for the sleep timer.
 *
 * Props:
 *   remaining   number|null
 *   onStart     fn(mins)
 *   onCancel    fn()
 *   onClose     fn()
 */
import { useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const EASE = [0.25, 0.46, 0.45, 0.94]
const OPTIONS = [15, 30, 45, 60]

function fmt(secs) {
  const m = Math.floor(secs / 60)
  const s = secs % 60
  return `${m}:${String(s).padStart(2, '0')}`
}

/* Circular countdown ring */
function Ring({ pct, size = 44, stroke = 3 }) {
  const r = (size - stroke) / 2
  const circ = 2 * Math.PI * r
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r}
        stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} fill="none" />
      <circle cx={size/2} cy={size/2} r={r}
        stroke="var(--accent-primary)" strokeWidth={stroke} fill="none"
        strokeLinecap="round"
        strokeDasharray={circ}
        strokeDashoffset={circ * (1 - pct / 100)}
        style={{ transition: 'stroke-dashoffset 1s linear' }}
      />
    </svg>
  )
}

export default function SleepTimerMenu({ remaining, onStart, onCancel, onClose, initialMins }) {
  const ref = useRef(null)

  /* Close on outside click */
  useEffect(() => {
    const handler = e => {
      if (ref.current && !ref.current.contains(e.target)) onClose()
    }
    setTimeout(() => window.addEventListener('mousedown', handler), 0)
    return () => window.removeEventListener('mousedown', handler)
  }, [onClose])

  const pct = remaining !== null
    ? (remaining / (initialMins * 60)) * 100
    : 0

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 10, scale: 0.94 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: 6,  scale: 0.96 }}
      transition={{ duration: 0.20, ease: EASE }}
      style={{
        position: 'absolute',
        bottom: 'calc(100% + 12px)',
        right: 0,
        width: 220,
        background: 'rgba(8,12,20,0.96)',
        backdropFilter: 'blur(28px)',
        WebkitBackdropFilter: 'blur(28px)',
        border: '1px solid rgba(255,255,255,0.10)',
        borderRadius: 18,
        boxShadow: '0 20px 60px rgba(0,0,0,0.55), 0 0 0 1px rgba(34,211,238,0.07)',
        fontFamily: 'var(--font-body)',
        overflow: 'hidden',
        zIndex: 400,
      }}
    >
      {/* Header */}
      <div style={{
        padding: '14px 16px 10px',
        borderBottom: '1px solid rgba(255,255,255,0.06)',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{ fontSize: 16 }}>🌙</span>
        <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>
          Sleep Timer
        </span>
      </div>

      {/* Active timer display */}
      <AnimatePresence>
        {remaining !== null && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{    opacity: 0, height: 0 }}
            style={{
              overflow: 'hidden',
              borderBottom: '1px solid rgba(255,255,255,0.06)',
            }}
          >
            <div style={{
              padding: '16px',
              display: 'flex', alignItems: 'center', gap: 14,
            }}>
              {/* Circular ring countdown */}
              <div style={{ position: 'relative', flexShrink: 0 }}>
                <Ring pct={pct} size={52} stroke={3} />
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <span style={{ fontSize: 9, fontWeight: 700, color: 'var(--accent-primary)', fontVariantNumeric: 'tabular-nums' }}>
                    {fmt(remaining)}
                  </span>
                </div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: 12, color: 'var(--text-primary)', margin: '0 0 2px', fontWeight: 500 }}>
                  Pausing in
                </p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>
                  + 20s fade out
                </p>
              </div>
              <motion.button
                onClick={onCancel}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                style={{
                  background: 'rgba(255,80,80,0.12)',
                  border: '1px solid rgba(255,80,80,0.25)',
                  borderRadius: 8, padding: '4px 10px',
                  color: '#ff6b6b', fontSize: 11,
                  cursor: 'pointer', flexShrink: 0,
                  fontFamily: 'var(--font-body)',
                }}
              >
                Cancel
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Time options */}
      <div style={{ padding: '10px 10px 12px' }}>
        <p style={{
          fontSize: 10, fontWeight: 600, letterSpacing: '0.10em',
          color: 'var(--text-muted)', textTransform: 'uppercase',
          margin: '0 6px 8px',
        }}>
          {remaining !== null ? 'Change timer' : 'Set timer'}
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
          {OPTIONS.map(mins => (
            <motion.button
              key={mins}
              onClick={() => { onStart(mins); onClose() }}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.94 }}
              style={{
                background: remaining !== null && Math.round(remaining / 60) === mins
                  ? 'rgba(34,211,238,0.12)'
                  : 'rgba(255,255,255,0.04)',
                border: remaining !== null && Math.round(remaining / 60) === mins
                  ? '1px solid rgba(34,211,238,0.30)'
                  : '1px solid rgba(255,255,255,0.07)',
                borderRadius: 10,
                padding: '10px 0',
                color: remaining !== null && Math.round(remaining / 60) === mins
                  ? 'var(--accent-primary)'
                  : 'var(--text-secondary)',
                fontSize: 13, fontWeight: 500,
                cursor: 'pointer',
                fontFamily: 'var(--font-body)',
                transition: 'all 0.15s',
              }}
            >
              {mins} min
            </motion.button>
          ))}
        </div>
      </div>
    </motion.div>
  )
}
