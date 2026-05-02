/**
 * GlassCard — reusable glassmorphism container
 *
 * Props:
 *   variant   "default" | "elevated" | "inset"
 *   active    bool   — cyan highlight state
 *   hoverable bool   — enable hover lift
 *   glow      bool   — ambient cyan glow
 *   radius    number — border radius in px
 *   padding   string — css padding shorthand
 *   onClick   fn     — makes cursor pointer
 *   style     obj    — extra inline styles
 */
export default function GlassCard({
  children,
  style     = {},
  active    = false,
  hoverable = true,
  radius    = 20,
  padding,
  glow      = false,
  onClick,
  variant   = 'default',
}) {
  const variants = {
    default: {
      bg:          'rgba(255,255,255,0.04)',
      bgHover:     'rgba(255,255,255,0.07)',
      border:      'rgba(255,255,255,0.07)',
      borderHover: 'rgba(34,211,238,0.22)',
      shadow:      'none',
      shadowHover: '0 12px 32px rgba(14,165,233,0.10)',
    },
    elevated: {
      bg:          'rgba(255,255,255,0.06)',
      bgHover:     'rgba(255,255,255,0.09)',
      border:      'rgba(255,255,255,0.10)',
      borderHover: 'rgba(34,211,238,0.28)',
      shadow:      '0 4px 20px rgba(0,0,0,0.30), inset 0 1px 0 rgba(255,255,255,0.06)',
      shadowHover: '0 16px 40px rgba(14,165,233,0.12), inset 0 1px 0 rgba(34,211,238,0.08)',
    },
    inset: {
      bg:          'rgba(0,0,0,0.20)',
      bgHover:     'rgba(0,0,0,0.15)',
      border:      'rgba(255,255,255,0.05)',
      borderHover: 'rgba(34,211,238,0.15)',
      shadow:      'inset 0 1px 0 rgba(255,255,255,0.05)',
      shadowHover: 'inset 0 1px 0 rgba(34,211,238,0.10)',
    },
  }

  const v = variants[variant] || variants.default

  const base = {
    background:           active ? 'rgba(34,211,238,0.07)' : v.bg,
    backdropFilter:       'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    border:               `1px solid ${active ? 'rgba(34,211,238,0.35)' : v.border}`,
    borderRadius:         radius,
    transition:           'background 0.25s ease, border-color 0.25s ease, transform 0.25s ease, box-shadow 0.25s ease',
    boxShadow: active
      ? '0 0 0 1px rgba(34,211,238,0.12), 0 8px 28px rgba(34,211,238,0.12), inset 0 1px 0 rgba(34,211,238,0.08)'
      : glow
      ? '0 0 28px rgba(34,211,238,0.10), inset 0 1px 0 rgba(255,255,255,0.06)'
      : v.shadow,
    cursor:   onClick ? 'pointer' : 'default',
    position: 'relative',
    ...(padding !== undefined ? { padding } : {}),
    ...style,
  }

  const onEnter = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background  = v.bgHover
    e.currentTarget.style.borderColor = v.borderHover
    e.currentTarget.style.transform   = 'translateY(-2px)'
    e.currentTarget.style.boxShadow   = v.shadowHover
  }

  const onLeave = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background  = v.bg
    e.currentTarget.style.borderColor = v.border
    e.currentTarget.style.transform   = 'translateY(0)'
    e.currentTarget.style.boxShadow   = v.shadow
  }

  return (
    <div style={base} onMouseEnter={onEnter} onMouseLeave={onLeave} onClick={onClick}>
      {children}
    </div>
  )
}