// ─── Master song list ────────────────────────────────────────────────────────
export const SONGS = [
  {
    id: 1,
    title:     'Blinding Lights',
    artist:    'The Weeknd',
    album:     'After Hours',
    duration:  200,
    color:     '#22d3ee',
    youtubeId: 'fHI8X4OXluQ',
  },
  {
    id: 2,
    title:     'Rait Zara Si',
    artist:    'A.R. Rahman',
    album:     'Atrangi Re',
    duration:  242,
    color:     '#f59e0b',
    youtubeId: 'TV5MTCuHgMw',
  },
  {
    id: 3,
    title:     'Dholida',
    artist:    'Jonita Gandhi',
    album:     'Gangubai',
    duration:  225,
    color:     '#818cf8',
    youtubeId: 'OQU2PTee3H8',
  },
  {
    id: 4,
    title:     'Doobey',
    artist:    'Rekha Bhardwaj',
    album:     'Gehraiyaan',
    duration:  270,
    color:     '#22d3ee',
    youtubeId: 'z9MtZrPgDwQ',
  },
  {
    id: 5,
    title:     'Hum Nashe Mein',
    artist:    'Arijit Singh',
    album:     'Bhoot Police',
    duration:  238,
    color:     '#f59e0b',
    youtubeId: 'AzNbS6HMVCA',
  },
  {
    id: 6,
    title:     'Shape of You',
    artist:    'Ed Sheeran',
    album:     'Divide',
    duration:  233,
    color:     '#0ea5e9',
    youtubeId: 'JGwWNGJdvx8',
  },
  {
    id: 7,
    title:     'Secrets',
    artist:    'Tiesto & KSHMR',
    album:     'Singles',
    duration:  192,
    color:     '#818cf8',
    youtubeId: 'hOwkiegHAaQ',
  },
  {
    id: 8,
    title:     'Mi Cama',
    artist:    'Karol G',
    album:     'Ocean',
    duration:  187,
    color:     '#22d3ee',
    youtubeId: 'fbRoKCHEMqo',
  },
]

export const FEATURED = [
  { songId: 1, icon: 'diamond', plays: '2.1B' },
  { songId: 2, icon: 'circle',  plays: '890M' },
  { songId: 7, icon: 'star',    plays: '430M' },
]

export const COLLECTIONS = [
  { name: 'Chillout',   count: '206 songs', color: '#22d3ee', songIds: [2, 4, 5] },
  { name: 'Workout',    count: '137 songs', color: '#f59e0b', songIds: [1, 6, 7] },
  { name: 'Late Night', count: '89 songs',  color: '#818cf8', songIds: [3, 7, 8] },
  { name: 'Bollywood',  count: '312 songs', color: '#0ea5e9', songIds: [2, 3, 4, 5] },
]

export const PLAYLISTS = [
  { name: 'Late Night Drive', count: '24 songs', songIds: [2, 4, 8] },
  { name: 'Workout Beast',    count: '18 songs', songIds: [1, 6, 7] },
  { name: 'Chill Sunday',     count: '31 songs', songIds: [2, 3, 4] },
  { name: 'Bollywood Fire',   count: '47 songs', songIds: [3, 4, 5] },
  { name: 'Deep Focus',       count: '12 songs', songIds: [7, 8]    },
]

export const getSongById = id => SONGS.find(s => s.id === id) || null

export const formatTime = secs => {
  const s = Math.floor(secs)
  const m = Math.floor(s / 60)
  const r = s % 60
  return `${m}:${r.toString().padStart(2, '0')}`
}
