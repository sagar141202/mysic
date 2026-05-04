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
