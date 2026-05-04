#!/usr/bin/env bash
# =============================================================================
#  fix-yt-proxy.sh — Mysic · YouTube Proxy Production Fix
#  Run from the ROOT of your mysic repo:  bash fix-yt-proxy.sh
# =============================================================================
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[mysic]${RESET} $1"; }
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $1"; }
die()  { echo -e "${RED}  ✗ $1${RESET}"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║      Mysic — YouTube Proxy Production Fix            ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Sanity check ──────────────────────────────────────────────────────────────
[ -f "package.json" ] || die "Run this script from the repo root (package.json not found)"
log "Repo root confirmed"

# ── 1. vercel.json ────────────────────────────────────────────────────────────
log "Writing vercel.json …"
cat > vercel.json << 'EOF'
{
  "rewrites": [
    {
      "source": "/ytproxy/:path*",
      "destination": "/api/ytproxy"
    }
  ]
}
EOF
ok "vercel.json created"

# ── 2. api/ytproxy.js (Vercel serverless function) ───────────────────────────
log "Writing api/ytproxy.js …"
mkdir -p api
cat > api/ytproxy.js << 'EOF'
/**
 * api/ytproxy.js  —  Vercel Serverless Function
 *
 * Proxies YouTube search requests so the browser never hits youtube.com
 * directly (which blocks CORS). Works in both preview and production deploys.
 *
 * Usage (from the client):
 *   fetch('/ytproxy/results?search_query=lofi+beats')
 *
 * Place this file at:  /api/ytproxy.js  in the repo root.
 */

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const { search_query } = req.query

  if (!search_query) {
    return res.status(400).json({ error: 'Missing search_query parameter' })
  }

  const ytUrl = `https://www.youtube.com/results?search_query=${encodeURIComponent(
    search_query
  )}&hl=en&gl=US`

  try {
    const ytRes = await fetch(ytUrl, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'no-cache',
        Pragma: 'no-cache',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Upgrade-Insecure-Requests': '1',
      },
    })

    if (!ytRes.ok) {
      return res.status(ytRes.status).json({ error: `YouTube returned ${ytRes.status}` })
    }

    const html = await ytRes.text()

    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Content-Type', 'text/html; charset=utf-8')
    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=60')

    return res.status(200).send(html)
  } catch (err) {
    console.error('[ytproxy] fetch error:', err)
    return res.status(500).json({ error: 'Proxy fetch failed', detail: err.message })
  }
}
EOF
ok "api/ytproxy.js created"

# ── 3. netlify.toml ───────────────────────────────────────────────────────────
log "Writing netlify.toml …"
cat > netlify.toml << 'EOF'
[build]
  publish = "dist"
  command = "npm run build"

[[redirects]]
  from   = "/ytproxy/*"
  to     = "/.netlify/functions/ytproxy"
  status = 200

[[redirects]]
  from   = "/*"
  to     = "/index.html"
  status = 200
EOF
ok "netlify.toml created"

# ── 4. netlify/functions/ytproxy.js ──────────────────────────────────────────
log "Writing netlify/functions/ytproxy.js …"
mkdir -p netlify/functions
cat > netlify/functions/ytproxy.js << 'EOF'
/**
 * netlify/functions/ytproxy.js  —  Netlify Function
 *
 * Equivalent of api/ytproxy.js but for Netlify's function runtime.
 * Receives requests forwarded from the /ytproxy/* redirect in netlify.toml.
 */

