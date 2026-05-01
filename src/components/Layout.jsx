import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'

export default function Layout() {
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)',
      gridTemplateRows: '1fr var(--player-height)',
      height: '100vh',
      width: '100vw',
      position: 'relative',
      overflow: 'hidden',
      background: 'var(--bg-base)',
    }}>

      {/* Ambient background orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{
          position: 'absolute', top: '-20%', left: '-10%',
          width: '600px', height: '600px', borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(168,85,247,0.12) 0%, transparent 70%)',
          filter: 'blur(60px)',
          animation: 'drift1 18s ease-in-out infinite alternate',
        }} />
        <div style={{
          position: 'absolute', top: '30%', right: '-15%',
          width: '500px', height: '500px', borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(236,72,153,0.10) 0%, transparent 70%)',
          filter: 'blur(60px)',
          animation: 'drift2 22s ease-in-out infinite alternate',
        }} />
        <div style={{
          position: 'absolute', bottom: '-10%', left: '35%',
          width: '400px', height: '400px', borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)',
          filter: 'blur(60px)',
          animation: 'drift3 26s ease-in-out infinite alternate',
        }} />
      </div>

      <style>{`
        @keyframes drift1 { from { transform: translate(0, 0) scale(1); } to { transform: translate(80px, 60px) scale(1.15); } }
        @keyframes drift2 { from { transform: translate(0, 0) scale(1); } to { transform: translate(-60px, 80px) scale(1.1); } }
        @keyframes drift3 { from { transform: translate(0, 0) scale(1); } to { transform: translate(40px, -60px) scale(1.2); } }
      `}</style>

      {/* Sidebar */}
      <div style={{ gridColumn: '1', gridRow: '1', zIndex: 10, position: 'relative' }}>
        <Sidebar />
      </div>

      {/* Main Content */}
      <div style={{ gridColumn: '2', gridRow: '1', zIndex: 10, position: 'relative', overflow: 'hidden' }}>
        <MainContent />
      </div>

      {/* Now Playing Panel */}
      <div style={{ gridColumn: '3', gridRow: '1', zIndex: 10, position: 'relative' }}>
        <NowPlaying />
      </div>

      {/* Bottom Player */}
      <div style={{ gridColumn: '1 / -1', gridRow: '2', zIndex: 20, position: 'relative' }}>
        <Player />
      </div>
    </div>
  )
}
