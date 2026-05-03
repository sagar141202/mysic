#!/usr/bin/env bash
set -e

REPO_ROOT="$(pwd)"

if [ ! -f "$REPO_ROOT/vite.config.js" ]; then
  echo "❌  Run from the mysic repo root."
  exit 1
fi

echo "─── Fixing src/utils/ytSearch.js ───"

cat > "$REPO_ROOT/src/utils/ytSearch.js" << 'YTSEARCH_EOF'
// ─────────────────────────────────────────────────────────────────────────────
// ytSearch.js — free YouTube search, no API key required
// ─────────────────────────────────────────────────────────────────────────────

const COLORS = [
  '#06b6d4','#8b5cf6','#ec4899','#f59e0b',
  '#10b981','#3b82f6','#f97316','#14b8a6',
]

export function getYtThumbnail(videoId, quality = 'hq') {
  if (!videoId) return null
  const suffix =
    quality === 'maxres' ? 'maxresdefault' :
    quality === 'sd'     ? 'sddefault'     :
    quality === 'mq'     ? 'mqdefault'     :
    quality === 'default'? 'default'        :
    'hqdefault'
  return `https://i.ytimg.com/vi/${videoId}/${suffix}.jpg`
}

/**
 * Robustly extract ytInitialData JSON from raw YouTube HTML.
 * YouTube embeds it as: var ytInitialData = {...};
 * The blob is huge — we find the var assignment and brace-match to get the full object.
 */
function extractYtInitialData(html) {
  const marker = 'var ytInitialData = '
  const start  = html.indexOf(marker)
  if (start === -1) return null

  let i     = start + marker.length
  let depth = 0
  let inStr = false
  let strCh = ''
  let escape = false

  for (; i < html.length; i++) {
    const ch = html[i]

    if (escape) { escape = false; continue }
    if (ch === '\\' && inStr) { escape = true; continue }

    if (inStr) {
      if (ch === strCh) inStr = false
      continue
    }

    if (ch === '"' || ch === "'" || ch === '`') { inStr = true; strCh = ch; continue }
    if (ch === '{' || ch === '[') { depth++; continue }
    if (ch === '}' || ch === ']') {
      depth--
      if (depth === 0) {
        const jsonStr = html.slice(start + marker.length, i + 1)
        try { return JSON.parse(jsonStr) } catch { return null }
      }
    }
  }
  return null
}

function parseResults(html, maxCount) {
  const data = extractYtInitialData(html)
  if (!data) {
    console.warn('[ytSearch] Could not extract ytInitialData')
    return []
  }

  // Walk all itemSectionRenderer contents to find videoRenderers
  const items = []

  function walk(node) {
    if (items.length >= maxCount) return
    if (!node || typeof node !== 'object') return

    if (node.videoRenderer?.videoId) {
      const vr     = node.videoRenderer
      const title  = vr.title?.runs?.[0]?.text ?? 'Unknown'
      const artist = vr.ownerText?.runs?.[0]?.text
                  ?? vr.shortBylineText?.runs?.[0]?.text
                  ?? 'Unknown'

      // Best thumbnail: largest width from the thumbnails array
      let thumbnail = null
      const thumbs  = vr.thumbnail?.thumbnails ?? []
      if (thumbs.length) {
        const best = thumbs.reduce((a, b) => ((b.width || 0) > (a.width || 0) ? b : a))
        thumbnail  = best.url || null
      }
      if (!thumbnail) thumbnail = getYtThumbnail(vr.videoId, 'hq')

      // Duration
      let duration = 210
      try {
        const parts = vr.lengthText?.simpleText?.split(':').map(Number) ?? []
        if (parts.length === 2) duration = parts[0] * 60 + parts[1]
        if (parts.length === 3) duration = parts[0] * 3600 + parts[1] * 60 + parts[2]
      } catch { /* keep default */ }

      items.push({
        id:        vr.videoId,
        youtubeId: vr.videoId,
        title,
        artist,
        duration,
        thumbnail,
        color: COLORS[items.length % COLORS.length],
      })
      return // don't recurse into this renderer's children
    }

    // Recurse into arrays and plain objects
    if (Array.isArray(node)) {
      for (const child of node) { if (items.length < maxCount) walk(child) }
    } else {
      for (const key of Object.keys(node)) { if (items.length < maxCount) walk(node[key]) }
    }
  }

  // Start from sectionListRenderer contents for efficiency
  try {
    const sections =
      data.contents?.twoColumnSearchResultsRenderer?.primaryContents
          ?.sectionListRenderer?.contents ?? []
    for (const section of sections) {
      walk(section)
      if (items.length >= maxCount) break
    }
  } catch {
    walk(data) // full walk fallback
  }

  return items
}

async function fetchViaProxy(query) {
  const url = `/ytproxy/results?search_query=${encodeURIComponent(query)}&hl=en`
  const res  = await fetch(url, { headers: { 'Accept-Language': 'en-US,en;q=0.9' } })
  if (!res.ok) throw new Error(`proxy ${res.status}`)
  return res.text()
}

async function fetchViaAllOrigins(query) {
  const yt  = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}&hl=en`
  const url = `https://api.allorigins.win/get?url=${encodeURIComponent(yt)}`
  const res  = await fetch(url)
  if (!res.ok) throw new Error(`allorigins ${res.status}`)
  const json = await res.json()
  return json.contents
}

/**
 * Primary export. DiscoverPage etc. import as:
 *   import { ytSearch as searchYouTube } from '../utils/ytSearch'
 */
export async function ytSearch(query) {
  const MAX = 20
  let html = ''
  try {
    html = await fetchViaProxy(query)
  } catch (e) {
    console.warn('[ytSearch] proxy failed, trying allorigins:', e.message)
    try {
      html = await fetchViaAllOrigins(query)
    } catch (e2) {
      console.error('[ytSearch] both methods failed:', e2.message)
      return []
    }
  }
  const results = parseResults(html, MAX)
  console.log(`[ytSearch] "${query}" → ${results.length} results`)
  return results
}

/**
 * Alias for MainContent (accepts optional count arg, ignored).
 */
export async function searchYouTube(query, _count) {
  return ytSearch(query)
}
YTSEARCH_EOF

echo "✅  ytSearch.js fixed"
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Done! Now run:  npm run dev           ║"
echo "║                                        ║"
echo "║  Open browser console — you should     ║"
echo "║  see: [ytSearch] 'query' → N results   ║"
echo "╚════════════════════════════════════════╝"
