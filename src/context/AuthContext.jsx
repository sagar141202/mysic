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
