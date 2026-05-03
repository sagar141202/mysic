import { useState } from 'react'
import { motion } from 'framer-motion'

export default function AuthInput({
  label, type = 'text', value, onChange,
  placeholder, autoComplete, icon, error,
}) {
  const [focused,      setFocused]      = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const isPassword = type === 'password'
  const inputType  = isPassword ? (showPassword ? 'text' : 'password') : type

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      style={{ width: '100%', marginBottom: 4 }}
    >
      {label && (
        <label style={{
          display: 'block', fontSize: 11, fontWeight: 600,
          color: error ? '#f87171' : focused ? 'rgba(34,211,238,0.9)' : 'rgba(255,255,255,0.45)',
          letterSpacing: '0.08em', textTransform: 'uppercase',
          marginBottom: 7, transition: 'color 0.2s',
        }}>
          {label}
        </label>
      )}

      <div style={{ position: 'relative' }}>
        {/* Left icon */}
        {icon && (
          <span style={{
            position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
            fontSize: 15, pointerEvents: 'none', userSelect: 'none',
            color: error ? '#f87171' : focused ? 'rgba(34,211,238,0.8)' : 'rgba(255,255,255,0.3)',
            transition: 'color 0.2s', zIndex: 1,
          }}>
            {icon}
          </span>
        )}

        <input
          type={inputType}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          autoComplete={autoComplete}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            width: '100%', boxSizing: 'border-box',
            padding: `14px ${isPassword ? '46px' : '16px'} 14px ${icon ? '44px' : '16px'}`,
            background: error
              ? 'rgba(248,113,113,0.06)'
              : focused
                ? 'rgba(34,211,238,0.05)'
                : 'rgba(255,255,255,0.04)',
            border: `1.5px solid ${
              error   ? 'rgba(248,113,113,0.55)' :
              focused ? 'rgba(34,211,238,0.55)'  :
                        'rgba(255,255,255,0.09)'
            }`,
            borderRadius: 14,
            outline: 'none',
            color: 'rgba(255,255,255,0.92)',
            fontSize: 14,
            fontFamily: 'var(--font-body)',
            backdropFilter: 'blur(8px)',
            transition: 'all 0.22s ease',
            boxShadow: focused && !error
              ? '0 0 0 3px rgba(34,211,238,0.09), inset 0 1px 0 rgba(34,211,238,0.06)'
              : error
              ? '0 0 0 3px rgba(248,113,113,0.09)'
              : 'none',
            /* prevent iOS zoom */
            WebkitAppearance: 'none',
          }}
        />

        {/* Show/hide password toggle */}
        {isPassword && (
          <button
            type="button"
            onClick={() => setShowPassword(s => !s)}
            style={{
              position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
              background: 'none', border: 'none', cursor: 'pointer',
              color: 'rgba(255,255,255,0.35)', fontSize: 13, padding: '4px 6px',
              transition: 'color 0.18s',
              WebkitTapHighlightColor: 'transparent',
            }}
            onMouseEnter={e => e.currentTarget.style.color = 'rgba(255,255,255,0.7)'}
            onMouseLeave={e => e.currentTarget.style.color = 'rgba(255,255,255,0.35)'}
          >
            {showPassword ? '🙈' : '👁'}
          </button>
        )}
      </div>

      {/* Inline error */}
      {error && (
        <motion.p
          initial={{ opacity: 0, y: -4 }}
          animate={{ opacity: 1, y: 0 }}
          style={{ fontSize: 11, color: '#f87171', margin: '6px 0 0 2px', lineHeight: 1.4 }}
        >
          {error}
        </motion.p>
      )}
    </motion.div>
  )
}
