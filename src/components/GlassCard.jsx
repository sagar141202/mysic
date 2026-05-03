/**
 * GlassCard — reusable glassmorphism container
 *
 * Props:
 *   variant   "default" | "elevated" | "inset"
 *   active    bool   — cyan highlight state
 *   hoverable bool   — enable hover lift
 *   glow      bool   — ambient cyan glow
 *   glowColor string — custom glow colour (default cyan)
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
  glowColor = 'rgba(34,211,238,',   // appended with alpha
  onClick,
  variant   = 'default',
}) {
  const c = glowColor.endsWith('(') ? glowColor : 'rgba(34,211,238,'   // safety

  const variants = {
    default: {
      bg:          'rgba(255,255,255,0.04)',
      bgHover:     'rgba(255,255,255,0.07)',
      border:      'rgba(255,255,255,0.07)',
      borderHover: `${c}0.26)`,
      shadow:      'none',
      shadowHover: `0 12px 32px ${c}0.12), 0 2px 8px rgba(0,0,0,0.18)`,
    },
    elevated: {
      bg:          'rgba(255,255,255,0.06)',
      bgHover:     'rgba(255,255,255,0.09)',
      border:      'rgba(255,255,255,0.10)',
      borderHover: `${c}0.32)`,
      shadow:      '0 4px 20px rgba(0,0,0,0.30), inset 0 1px 0 rgba(255,255,255,0.06)',
      shadowHover: `0 18px 44px ${c}0.14), inset 0 1px 0 ${c}0.08)`,
    },
    inset: {
      bg:          'rgba(0,0,0,0.20)',
      bgHover:     'rgba(0,0,0,0.15)',
      border:      'rgba(255,255,255,0.05)',
      borderHover: `${c}0.18)`,
      shadow:      'inset 0 1px 0 rgba(255,255,255,0.05)',
      shadowHover: `inset 0 1px 0 ${c}0.12)`,
    },
  }

  const v = variants[variant] || variants.default

  const base = {
    background:           active ? `${c}0.09)` : v.bg,
    backdropFilter:       'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    border:               `1px solid ${active ? `${c}0.38)` : v.border}`,
    borderRadius:         radius,
    // ← longer transition so hover feels buttery
    transition:           'background 0.30s ease, border-color 0.30s ease, transform 0.30s ease, box-shadow 0.30s ease',
    boxShadow: active
      ? `0 0 0 1px ${c}0.14), 0 8px 28px ${c}0.16), inset 0 1px 0 ${c}0.10)`
      : glow
      ? `0 0 32px ${c}0.12), inset 0 1px 0 rgba(255,255,255,0.06)`
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
    e.currentTarget.style.transform   = 'translateY(-3px) scale(1.005)'
    e.currentTarget.style.boxShadow   = v.shadowHover
  }

  const onLeave = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background  = v.bg
    e.currentTarget.style.borderColor = v.border
    e.currentTarget.style.transform   = 'translateY(0) scale(1)'
    e.currentTarget.style.boxShadow   = v.shadow
  }

  return (
    <div style={base} onMouseEnter={onEnter} onMouseLeave={onLeave} onClick={onClick}>
      {children}
    </div>
  )
}
