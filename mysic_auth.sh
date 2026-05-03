#!/usr/bin/env bash
# ============================================================
#  mysic_auth.sh
#  Adds a full Login / Signup flow to Mysic
#
#  Creates:
#    src/context/AuthContext.jsx   — auth state + localStorage
#    src/components/AuthPage.jsx   — login + signup screens
#    src/components/AuthInput.jsx  — reusable input component
#    src/App.jsx (patch)           — gate Layout behind auth
#
#  Run from project root:
#    bash mysic_auth.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✅  $1${RESET}"; }
msg()  { echo -e "${CYAN}➜   $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠️   $1${RESET}"; }

mkdir -p src/context src/components

# ============================================================
# 1.  AuthContext.jsx
#     Stores user in localStorage, exposes login/signup/logout
# ============================================================
msg "Writing src/context/AuthContext.jsx …"
cat > src/context/AuthContext.jsx << 'EOF'
import { createContext, useContext, useState, useCallback } from 'react'

const AuthContext = createContext(null)

const STORAGE_KEY = 'mysic_user'
const USERS_KEY   = 'mysic_users'   // simple "db" stored as JSON

/* ── helpers ─────────────────────────────────────────────── */
const loadUsers  = () => { try { return JSON.parse(localStorage.getItem(USERS_KEY) || '{}') } catch { return {} } }
const saveUsers  = (u) => localStorage.setItem(USERS_KEY, JSON.stringify(u))
const loadMe     = () => { try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null') } catch { return null } }
const saveMe     = (u) => u ? localStorage.setItem(STORAGE_KEY, JSON.stringify(u)) : localStorage.removeItem(STORAGE_KEY)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(loadMe)

  /* Returns null on success, error string on failure */
  const signup = useCallback((name, email, password) => {
    name     = name.trim()
    email    = email.trim().toLowerCase()
    password = password.trim()

    if (!name || name.length < 2)         return 'Name must be at least 2 characters.'
    if (!email.includes('@'))             return 'Please enter a valid email.'
    if (password.length < 6)             return 'Password must be at least 6 characters.'

    const users = loadUsers()
    if (users[email])                    return 'An account with this email already exists.'

    const newUser = { name, email, avatar: name[0].toUpperCase(), createdAt: Date.now() }
    users[email]  = { ...newUser, password }   // plain-text is fine for a demo app
    saveUsers(users)
    saveMe(newUser)
    setUser(newUser)
    return null
  }, [])

  const login = useCallback((email, password) => {
    email    = email.trim().toLowerCase()
    password = password.trim()

    if (!email || !password)             return 'Please fill in all fields.'

    const users = loadUsers()
    const found = users[email]
    if (!found)                          return 'No account found with that email.'
    if (found.password !== password)     return 'Incorrect password.'

    const me = { name: found.name, email: found.email, avatar: found.avatar, createdAt: found.createdAt }
    saveMe(me)
    setUser(me)
    return null
  }, [])

  const logout = useCallback(() => {
    saveMe(null)
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, login, signup, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
EOF
ok "src/context/AuthContext.jsx"

# ============================================================
# 2.  AuthInput.jsx — reusable animated input
# ============================================================
msg "Writing src/components/AuthInput.jsx …"
cat > src/components/AuthInput.jsx << 'EOF'
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
EOF
ok "src/components/AuthInput.jsx"

# ============================================================
# 3.  AuthPage.jsx — full login + signup UI
# ============================================================
msg "Writing src/components/AuthPage.jsx …"
cat > src/components/AuthPage.jsx << 'EOF'
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
EOF
ok "src/components/AuthPage.jsx"

# ============================================================
# 4.  Patch App.jsx to gate Layout behind auth
#     Tries to find App.jsx or main.jsx and inject the guard
# ============================================================
msg "Patching App.jsx …"

APP_FILE=""
for f in src/App.jsx src/app.jsx src/App.tsx; do
  [ -f "$f" ] && { APP_FILE="$f"; break; }
done

if [ -n "$APP_FILE" ]; then
  # Backup
  cp "$APP_FILE" "${APP_FILE}.bak"

  cat > "$APP_FILE" << 'EOF'
import { AuthProvider, useAuth } from './context/AuthContext'
import AuthPage from './components/AuthPage'
import Layout   from './components/Layout'

function AppShell() {
  const { user } = useAuth()
  return user ? <Layout /> : <AuthPage />
}

export default function App() {
  return (
    <AuthProvider>
      <AppShell />
    </AuthProvider>
  )
}
EOF
  ok "App.jsx patched (backup → App.jsx.bak)"
else
  warn "App.jsx not found. Add the following manually:"
  cat << 'MANUAL'
// In your App.jsx:
import { AuthProvider, useAuth } from './context/AuthContext'
import AuthPage from './components/AuthPage'
import Layout   from './components/Layout'

function AppShell() {
  const { user } = useAuth()
  return user ? <Layout /> : <AuthPage />
}

export default function App() {
  return (
    <AuthProvider>
      <AppShell />
    </AuthProvider>
  )
}
MANUAL
fi

# ============================================================
# 5.  Add UserMenu to Sidebar — shows avatar + logout button
# ============================================================
msg "Writing Sidebar.jsx with logout support …"
cat > src/components/Sidebar.jsx << 'EOF'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import GlassCard from './GlassCard'
import { useAuth } from '../context/AuthContext'

const nav = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
  { icon: '⊞', label: 'Playlists' },
]

export default function Sidebar({ collapsed = false, onClose, activePage, onNavigate }) {
  const { user, logout } = useAuth()
  const [showLogout, setShowLogout] = useState(false)

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      padding: collapsed ? '20px 10px' : '22px 14px',
      background: 'rgba(8,12,20,0.65)',
      backdropFilter: 'blur(28px)', WebkitBackdropFilter: 'blur(28px)',
      borderRight: '1px solid rgba(255,255,255,0.06)',
      fontFamily: 'var(--font-body)', overflowY: 'auto', overflowX: 'hidden',
    }}>

      {/* Logo */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: collapsed ? 'center' : 'flex-start', padding: collapsed ? '0 0 24px' : '0 6px 24px' }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, flexShrink: 0, background: 'var(--accent-grad)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, boxShadow: '0 4px 16px rgba(34,211,238,0.28)' }}>♫</div>
        {!collapsed && <span style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 800, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text', letterSpacing: '-0.5px' }}>mysic</span>}
        {onClose && !collapsed && (
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 18, cursor: 'pointer', transition: 'color 0.2s' }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >✕</button>
        )}
      </div>

      {/* Nav */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {nav.map(item => {
          const active = activePage === item.label
          return (
            <button key={item.label} onClick={() => onNavigate(item.label)} title={collapsed ? item.label : ''} style={{
              display: 'flex', alignItems: 'center', gap: collapsed ? 0 : 10,
              justifyContent: collapsed ? 'center' : 'flex-start',
              padding: collapsed ? '10px 8px' : '10px 12px',
              borderRadius: 12, width: '100%',
              border: active ? '1px solid rgba(34,211,238,0.28)' : '1px solid transparent',
              background: active ? 'rgba(34,211,238,0.07)' : 'transparent',
              color: active ? 'var(--accent-primary)' : 'var(--text-secondary)',
              cursor: 'pointer', fontSize: 13, fontFamily: 'var(--font-body)',
              fontWeight: active ? 500 : 400, transition: 'all 0.2s ease',
              boxShadow: active ? '0 2px 12px rgba(34,211,238,0.07)' : 'none',
              minHeight: 42,
            }}
            onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.color = 'var(--text-primary)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
            onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--text-secondary)'; e.currentTarget.style.borderColor = 'transparent' }}}
            >
              <span style={{ fontSize: 17, width: collapsed ? 'auto' : 20, textAlign: 'center', flexShrink: 0 }}>{item.icon}</span>
              {!collapsed && <span style={{ whiteSpace: 'nowrap' }}>{item.label}</span>}
              {!collapsed && active && <div style={{ marginLeft: 'auto', width: 5, height: 5, borderRadius: '50%', background: 'var(--accent-primary)', boxShadow: '0 0 8px var(--accent-primary)', animation: 'pulse-glow 2s infinite' }} />}
            </button>
          )
        })}
      </nav>

      {/* Divider + Playlists */}
      {!collapsed && (
        <>
          <div style={{ margin: '20px 0 14px', borderTop: '1px solid rgba(255,255,255,0.06)' }} />
          <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', padding: '0 12px 10px', textTransform: 'uppercase' }}>Playlists</p>
          <div style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 1 }}>
            {[{ name: 'Late Night Drive', count: '6 songs' }, { name: 'Workout Beast', count: '5 songs' }, { name: 'Chill Sunday', count: '5 songs' }, { name: 'Bollywood Fire', count: '6 songs' }, { name: 'Deep Focus', count: '4 songs' }].map(p => (
              <button key={p.name} onClick={() => onNavigate('Playlists')} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', borderRadius: 10, border: '1px solid transparent', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', width: '100%', fontFamily: 'var(--font-body)', textAlign: 'left', transition: 'all 0.2s ease', minHeight: 42 }}
                onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.color = 'var(--text-primary)' }}
                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent'; e.currentTarget.style.color = 'var(--text-secondary)' }}
              >
                <div style={{ width: 28, height: 28, borderRadius: 8, flexShrink: 0, background: 'rgba(34,211,238,0.07)', border: '1px solid rgba(34,211,238,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12 }}>♪</div>
                <div style={{ minWidth: 0 }}>
                  <p style={{ fontSize: 13, margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.name}</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>{p.count}</p>
                </div>
              </button>
            ))}
          </div>
        </>
      )}

      {/* User card with logout */}
      <div style={{ marginTop: 16, position: 'relative' }}>
        <GlassCard
          padding="10px 12px" radius={14} hoverable={!collapsed}
          onClick={() => !collapsed && setShowLogout(s => !s)}
          style={{
            display: 'flex', alignItems: 'center',
            gap: collapsed ? 0 : 10,
            justifyContent: collapsed ? 'center' : 'flex-start',
            boxShadow: '0 2px 12px rgba(0,0,0,0.20), inset 0 1px 0 rgba(255,255,255,0.05)',
            cursor: collapsed ? 'default' : 'pointer',
          }}
        >
          {/* Avatar circle */}
          <div style={{
            width: 30, height: 30, borderRadius: '50%', flexShrink: 0,
            background: 'var(--accent-grad)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 700, color: '#08121f',
          }}>
            {user?.avatar || '?'}
          </div>

          {!collapsed && (
            <>
              <div style={{ minWidth: 0, flex: 1 }}>
                <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {user?.name || 'Guest'}
                </p>
                <p style={{ fontSize: 10, color: 'var(--accent-primary)', margin: 0 }}>Premium ✦</p>
              </div>
              <motion.span
                animate={{ rotate: showLogout ? 180 : 0 }}
                style={{ color: 'var(--text-muted)', fontSize: 12, flexShrink: 0 }}
              >
                ▾
              </motion.span>
            </>
          )}
        </GlassCard>

        {/* Logout dropdown */}
        <AnimatePresence>
          {showLogout && !collapsed && (
            <motion.div
              initial={{ opacity: 0, y: 6, scale: 0.97 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{   opacity: 0, y: 6, scale: 0.97 }}
              transition={{ duration: 0.18 }}
              style={{
                position: 'absolute', bottom: 'calc(100% + 6px)', left: 0, right: 0,
                background: 'rgba(8,12,20,0.95)',
                backdropFilter: 'blur(20px)',
                border: '1px solid rgba(255,255,255,0.10)',
                borderRadius: 14, overflow: 'hidden',
                boxShadow: '0 -12px 32px rgba(0,0,0,0.35)',
                zIndex: 10,
              }}
            >
              {/* User info row */}
              <div style={{ padding: '12px 14px 10px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', margin: 0 }}>{user?.name}</p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: '2px 0 0' }}>{user?.email}</p>
              </div>

              {/* Actions */}
              {[
                { icon: '⚙', label: 'Settings' },
                { icon: '🔒', label: 'Sign Out', danger: true, action: logout },
              ].map(item => (
                <button
                  key={item.label}
                  onClick={() => { item.action?.(); setShowLogout(false) }}
                  style={{
                    width: '100%', padding: '11px 14px',
                    display: 'flex', alignItems: 'center', gap: 10,
                    background: 'none', border: 'none', cursor: 'pointer',
                    color: item.danger ? '#f87171' : 'var(--text-secondary)',
                    fontSize: 13, fontFamily: 'var(--font-body)',
                    textAlign: 'left', transition: 'background 0.15s, color 0.15s',
                    WebkitTapHighlightColor: 'transparent',
                  }}
                  onMouseEnter={e => { e.currentTarget.style.background = item.danger ? 'rgba(248,113,113,0.08)' : 'rgba(255,255,255,0.05)'; e.currentTarget.style.color = item.danger ? '#f87171' : 'var(--text-primary)' }}
                  onMouseLeave={e => { e.currentTarget.style.background = 'none'; e.currentTarget.style.color = item.danger ? '#f87171' : 'var(--text-secondary)' }}
                >
                  <span style={{ fontSize: 15, width: 20, textAlign: 'center' }}>{item.icon}</span>
                  {item.label}
                </button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

    </div>
  )
}
EOF
ok "Sidebar.jsx updated with logout"

# ============================================================
# 6.  Add @keyframes spin to CSS (needed for loading spinner)
# ============================================================
CSS_FILE=""
for f in src/index.css src/App.css src/styles/global.css; do
  [ -f "$f" ] && { CSS_FILE="$f"; break; }
done

if [ -n "$CSS_FILE" ] && ! grep -q "@keyframes spin" "$CSS_FILE"; then
  msg "Injecting @keyframes spin into $CSS_FILE …"
  printf '\n@keyframes spin {\n  from { transform: rotate(0deg); }\n  to   { transform: rotate(360deg); }\n}\n' >> "$CSS_FILE"
  ok "@keyframes spin added"
fi

# ============================================================
# Done
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅  Auth system added to Mysic!                           ║${RESET}"
echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${RESET}"
echo -e "${GREEN}║  AuthContext.jsx   localStorage login/signup/logout          ║${RESET}"
echo -e "${GREEN}║  AuthPage.jsx      animated login + signup card              ║${RESET}"
echo -e "${GREEN}║  AuthInput.jsx     reusable input with validation            ║${RESET}"
echo -e "${GREEN}║  Sidebar.jsx       user avatar + logout dropdown             ║${RESET}"
echo -e "${GREEN}║  App.jsx           auth-gated Layout                         ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}Features:${RESET}"
echo -e "  • Login / Sign Up tabs with sliding pill indicator"
echo -e "  • Per-field inline validation (client-side)"
echo -e "  • Password show/hide toggle"
echo -e "  • Error + success banners"
echo -e "  • ⚡ Continue as Guest (auto-creates demo account)"
echo -e "  • Forgot password button (hookable)"
echo -e "  • Logout dropdown in sidebar with user email"
echo -e "  • Persists across reloads via localStorage"
echo ""
echo -e "  Run  ${CYAN}npm run dev${RESET}  — you'll land on the auth screen first."