exports.handler = async function (event) {
  if (event.httpMethod !== 'GET') {
    return { statusCode: 405, body: JSON.stringify({ error: 'Method not allowed' }) }
  }

  const search_query = event.queryStringParameters?.search_query

  if (!search_query) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Missing search_query' }) }
  }

  const ytUrl = `https://www.youtube.com/results?search_query=${encodeURIComponent(
    search_query
  )}&hl=en&gl=US`

  try {
    const ytRes = await fetch(ytUrl, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
        Pragma: 'no-cache',
      },
    })

    if (!ytRes.ok) {
      return {
        statusCode: ytRes.status,
        body: JSON.stringify({ error: `YouTube returned ${ytRes.status}` }),
      }
    }

    const html = await ytRes.text()

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 's-maxage=300, stale-while-revalidate=60',
      },
      body: html,
    }
  } catch (err) {
    console.error('[ytproxy] fetch error:', err)
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Proxy fetch failed', detail: err.message }),
    }
  }
}
EOF
ok "netlify/functions/ytproxy.js created"

# ── 5. vite.config.js ─────────────────────────────────────────────────────────
log "Backing up and replacing vite.config.js …"
[ -f "vite.config.js" ] && cp vite.config.js vite.config.js.bak && ok "Backup saved → vite.config.js.bak"
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

/**
 * vite.config.js
 *
 * Dev server:  /ytproxy/*  →  https://www.youtube.com/*  (Vite rewrite, dev only)
 * Production:  vercel.json  routes /ytproxy/* → /api/ytproxy
 *              netlify.toml routes /ytproxy/* → netlify function
 *
 * The client always calls /ytproxy/results?search_query=...
 * No env vars needed — the host environment handles routing.
 */
export default defineConfig({
  plugins: [react()],

  server: {
    proxy: {
      '/ytproxy': {
        target: 'https://www.youtube.com',
        changeOrigin: true,
        rewrite: path => path.replace(/^\/ytproxy/, ''),
        configure: (proxy) => {
          proxy.on('proxyRes', (proxyRes) => {
            delete proxyRes.headers['x-frame-options']
            proxyRes.headers['access-control-allow-origin'] = '*'
          })
        },
      },
    },
  },

  build: {
    chunkSizeWarningLimit: 800,
  },
})
EOF
ok "vite.config.js updated"

# ── 6. src/utils/ytSearch.js ──────────────────────────────────────────────────
log "Locating ytSearch.js …"
YT_SEARCH_PATH=""
for candidate in \
    "src/utils/ytSearch.js" \
    "src/utils/ytSearch.ts" \
    "utils/ytSearch.js" \
    "utils/ytSearch.ts"
do
  if [ -f "$candidate" ]; then
    YT_SEARCH_PATH="$candidate"
    break
  fi
done

if [ -z "$YT_SEARCH_PATH" ]; then
  warn "ytSearch.js not found at expected paths — writing to src/utils/ytSearch.js"
  mkdir -p src/utils
  YT_SEARCH_PATH="src/utils/ytSearch.js"
else
  cp "$YT_SEARCH_PATH" "${YT_SEARCH_PATH}.bak"
  ok "Backup saved → ${YT_SEARCH_PATH}.bak"
fi

log "Writing ${YT_SEARCH_PATH} …"
cat > "$YT_SEARCH_PATH" << 'EOF'
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
EOF
ok "${YT_SEARCH_PATH} updated"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  All done! Files written:                            ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  vercel.json                                         ║${RESET}"
echo -e "${GREEN}║  api/ytproxy.js              ← Vercel function       ║${RESET}"
echo -e "${GREEN}║  netlify.toml                                        ║${RESET}"
echo -e "${GREEN}║  netlify/functions/ytproxy.js ← Netlify function     ║${RESET}"
echo -e "${GREEN}║  vite.config.js              (backup: .bak)          ║${RESET}"
echo -e "${GREEN}║  ${YT_SEARCH_PATH}$(printf '%*s' $((38 - ${#YT_SEARCH_PATH})) "")║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps:                                         ║${RESET}"
echo -e "${GREEN}║  1. git add -A && git commit -m 'fix: yt proxy prod' ║${RESET}"
echo -e "${GREEN}║  2. git push  → Vercel/Netlify redeploys             ║${RESET}"
echo -e "${GREEN}║  3. Test: npm run dev  (proxy still works in dev)    ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
