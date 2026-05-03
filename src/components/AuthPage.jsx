import { useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '../context/AuthContext'
import AuthInput from './AuthInput'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── tiny helpers ─────────────────────────────────────────── */
function validate(mode, fields) {
  const errs = {}
  if (mode === 'signup' && !fields.name?.trim())
    errs.name = 'Name is required.'
  if (mode === 'signup' && fields.name?.trim().length < 2)
    errs.name = 'At least 2 characters.'
  if (!fields.email?.trim() || !fields.email.includes('@'))
    errs.email = 'Valid email required.'
  if (!fields.password || fields.password.length < 6)
    errs.password = 'Min 6 characters.'
  if (mode === 'signup' && fields.confirm !== fields.password)
    errs.confirm = 'Passwords do not match.'
  return errs
}

/* ── Orb background (matches rest of app) ──────────────────── */
function Orbs() {
  return (
    <div style={{ position: 'fixed', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 0 }}>
      <div style={{ position: 'absolute', top: '-18%', left: '-10%', width: 560, height: 560, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-1) 0%, transparent 70%)', filter: 'blur(55px)', animation: 'drift1 20s ease-in-out infinite alternate' }} />
      <div style={{ position: 'absolute', top: '35%', right: '-14%', width: 460, height: 460, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-2) 0%, transparent 70%)', filter: 'blur(55px)', animation: 'drift2 25s ease-in-out infinite alternate' }} />
      <div style={{ position: 'absolute', bottom: '-10%', left: '30%', width: 380, height: 380, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-3) 0%, transparent 70%)', filter: 'blur(55px)', animation: 'drift3 28s ease-in-out infinite alternate' }} />
    </div>
  )
}

/* ── Animated logo ──────────────────────────────────────────── */
function Logo() {
  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: EASE }}
      style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 36 }}
    >
      <motion.div
        animate={{ boxShadow: ['0 0 24px rgba(34,211,238,0.30)', '0 0 44px rgba(34,211,238,0.55)', '0 0 24px rgba(34,211,238,0.30)'] }}
        transition={{ duration: 2.8, repeat: Infinity, ease: 'easeInOut' }}
        style={{
          width: 58, height: 58, borderRadius: 18,
          background: 'var(--accent-grad)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 26, marginBottom: 14,
          boxShadow: '0 8px 28px rgba(34,211,238,0.35)',
        }}
      >
        ♫
      </motion.div>
      <h1 style={{
        fontFamily: 'var(--font-display)', fontSize: 36, fontWeight: 900,
        background: 'var(--accent-grad)',
        WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
        margin: 0, letterSpacing: '-1px', lineHeight: 1,
      }}>
        mysic
      </h1>
      <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.35)', marginTop: 7, letterSpacing: '0.18em', textTransform: 'uppercase' }}>
        your music, everywhere
      </p>
    </motion.div>
  )
}

/* ── Tab switcher ───────────────────────────────────────────── */
function Tabs({ mode, setMode }) {
  return (
    <div style={{
      display: 'flex', position: 'relative',
      background: 'rgba(255,255,255,0.04)',
      border: '1px solid rgba(255,255,255,0.08)',
      borderRadius: 12, padding: 3,
      marginBottom: 28,
    }}>
      {['login', 'signup'].map(m => (
        <button
          key={m}
          onClick={() => setMode(m)}
          style={{
            flex: 1, padding: '9px 0', border: 'none',
            borderRadius: 10, cursor: 'pointer',
            fontFamily: 'var(--font-body)', fontSize: 13, fontWeight: 600,
            letterSpacing: '0.04em',
            color: mode === m ? '#08121f' : 'rgba(255,255,255,0.45)',
            background: 'none',
            position: 'relative', zIndex: 1,
            transition: 'color 0.22s',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          {m === 'login' ? 'Sign In' : 'Create Account'}
        </button>
      ))}
      {/* sliding pill */}
      <motion.div
        layout
        style={{
          position: 'absolute',
          top: 3, bottom: 3,
          left: mode === 'login' ? 3 : '50%',
          width: 'calc(50% - 3px)',
          borderRadius: 9,
          background: 'var(--accent-grad)',
          boxShadow: '0 4px 14px rgba(34,211,238,0.35)',
          zIndex: 0,
        }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
      />
    </div>
  )
}

/* ── Submit button ──────────────────────────────────────────── */
function SubmitBtn({ loading, label }) {
  return (
    <motion.button
      type="submit"
      whileHover={loading ? {} : { scale: 1.02, boxShadow: '0 8px 32px rgba(34,211,238,0.50)' }}
      whileTap={loading ? {} : { scale: 0.97 }}
      disabled={loading}
      style={{
        width: '100%', padding: '15px 0', marginTop: 6,
        border: 'none', borderRadius: 14, cursor: loading ? 'default' : 'pointer',
        background: loading ? 'rgba(34,211,238,0.25)' : 'var(--accent-grad)',
        color: loading ? 'rgba(255,255,255,0.5)' : '#08121f',
        fontSize: 15, fontWeight: 700, fontFamily: 'var(--font-body)',
        letterSpacing: '0.05em',
        boxShadow: loading ? 'none' : '0 6px 22px rgba(34,211,238,0.38)',
        transition: 'background 0.2s, color 0.2s, box-shadow 0.2s',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {loading ? (
        <>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{ animation: 'spin 0.75s linear infinite' }}>
            <circle cx="12" cy="12" r="9" stroke="#08121f" strokeWidth="2.5" strokeLinecap="round" strokeDasharray="42 14" />
          </svg>
          {label}ing…
        </>
      ) : label}
    </motion.button>
  )
}

/* ── Divider ────────────────────────────────────────────────── */
function Divider({ text }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0' }}>
      <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.08)' }} />
      <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.25)', letterSpacing: '0.08em' }}>{text}</span>
      <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.08)' }} />
    </div>
  )
}

