import { useState, useEffect } from 'react'
import { AnimatePresence } from 'framer-motion'
import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'
import MobileNav from './MobileNav'
import YouTubePlayer from './YouTubePlayer'
import PageTransition from './PageTransition'
import DiscoverPage from '../pages/DiscoverPage'
import LibraryPage from '../pages/LibraryPage'
import LikedPage from '../pages/LikedPage'
import PlaylistsPage from '../pages/PlaylistsPage'

function PageRouter({ page, screenSize }) {
  const props = { screenSize }
  switch (page) {
    case 'Discover':  return <DiscoverPage  {...props} />
    case 'Library':   return <LibraryPage   {...props} />
    case 'Liked':     return <LikedPage     {...props} />
    case 'Playlists': return <PlaylistsPage {...props} />
    default:          return <MainContent   {...props} />
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

  /* shared slide-panel styles */
  const backdrop = {
    position: 'fixed', inset: 0, zIndex: 40,
    background: 'rgba(0,0,0,0.55)',
    animation: 'fadeIn 0.2s ease',
  }

  return (
    <div style={{
      height: '100dvh', width: '100vw',
      overflow: 'hidden',
      background: 'var(--bg-base)',
      position: 'relative',
      display: 'flex', flexDirection: 'column',
      fontFamily: 'var(--font-body)',
      /* prevent rubber-band scroll on iOS from exposing background */
      overscrollBehavior: 'none',
    }}>
      <YouTubePlayer />

      {/* Ambient orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '-15%', left: '-8%', width: isMobile ? 240 : 520, height: isMobile ? 240 : 520, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-1) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift1 20s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', top: '40%', right: '-12%', width: isMobile ? 190 : 420, height: isMobile ? 190 : 420, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-2) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift2 25s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', bottom: '-8%', left: '38%', width: isMobile ? 160 : 360, height: isMobile ? 160 : 360, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-3) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift3 28s ease-in-out infinite alternate' }} />
      </div>

      {/* ── Desktop ── */}
      {isDesktop && (
        <div style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)',
          gridTemplateRows: '1fr var(--player-height)',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          minWidth: 0,  /* prevent grid blowout */
        }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden', minWidth: 0 }}>
            <Sidebar activePage={activePage} onNavigate={setActivePage} />
          </div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative', minWidth: 0 }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: 3, gridRow: 1, overflow: 'hidden', minWidth: 0 }}>
            <NowPlaying />
          </div>
          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>
            <Player />
          </div>
        </div>
      )}

      {/* ── Tablet ── */}
      {isTablet && (
        <div style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: '64px 1fr',
          gridTemplateRows: '1fr var(--player-height)',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          minWidth: 0,
        }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden' }}>
            <Sidebar collapsed activePage={activePage} onNavigate={setActivePage} />
          </div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative', minWidth: 0 }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>
            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />
          </div>

          {nowPlayingOpen && (
            <>
              <div style={backdrop} onClick={() => setNowPlayingOpen(false)} />
              <div style={{ position: 'fixed', top: 0, right: 0, width: 'min(320px, 90vw)', height: '100dvh', zIndex: 50, animation: 'slideInRight 0.28s ease' }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}

      {/* ── Mobile ── */}
      {isMobile && (
        <div style={{
          flex: 1,
          display: 'flex', flexDirection: 'column',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          /* pushes content above home indicator on iOS */
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        }}>
          <div style={{ flex: 1, overflow: 'hidden', position: 'relative', touchAction: 'pan-y' }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />
          <MobileNav activePage={activePage} onNavigate={setActivePage} />

          {nowPlayingOpen && (
            <>
              <div style={{ ...backdrop, background: 'rgba(0,0,0,0.65)' }} onClick={() => setNowPlayingOpen(false)} />
              <div style={{
                position: 'fixed', bottom: 0, left: 0, right: 0,
                height: '92dvh',
                borderRadius: '24px 24px 0 0',
                zIndex: 50,
                animation: 'slideInUp 0.28s ease',
                overflow: 'hidden',
              }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}
