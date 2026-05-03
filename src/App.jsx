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
