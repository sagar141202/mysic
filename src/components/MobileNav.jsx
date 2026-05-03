import { motion } from 'framer-motion'

const tabs = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
  { icon: '⊞', label: 'Playlists' },
]

export default function MobileNav({ activePage = 'Home', onNavigate }) {
  return (
    <nav
      role="navigation"
      aria-label="Main navigation"
      style={{
        display: 'flex',
        background: 'rgba(6,10,18,0.97)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        borderTop: '1px solid rgba(255,255,255,0.07)',
        /* safe-area: home bar on iPhone */
        paddingBottom: 'max(8px, env(safe-area-inset-bottom, 8px))',
        paddingTop: 4,
        /* prevent tap highlight flash on Android */
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {tabs.map(tab => {
        const active = activePage === tab.label
        return (
          <motion.button
            key={tab.label}
            aria-label={tab.label}
            aria-current={active ? 'page' : undefined}
            onClick={() => onNavigate?.(tab.label)}
            whileTap={{ scale: 0.88 }}
            style={{
              /* ≥44px tap target */
              flex: 1,
              minHeight: 44,
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              gap: 3,
              background: 'none', border: 'none',
              cursor: 'pointer',
              padding: '6px 4px',
              color: active ? 'var(--accent-primary)' : 'var(--text-muted)',
              transition: 'color 0.18s',
              fontFamily: 'var(--font-body)',
              WebkitTapHighlightColor: 'transparent',
              position: 'relative',
            }}
          >
            {/* Icon */}
            <span style={{
              fontSize: 20,
              lineHeight: 1,
              filter: active ? 'drop-shadow(0 0 7px rgba(34,211,238,0.65))' : 'none',
              transition: 'filter 0.2s',
            }}>
              {tab.icon}
            </span>

            {/* Label */}
            <span style={{
              fontSize: 10,
              fontWeight: active ? 600 : 400,
              letterSpacing: '0.03em',
              /* keep readable even on small phones */
              whiteSpace: 'nowrap',
            }}>
              {tab.label}
            </span>

            {/* Active dot */}
            {active && (
              <motion.span
                layoutId="nav-dot"
                style={{
                  position: 'absolute', bottom: 2,
                  width: 4, height: 4, borderRadius: '50%',
                  background: 'var(--accent-primary)',
                  boxShadow: '0 0 6px var(--accent-primary)',
                }}
              />
            )}
          </motion.button>
        )
      })}
    </nav>
  )
}
