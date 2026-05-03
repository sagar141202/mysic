/**
 * fetchLyrics.js
 *
 * Fetches lyrics from lrclib.net — free, no auth, has
 * timestamped (LRC) lyrics for most songs.
 *
 * Strategy:
 *  1. Try lrclib /api/get  with title + artist + duration
 *  2. Fallback: /api/search with title + artist (looser match)
 *  3. Parse LRC timestamp lines → [{time:seconds, text:string}]
 *  4. Resolve with plain-text lines if no timestamps exist
 */

const BASE = 'https://lrclib.net/api'

/** Parse "[mm:ss.xx] lyric line" → [{time, text}] */
function parseLrc(lrc) {
  if (!lrc) return []
  const lines = []
  for (const raw of lrc.split('\n')) {
    const m = raw.match(/^\[(\d{1,2}):(\d{2})\.(\d{1,3})\](.*)/)
    if (!m) continue
    const time = parseInt(m[1]) * 60 + parseFloat(`${m[2]}.${m[3]}`)
    const text = m[4].trim()
    if (text) lines.push({ time, text })
  }
  return lines
}

/** Parse plain lyrics → [{time: null, text}] */
function parsePlain(plain) {
  if (!plain) return []
  return plain.split('\n')
    .map(t => t.trim())
    .filter(Boolean)
    .map(text => ({ time: null, text }))
}

/** Clean title — strip "(Official Video)", "[Lyrics]" etc */
function cleanTitle(title = '') {
  return title
    .replace(/\(.*?\)/g, '')
    .replace(/\[.*?\]/g, '')
    .replace(/ft\.?.*/i, '')
    .replace(/feat\.?.*/i, '')
    .trim()
}

/** Clean artist — use only first listed artist */
function cleanArtist(artist = '') {
  return artist.split(/[,&x×]/)[0].trim()
}

export async function fetchLyrics(song) {
  const title    = cleanTitle(song?.title   || '')
  const artist   = cleanArtist(song?.artist || '')
  const duration = song?.duration ? Math.round(song.duration) : undefined

  if (!title) return { lines: [], plain: [], synced: false, notFound: true }

  /* ── Attempt 1: exact match via /api/get ── */
  try {
    const params = new URLSearchParams({ track_name: title, artist_name: artist })
    if (duration) params.set('duration', duration)
    const res  = await fetch(`${BASE}/get?${params}`, {
      headers: { 'Lrclib-Client': 'Mysic/1.0 (github.com/sagar141202/mysic)' }
    })
    if (res.ok) {
      const data = await res.json()
      if (data?.syncedLyrics) {
        const lines = parseLrc(data.syncedLyrics)
        if (lines.length) return { lines, plain: lines.map(l => l.text), synced: true, notFound: false }
      }
      if (data?.plainLyrics) {
        const lines = parsePlain(data.plainLyrics)
        return { lines, plain: lines.map(l => l.text), synced: false, notFound: false }
      }
    }
  } catch { /* network error — fall through */ }

  /* ── Attempt 2: search fallback ── */
  try {
    const params = new URLSearchParams({ track_name: title, artist_name: artist })
    const res    = await fetch(`${BASE}/search?${params}`, {
      headers: { 'Lrclib-Client': 'Mysic/1.0 (github.com/sagar141202/mysic)' }
    })
    if (res.ok) {
      const results = await res.json()
      const hit = results?.find(r => r.syncedLyrics || r.plainLyrics)
      if (hit?.syncedLyrics) {
        const lines = parseLrc(hit.syncedLyrics)
        if (lines.length) return { lines, plain: lines.map(l => l.text), synced: true, notFound: false }
      }
      if (hit?.plainLyrics) {
        const lines = parsePlain(hit.plainLyrics)
        return { lines, plain: lines.map(l => l.text), synced: false, notFound: false }
      }
    }
  } catch { /* network error */ }

  return { lines: [], plain: [], synced: false, notFound: true }
}
