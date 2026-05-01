export default function GlassCard({
  children,
  style = {},
  active = false,
  hoverable = true,
  radius = 20,
  padding,
  glow = false,
  onClick,
  className = '',
}) {
  const base = {
    background: active ? 'rgba(34,211,238,0.07)' : 'rgba(255,255,255,0.04)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    border: `1px solid ${active ? 'rgba(34,211,238,0.35)' : 'rgba(255,255,255,0.07)'}`,
    borderRadius: radius,
    transition: 'all 0.25s ease',
    boxShadow: active
      ? '0 0 0 1px rgba(34,211,238,0.15), 0 8px 24px rgba(34,211,238,0.1)'
      : glow
      ? '0 0 30px rgba(34,211,238,0.12)'
      : 'none',
    cursor: onClick ? 'pointer' : 'default',
    ...(padding !== undefined ? { padding } : {}),
    ...style,
  }

  const handleEnter = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background = 'rgba(255,255,255,0.07)'
    e.currentTarget.style.borderColor = 'rgba(34,211,238,0.2)'
    e.currentTarget.style.transform = 'translateY(-2px)'
    e.currentTarget.style.boxShadow = '0 14px 36px rgba(14,165,233,0.1)'
  }
  const handleLeave = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background = 'rgba(255,255,255,0.04)'
    e.currentTarget.style.borderColor = 'rgba(255,255,255,0.07)'
    e.currentTarget.style.transform = 'translateY(0)'
    e.currentTarget.style.boxShadow = 'none'
  }

  return (
    <div style={base} onMouseEnter={handleEnter} onMouseLeave={handleLeave} onClick={onClick}>
      {children}
    </div>
  )
}