/* ── Demo shortcut ──────────────────────────────────────────── */
function DemoBtn({ onClick }) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
      style={{
        width: '100%', padding: '13px 0',
        border: '1.5px solid rgba(255,255,255,0.12)',
        borderRadius: 14, cursor: 'pointer',
        background: 'rgba(255,255,255,0.04)',
        backdropFilter: 'blur(12px)',
        color: 'rgba(255,255,255,0.70)',
        fontSize: 14, fontWeight: 500, fontFamily: 'var(--font-body)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        transition: 'border-color 0.2s, background 0.2s',
        WebkitTapHighlightColor: 'transparent',
      }}
      onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.35)'; e.currentTarget.style.background = 'rgba(34,211,238,0.05)' }}
      onMouseLeave={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.12)'; e.currentTarget.style.background = 'rgba(255,255,255,0.04)' }}
    >
      <span style={{ fontSize: 16 }}>⚡</span>
      Continue as Guest
    </motion.button>
  )
}

/* ── Global error banner ────────────────────────────────────── */
function ErrorBanner({ msg }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -8, scale: 0.97 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8 }}
      style={{
        padding: '11px 16px', borderRadius: 12, marginBottom: 16,
        background: 'rgba(248,113,113,0.10)',
        border: '1px solid rgba(248,113,113,0.35)',
        color: '#f87171', fontSize: 13, lineHeight: 1.5,
        display: 'flex', alignItems: 'flex-start', gap: 8,
      }}
    >
      <span style={{ flexShrink: 0, marginTop: 1 }}>⚠</span>
      <span>{msg}</span>
    </motion.div>
  )
}

/* ── Success flash ──────────────────────────────────────────── */
function SuccessBanner({ msg }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -8, scale: 0.97 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8 }}
      style={{
        padding: '11px 16px', borderRadius: 12, marginBottom: 16,
        background: 'rgba(34,211,238,0.10)',
        border: '1px solid rgba(34,211,238,0.35)',
        color: 'rgba(34,211,238,0.95)', fontSize: 13,
        display: 'flex', alignItems: 'center', gap: 8,
      }}
    >
      <span>✓</span>
      <span>{msg}</span>
    </motion.div>
  )
}

