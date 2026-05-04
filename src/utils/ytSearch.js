/**
 * ytSearch.js — YouTube search via proxy
 *
 * Dev:  Vite rewrites  /ytproxy/* → https://www.youtube.com/*
 * Prod: Vercel routes  /ytproxy/* → /api/ytproxy
 *       Netlify routes /ytproxy/* → /.netlify/functions/ytproxy
 *
 * The client always calls /ytproxy/results?search_query=...
 * No env vars needed.
 */

const PROXY = '/ytproxy'

/* ── Thumbnail helpers ──────────────────────────────────── */

export function getYtThumbnail(id, quality = 'hq') {
  if (!id) return null
  const q = quality === 'hq' ? 'hqdefault' : quality === 'mq' ? 'mqdefault' : 'sddefault'
  return `https://i.ytimg.com/vi/${id}/${q}.jpg`
}

/* ── Colour extraction ──────────────────────────────────── */

const COLOR_CACHE = new Map()

export async function extractColors(src, _count = 3) {
  if (COLOR_CACHE.has(src)) return { hex: COLOR_CACHE.get(src) }

  try {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    await new Promise((res, rej) => {
      img.onload = res
      img.onerror = rej
      img.src = src
    })

    const canvas = document.createElement('canvas')
    canvas.width = 32
    canvas.height = 32
    const ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0, 32, 32)
    const data = ctx.getImageData(0, 0, 32, 32).data

    let r = 0, g = 0, b = 0, count = 0
    for (let i = 0; i < data.length; i += 16) {
      const lum = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]
      if (lum > 20 && lum < 235) {
        r += data[i]; g += data[i + 1]; b += data[i + 2]; count++
      }
    }

    if (!count) throw new Error('no usable pixels')

    const hex =
      '#' +
      [Math.round(r / count), Math.round(g / count), Math.round(b / count)]
        .map(v => v.toString(16).padStart(2, '0'))
        .join('')

    COLOR_CACHE.set(src, hex)
    return { hex }
  } catch {
    return { hex: '#8b5cf6' }
  }
}

/* ── ytInitialData parser ────────────────────────────────── */

function extractYtInitialData(html) {
  const marker = 'var ytInitialData = '
  const start = html.indexOf(marker)
  if (start === -1) return null

  let depth = 0, inStr = false, escape = false
  let i = start + marker.length

  for (; i < html.length; i++) {
    const ch = html[i]
    if (escape)          { escape = false; continue }
    if (ch === '\\')     { escape = true;  continue }
    if (ch === '"')      { inStr = !inStr; continue }
    if (inStr)           continue
    if (ch === '{')      depth++
    else if (ch === '}') { depth--; if (depth === 0) { i++; break } }
  }

  try {
    return JSON.parse(html.slice(start + marker.length, i))
  } catch {
    return null
  }
}

function collectVideoRenderers(obj, results = [], depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 25) return results

  if (obj.videoRenderer?.videoId) {
    results.push(obj.videoRenderer)
    return results
  }

  for (const value of Object.values(obj)) {
    if (Array.isArray(value)) {
      for (const item of value) collectVideoRenderers(item, results, depth + 1)
    } else if (value && typeof value === 'object') {
      collectVideoRenderers(value, results, depth + 1)
    }
  }

  return results
}

async function rendererToSong(r) {
  const id = r.videoId
  if (!id) return null

  const title =
    r.title?.runs?.[0]?.text ||
    r.title?.simpleText ||
    'Unknown'

  const artist =
    r.longBylineText?.runs?.[0]?.text ||
    r.ownerText?.runs?.[0]?.text ||
    r.shortBylineText?.runs?.[0]?.text ||
    'Unknown Artist'

  const durationStr =
    r.lengthText?.simpleText ||
    r.lengthText?.runs?.[0]?.text ||
    '0:00'

  const parts = durationStr.split(':').map(Number)
  const duration =
    parts.length === 3
      ? parts[0] * 3600 + parts[1] * 60 + parts[2]
      : parts.length === 2
      ? parts[0] * 60 + parts[1]
      : 0

  const thumbnail = getYtThumbnail(id, 'hq')

  let color = '#8b5cf6'
  try {
    const { hex } = await extractColors(thumbnail)
    color = hex
  } catch { /* keep default */ }

  return { id, youtubeId: id, title, artist, duration, thumbnail, color }
}

/* ── Public API ─────────────────────────────────────────── */

const SEARCH_CACHE = new Map()

export async function searchYouTube(query, limit = 10) {
  const cacheKey = `${query}__${limit}`
  if (SEARCH_CACHE.has(cacheKey)) return SEARCH_CACHE.get(cacheKey)

  try {
    const url = `${PROXY}/results?search_query=${encodeURIComponent(query)}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Proxy responded ${res.status}`)

    const html = await res.text()
    const data = extractYtInitialData(html)
    if (!data) throw new Error('ytInitialData not found in response')

    const renderers = collectVideoRenderers(data)

    const songs = (
      await Promise.all(
        renderers.slice(0, limit * 2).map(r => rendererToSong(r))
      )
    )
      .filter(Boolean)
      .filter(s => s.duration > 0)   // strip Shorts / live streams
      .slice(0, limit)

    SEARCH_CACHE.set(cacheKey, songs)
    return songs
  } catch (err) {
    console.error('[ytSearch] error:', err)
    return []
  }
}
