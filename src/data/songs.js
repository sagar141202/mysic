export const SONGS = [
  { id: 1,  title: 'Blinding Lights',    artist: 'The Weeknd',        album: 'After Hours',      duration: 200, color: '#22d3ee', youtubeId: 'fHI8X4OXluQ', genre: 'pop' },
  { id: 2,  title: 'Rait Zara Si',       artist: 'A.R. Rahman',       album: 'Atrangi Re',       duration: 242, color: '#f59e0b', youtubeId: 'TV5MTCuHgMw', genre: 'bollywood' },
  { id: 3,  title: 'Dholida',            artist: 'Jonita Gandhi',      album: 'Gangubai',         duration: 225, color: '#818cf8', youtubeId: 'OQU2PTee3H8', genre: 'bollywood' },
  { id: 4,  title: 'Doobey',             artist: 'Rekha Bhardwaj',     album: 'Gehraiyaan',       duration: 270, color: '#22d3ee', youtubeId: 'z9MtZrPgDwQ', genre: 'bollywood' },
  { id: 5,  title: 'Hum Nashe Mein',     artist: 'Arijit Singh',       album: 'Bhoot Police',     duration: 238, color: '#f59e0b', youtubeId: 'AzNbS6HMVCA', genre: 'bollywood' },
  { id: 6,  title: 'Shape of You',       artist: 'Ed Sheeran',         album: 'Divide',           duration: 233, color: '#0ea5e9', youtubeId: 'JGwWNGJdvx8', genre: 'pop' },
  { id: 7,  title: 'Secrets',            artist: 'Tiesto & KSHMR',     album: 'Singles',          duration: 192, color: '#818cf8', youtubeId: 'hOwkiegHAaQ', genre: 'edm' },
  { id: 8,  title: 'Mi Cama',            artist: 'Karol G',            album: 'Ocean',            duration: 187, color: '#22d3ee', youtubeId: 'fbRoKCHEMqo', genre: 'latin' },
  { id: 9,  title: 'Levitating',         artist: 'Dua Lipa',           album: 'Future Nostalgia', duration: 203, color: '#818cf8', youtubeId: 'TUVcZfQe-Kw', genre: 'pop' },
  { id: 10, title: 'Peaches',            artist: 'Justin Bieber',      album: 'Justice',          duration: 198, color: '#f59e0b', youtubeId: 'tQ0yjYUFBDI', genre: 'pop' },
  { id: 11, title: 'Stay',               artist: 'Kid LAROI',          album: 'F*CK LOVE 3',      duration: 141, color: '#22d3ee', youtubeId: 'kTJczUoc26U', genre: 'pop' },
  { id: 12, title: 'Heat Waves',         artist: 'Glass Animals',      album: 'Dreamland',        duration: 238, color: '#0ea5e9', youtubeId: 'mRD0-GxqHVo', genre: 'indie' },
  { id: 13, title: 'Kesariya',           artist: 'Arijit Singh',       album: 'Brahmastra',       duration: 275, color: '#f59e0b', youtubeId: 'BddP6PYo2gs', genre: 'bollywood' },
  { id: 14, title: 'Tum Se Hi',          artist: 'Mohit Chauhan',      album: 'Jab We Met',       duration: 310, color: '#818cf8', youtubeId: 'lzMeECFlBXM', genre: 'bollywood' },
  { id: 15, title: 'Bad Guy',            artist: 'Billie Eilish',      album: 'When We Fall',     duration: 194, color: '#0ea5e9', youtubeId: 'DyDfgMOUjCI', genre: 'pop' },
  { id: 16, title: 'Save Your Tears',    artist: 'The Weeknd',         album: 'After Hours',      duration: 215, color: '#818cf8', youtubeId: 'LIIDh-qI9oI', genre: 'pop' },
  { id: 17, title: 'Dynamite',           artist: 'BTS',                album: 'BE',               duration: 199, color: '#f59e0b', youtubeId: 'gdZLi9oWNZg', genre: 'kpop' },
  { id: 18, title: 'Apna Bana Le',       artist: 'Arijit Singh',       album: 'Bhediya',          duration: 261, color: '#22d3ee', youtubeId: 'BuTRnNfrR3A', genre: 'bollywood' },
  { id: 19, title: 'Calm Down',          artist: 'Rema',               album: 'Rave & Roses',     duration: 239, color: '#818cf8', youtubeId: 'WcawKMGBhDc', genre: 'afrobeats' },
  { id: 20, title: 'As It Was',          artist: 'Harry Styles',       album: "Harry's House",    duration: 167, color: '#0ea5e9', youtubeId: 'H5v3kku4y6Q', genre: 'pop' },
]

export const FEATURED = [
  { songId: 1, icon: 'diamond', plays: '2.1B' },
  { songId: 2, icon: 'circle',  plays: '890M' },
  { songId: 7, icon: 'star',    plays: '430M' },
]

export const COLLECTIONS = [
  { name: 'Chillout',   count: '206 songs', color: '#22d3ee', songIds: [2, 4, 5, 14] },
  { name: 'Workout',    count: '137 songs', color: '#f59e0b', songIds: [1, 6, 7, 15] },
  { name: 'Late Night', count: '89 songs',  color: '#818cf8', songIds: [3, 7, 8, 12] },
  { name: 'Bollywood',  count: '312 songs', color: '#0ea5e9', songIds: [2, 3, 4, 5, 13, 14, 18] },
]

export const PLAYLISTS = [
  { id: 'p1', name: 'Late Night Drive', count: '6 songs',  color: '#22d3ee', songIds: [2, 4, 8, 12, 14, 19] },
  { id: 'p2', name: 'Workout Beast',    count: '5 songs',  color: '#f59e0b', songIds: [1, 6, 7, 15, 17] },
  { id: 'p3', name: 'Chill Sunday',     count: '5 songs',  color: '#818cf8', songIds: [2, 3, 4, 9, 20] },
  { id: 'p4', name: 'Bollywood Fire',   count: '6 songs',  color: '#0ea5e9', songIds: [3, 4, 5, 13, 14, 18] },
  { id: 'p5', name: 'Deep Focus',       count: '4 songs',  color: '#818cf8', songIds: [7, 8, 12, 19] },
]

export const GENRES = [
  { name: 'Bollywood', color: '#f59e0b', key: 'bollywood' },
  { name: 'Pop',       color: '#22d3ee', key: 'pop' },
  { name: 'EDM',       color: '#818cf8', key: 'edm' },
  { name: 'Indie',     color: '#0ea5e9', key: 'indie' },
  { name: 'K-Pop',     color: '#f472b6', key: 'kpop' },
  { name: 'Latin',     color: '#34d399', key: 'latin' },
  { name: 'Afrobeats', color: '#fb923c', key: 'afrobeats' },
]

export const getSongById  = id => SONGS.find(s => s.id === id) || null
export const getSongsByIds = ids => ids.map(id => getSongById(id)).filter(Boolean)

export const formatTime = secs => {
  const s = Math.floor(secs)
  const m = Math.floor(s / 60)
  const r = s % 60
  return `${m}:${r.toString().padStart(2, '0')}`
}