/* ═══════════════════════════════════════════════════════════
   Main AuthPage
═══════════════════════════════════════════════════════════ */
export default function AuthPage() {
  const { login, signup } = useAuth()
  const [mode,    setMode]    = useState('login')
  const [loading, setLoading] = useState(false)
  const [banner,  setBanner]  = useState(null)   // { type: 'error'|'success', msg }

  /* form fields */
  const [fields, setFields] = useState({ name: '', email: '', password: '', confirm: '' })
  const [errors, setErrors] = useState({})

  const set = (key) => (e) => {
    setFields(f => ({ ...f, [key]: e.target.value }))
    if (errors[key]) setErrors(e => ({ ...e, [key]: '' }))
    setBanner(null)
  }

  /* switch tabs — clear state */
  const switchMode = (m) => {
    setMode(m)
    setErrors({})
    setBanner(null)
    setFields({ name: '', email: '', password: '', confirm: '' })
  }

  /* guest demo — pre-fills a demo account */
  const handleGuest = useCallback(() => {
    const err = login('demo@mysic.app', 'demo123')
    if (err) {
      /* auto-create demo account if it doesn't exist yet */
      signup('Demo User', 'demo@mysic.app', 'demo123')
    }
  }, [login, signup])

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate(mode, fields)
    if (Object.keys(errs).length) { setErrors(errs); return }

    setLoading(true)
    setBanner(null)

    /* small artificial delay for UX polish */
    await new Promise(r => setTimeout(r, 520))

    let apiError = null
    if (mode === 'login') {
      apiError = login(fields.email, fields.password)
    } else {
      apiError = signup(fields.name, fields.email, fields.password)
    }

    setLoading(false)

    if (apiError) {
      setBanner({ type: 'error', msg: apiError })
    } else if (mode === 'signup') {
      setBanner({ type: 'success', msg: `Welcome to mysic, ${fields.name.split(' ')[0]}! 🎵` })
    }
  }

  return (
    <div style={{
      minHeight: '100dvh', width: '100vw',
      background: 'var(--bg-base)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'var(--font-body)',
      padding: '24px 16px',
      boxSizing: 'border-box',
      position: 'relative',
      overscrollBehavior: 'none',
    }}>
      <Orbs />

      {/* Card */}
      <motion.div
        initial={{ opacity: 0, y: 32, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.45, ease: EASE }}
        style={{
          width: '100%', maxWidth: 420,
          background: 'rgba(8,12,20,0.70)',
          backdropFilter: 'blur(32px)', WebkitBackdropFilter: 'blur(32px)',
          border: '1px solid rgba(255,255,255,0.09)',
          borderRadius: 24,
          padding: '36px 32px',
          position: 'relative', zIndex: 1,
          boxShadow: '0 40px 80px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.07)',
          /* prevent overflow on small screens */
          boxSizing: 'border-box',
        }}
      >
        {/* Top shimmer line */}
        <div style={{
          position: 'absolute', top: 0, left: '10%', right: '10%', height: 1,
          background: 'linear-gradient(90deg, transparent, rgba(34,211,238,0.45), transparent)',
          borderRadius: '0 0 4px 4px',
        }} />

        <Logo />
        <Tabs mode={mode} setMode={switchMode} />

        <AnimatePresence mode="wait">
          {banner?.type === 'error'   && <ErrorBanner   key="err" msg={banner.msg} />}
          {banner?.type === 'success' && <SuccessBanner key="ok"  msg={banner.msg} />}
        </AnimatePresence>

        <form onSubmit={handleSubmit} noValidate>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <AnimatePresence mode="wait">
              {mode === 'signup' && (
                <motion.div
                  key="name-field"
                  initial={{ opacity: 0, height: 0, marginBottom: 0 }}
                  animate={{ opacity: 1, height: 'auto', marginBottom: 0 }}
                  exit={{   opacity: 0, height: 0 }}
                  transition={{ duration: 0.22, ease: EASE }}
                  style={{ overflow: 'hidden' }}
                >
                  <AuthInput
                    label="Full Name"
                    type="text"
                    value={fields.name}
                    onChange={set('name')}
                    placeholder="Your name"
                    autoComplete="name"
                    icon="✦"
                    error={errors.name}
                  />
                </motion.div>
              )}
            </AnimatePresence>

            <AuthInput
              label="Email"
              type="email"
              value={fields.email}
              onChange={set('email')}
              placeholder="you@example.com"
              autoComplete={mode === 'login' ? 'username' : 'email'}
              icon="@"
              error={errors.email}
            />

            <AuthInput
              label="Password"
              type="password"
              value={fields.password}
              onChange={set('password')}
              placeholder={mode === 'signup' ? 'Min 6 characters' : '••••••••'}
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              icon="⬡"
              error={errors.password}
            />

            <AnimatePresence mode="wait">
              {mode === 'signup' && (
                <motion.div
                  key="confirm-field"
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{   opacity: 0, height: 0 }}
                  transition={{ duration: 0.22, ease: EASE }}
                  style={{ overflow: 'hidden' }}
                >
                  <AuthInput
                    label="Confirm Password"
                    type="password"
                    value={fields.confirm}
                    onChange={set('confirm')}
                    placeholder="Repeat password"
                    autoComplete="new-password"
                    icon="⬡"
                    error={errors.confirm}
                  />
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Forgot password (login only) */}
          <AnimatePresence>
            {mode === 'login' && (
              <motion.div
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                style={{ textAlign: 'right', marginTop: 8, marginBottom: 4 }}
              >
                <button
                  type="button"
                  style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, color: 'rgba(34,211,238,0.65)', fontFamily: 'var(--font-body)', transition: 'color 0.18s' }}
                  onMouseEnter={e => e.currentTarget.style.color = 'rgba(34,211,238,1)'}
                  onMouseLeave={e => e.currentTarget.style.color = 'rgba(34,211,238,0.65)'}
                >
                  Forgot password?
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          <div style={{ marginTop: 20 }}>
            <SubmitBtn loading={loading} label={mode === 'login' ? 'Sign In' : 'Create Account'} />
          </div>
        </form>

        <Divider text="or" />
        <DemoBtn onClick={handleGuest} />

        {/* Bottom note */}
        <motion.p
          initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.3 }}
          style={{ textAlign: 'center', fontSize: 11, color: 'rgba(255,255,255,0.22)', marginTop: 22, marginBottom: 0, lineHeight: 1.6 }}
        >
          {mode === 'login'
            ? <>No account? <span onClick={() => switchMode('signup')} style={{ color: 'rgba(34,211,238,0.65)', cursor: 'pointer' }}>Create one free</span></>
            : <>Already have an account? <span onClick={() => switchMode('login')} style={{ color: 'rgba(34,211,238,0.65)', cursor: 'pointer' }}>Sign in</span></>
          }
        </motion.p>
      </motion.div>
    </div>
  )
}
