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
