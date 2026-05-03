/**
 * Free YouTube search via Vite dev proxy — no API key needed.
 * In dev: requests go through /ytproxy → youtube.com (no CORS issues).
 */

const COLORS = ['#22d3ee','#0ea5e9','#818cf8','#f59e0b','#34d399','#f472b6','#fb923c']

function parseDuration(text) {
  if (!text) return 180
  const parts = text.split(':').map(Number)
  if (parts.length === 2) return parts[0] * 60 + parts[1]
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2]
  return 180
}

function parseVideoItems(html) {
  const results = []
  try {
    const match = html.match(/var ytInitialData\s*=\s*({.+?});\s*<\/script>/)
    if (!match) {
      console.warn('[ytSearch] ytInitialData not found in HTML')
      return results
    }
    const data     = JSON.parse(match[1])
    const contents =
      data?.contents?.twoColumnSearchResultsRenderer
        ?.primaryContents?.sectionListRenderer
        ?.contents?.[0]?.itemSectionRenderer?.contents || []

    for (const item of contents) {
      const v = item.videoRenderer
      if (!v?.videoId) continue
      const title   = v.title?.runs?.[0]?.text || 'Unknown'
      const artist  = v.ownerText?.runs?.[0]?.text || 'Unknown Artist'
      const durText = v.lengthText?.simpleText || '3:00'
      const thumb   = v.thumbnail?.thumbnails?.slice(-1)[0]?.url || null
      results.push({
        id:        `yt-${v.videoId}`,
        title,
        artist,
        album:     'YouTube',
        duration:  parseDuration(durText),
        color:     COLORS[results.length % COLORS.length],
        youtubeId: v.videoId,
        thumbnail: thumb,
        genre:     'search',
      })
      if (results.length >= 20) break
    }
  } catch (err) {
    console.error('[ytSearch] parse error:', err)
  }
  return results
}

export async function searchYouTube(query, limit = 20) {
  try {
    // /ytproxy is rewritten to https://www.youtube.com by Vite proxy
    const res  = await fetch(
      `/ytproxy/results?search_query=${encodeURIComponent(query)}&sp=EgIQAQ%3D%3D`
    )
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const html  = await res.text()
    const items = parseVideoItems(html)
    if (items.length === 0) throw new Error('No items parsed')
    return items.slice(0, limit)
  } catch (err) {
    console.error('[ytSearch] proxy failed, trying allorigins:', err)
    return searchViaAllOrigins(query, limit)
  }
}

async function searchViaAllOrigins(query, limit = 20) {
  try {
    const ytUrl    = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}&sp=EgIQAQ%3D%3D`
    const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(ytUrl)}`
    const res      = await fetch(proxyUrl)
    if (!res.ok) throw new Error(`allorigins HTTP ${res.status}`)
    const json  = await res.json()
    const items = parseVideoItems(json.contents || '')
    return items.slice(0, limit)
  } catch (err) {
    console.error('[ytSearch allorigins] failed:', err)
    return []
  }
}

export async function getRelatedSongs(videoId, limit = 10) {
  try {
    const ytUrl    = `https://www.youtube.com/watch?v=${videoId}`
    const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(ytUrl)}`
    const res      = await fetch(proxyUrl)
    const json     = await res.json()
    const html     = json.contents || ''

    const match = html.match(/var ytInitialData\s*=\s*({.+?});\s*<\/script>/)
    if (!match) return []

    const data    = JSON.parse(match[1])
    const related = []
    const items   =
      data?.contents?.twoColumnWatchNextResults
        ?.secondaryResults?.secondaryResults?.results || []

    for (const item of items) {
      const v = item.compactVideoRenderer
      if (!v?.videoId) continue
      related.push({
        id:        `yt-${v.videoId}`,
        title:     v.title?.simpleText || 'Unknown',
        artist:    v.shortBylineText?.runs?.[0]?.text || 'Unknown Artist',
        album:     'YouTube',
        duration:  parseDuration(v.lengthText?.simpleText),
        color:     COLORS[related.length % COLORS.length],
        youtubeId: v.videoId,
        thumbnail: v.thumbnail?.thumbnails?.slice(-1)[0]?.url || null,
        genre:     'related',
      })
      if (related.length >= limit) break
    }
    return related
  } catch (err) {
    console.error('[ytRelated] error:', err)
    return []
  }
}
