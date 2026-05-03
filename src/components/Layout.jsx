import { useState, useEffect } from 'react'
import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'
import MobileNav from './MobileNav'
import YouTubePlayer from './YouTubePlayer'
import DiscoverPage from '../pages/DiscoverPage'
import LibraryPage from '../pages/LibraryPage'
import LikedPage from '../pages/LikedPage'
import PlaylistsPage from '../pages/PlaylistsPage'

function PageRouter({ page, screenSize }) {
  switch (page) {
    case 'Discover':  return <DiscoverPage />
    case 'Library':   return <LibraryPage />
    case 'Liked':     return <LikedPage />
    case 'Playlists': return <PlaylistsPage />
    default:          return <MainContent screenSize={screenSize} />
  }
}

export default function Layout() {
  const [screen,         setScreen]         = useState('desktop')
  const [nowPlayingOpen, setNowPlayingOpen] = useState(false)
  const [activePage,     setActivePage]     = useState('Home')

  useEffect(() => {
    const upd = () => {
      const w = window.innerWidth
      setScreen(w < 640 ? 'mobile' : w < 1024 ? 'tablet' : 'desktop')
    }
    upd()
    window.addEventListener('resize', upd)
    return () => window.removeEventListener('resize', upd)
  }, [])

  const isMobile  = screen === 'mobile'
  const isTablet  = screen === 'tablet'
  const isDesktop = screen === 'desktop'

  return (
    <div style={{ height: '100dvh', width: '100vw', overflow: 'hidden', background: 'var(--bg-base)', position: 'relative', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font-body)' }}>
      <YouTubePlayer />

      {/* Ambient orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '-15%', left: '-8%', width: isMobile?280:520, height: isMobile?280:520, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-1) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift1 20s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', top: '40%', right: '-12%', width: isMobile?220:420, height: isMobile?220:420, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-2) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift2 25s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', bottom: '-8%', left: '38%', width: isMobile?180:360, height: isMobile?180:360, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-3) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift3 28s ease-in-out infinite alternate' }} />
      </div>

      {/* Desktop */}
      {isDesktop && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden' }}><Sidebar activePage={activePage} onNavigate={setActivePage} /></div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden' }}><PageRouter page={activePage} screenSize={screen} /></div>
          <div style={{ gridColumn: 3, gridRow: 1, overflow: 'hidden' }}><NowPlaying /></div>
          <div style={{ gridColumn: '1/-1', gridRow: 2 }}><Player /></div>
        </div>
      )}

      {/* Tablet */}
      {isTablet && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '68px 1fr', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: 1, gridRow: 1 }}><Sidebar collapsed activePage={activePage} onNavigate={setActivePage} /></div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden' }}><PageRouter page={activePage} screenSize={screen} /></div>
          <div style={{ gridColumn: '1/-1', gridRow: 2 }}><Player onNowPlayingClick={() => setNowPlayingOpen(true)} /></div>
          {nowPlayingOpen && <>
            <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
            <div style={{ position: 'fixed', top: 0, right: 0, width: 300, height: '100dvh', zIndex: 50, animation: 'slideInRight 0.3s ease' }}><NowPlaying onClose={() => setNowPlayingOpen(false)} /></div>
          </>}
        </div>
      )}

      {/* Mobile */}
      {isMobile && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ flex: 1, overflow: 'hidden' }}><PageRouter page={activePage} screenSize={screen} /></div>
          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />
          <MobileNav activePage={activePage} onNavigate={setActivePage} />
          {nowPlayingOpen && <>
            <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
            <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, height: '90dvh', borderRadius: '22px 22px 0 0', zIndex: 50, animation: 'slideInUp 0.3s ease', overflow: 'hidden' }}><NowPlaying onClose={() => setNowPlayingOpen(false)} /></div>
          </>}
        </div>
      )}
    </div>
  )
}
