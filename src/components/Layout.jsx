import { useState, useEffect } from 'react'
import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'
import MobileNav from './MobileNav'

export default function Layout() {
  const [screenSize, setScreenSize] = useState('desktop')
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [nowPlayingOpen, setNowPlayingOpen] = useState(false)

  useEffect(() => {
    const update = () => {
      const w = window.innerWidth
      if (w < 640) setScreenSize('mobile')
      else if (w < 1024) setScreenSize('tablet')
      else setScreenSize('desktop')
    }
    update()
    window.addEventListener('resize', update)
    return () => window.removeEventListener('resize', update)
  }, [])

  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'
  const isDesktop = screenSize === 'desktop'

  return (
    <div style={{
      height: '100dvh',
      width: '100vw',
      overflow: 'hidden',
      background: 'var(--bg-base)',
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
    }}>

      {/* Ambient orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '-20%', left: '-10%', width: isMobile ? '300px' : '600px', height: isMobile ? '300px' : '600px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(168,85,247,0.12) 0%, transparent 70%)', filter: 'blur(60px)', animation: 'drift1 18s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', top: '30%', right: '-15%', width: isMobile ? '250px' : '500px', height: isMobile ? '250px' : '500px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(236,72,153,0.10) 0%, transparent 70%)', filter: 'blur(60px)', animation: 'drift2 22s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', bottom: '-10%', left: '35%', width: isMobile ? '200px' : '400px', height: isMobile ? '200px' : '400px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)', filter: 'blur(60px)', animation: 'drift3 26s ease-in-out infinite alternate' }} />
      </div>

      <style>{`
        @keyframes drift1 { from { transform: translate(0,0) scale(1); } to { transform: translate(80px,60px) scale(1.15); } }
        @keyframes drift2 { from { transform: translate(0,0) scale(1); } to { transform: translate(-60px,80px) scale(1.1); } }
        @keyframes drift3 { from { transform: translate(0,0) scale(1); } to { transform: translate(40px,-60px) scale(1.2); } }
        @keyframes slideInLeft { from { transform: translateX(-100%); } to { transform: translateX(0); } }
        @keyframes slideInRight { from { transform: translateX(100%); } to { transform: translateX(0); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
      `}</style>

      {/* ── DESKTOP layout ── */}
      {isDesktop && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: '1', gridRow: '1', overflow: 'hidden' }}><Sidebar /></div>
          <div style={{ gridColumn: '2', gridRow: '1', overflow: 'hidden' }}><MainContent screenSize={screenSize} /></div>
          <div style={{ gridColumn: '3', gridRow: '1', overflow: 'hidden' }}><NowPlaying /></div>
          <div style={{ gridColumn: '1 / -1', gridRow: '2' }}><Player onNowPlayingClick={() => {}} /></div>
        </div>
      )}

      {/* ── TABLET layout ── */}
      {isTablet && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '72px 1fr', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: '1', gridRow: '1', overflow: 'hidden' }}><Sidebar collapsed /></div>
          <div style={{ gridColumn: '2', gridRow: '1', overflow: 'hidden' }}><MainContent screenSize={screenSize} /></div>
          <div style={{ gridColumn: '1 / -1', gridRow: '2' }}><Player onNowPlayingClick={() => setNowPlayingOpen(true)} /></div>
          {/* Slide-over Now Playing */}
          {nowPlayingOpen && (
            <>
              <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
              <div style={{ position: 'fixed', top: 0, right: 0, width: '320px', height: '100dvh', zIndex: 50, animation: 'slideInRight 0.3s ease' }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}

      {/* ── MOBILE layout ── */}
      {isMobile && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ flex: 1, overflow: 'hidden' }}><MainContent screenSize={screenSize} /></div>
          {/* Mini player bar */}
          <div style={{ flexShrink: 0 }}><Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} /></div>
          {/* Bottom nav */}
          <div style={{ flexShrink: 0 }}><MobileNav /></div>

          {/* Sidebar drawer */}
          {sidebarOpen && (
            <>
              <div onClick={() => setSidebarOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
              <div style={{ position: 'fixed', top: 0, left: 0, width: '260px', height: '100dvh', zIndex: 50, animation: 'slideInLeft 0.3s ease' }}>
                <Sidebar onClose={() => setSidebarOpen(false)} />
              </div>
            </>
          )}

          {/* Full-screen Now Playing sheet */}
          {nowPlayingOpen && (
            <>
              <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
              <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, height: '92dvh', borderRadius: '24px 24px 0 0', zIndex: 50, animation: 'slideInRight 0.3s ease', overflow: 'hidden' }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}
