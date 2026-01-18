const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(cors());

// Read key from env var GOOGLE_MAPS_API_KEY. If not set, fall back to
// the Android/iOS API key present in the project (not recommended for
// production — prefer setting the env var in your deployment).
const API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyAQotbaHvSA1So3d13mrykIA0XgsE1Ebq0';

app.get('/', async (req, res) => {
  try {
    const { lat, lng, w = '600', h = '300', zoom = '15', marker = 'true' } = req.query;
    if (!lat || !lng) return res.status(400).send('Missing lat or lng');
    const key = API_KEY || process.env.VITE_GOOGLE_MAPS_API_KEY;
    if (!key) return res.status(500).send('Google Maps API key not configured');

    // Build Google Static Maps URL
    const size = `${Math.min(Math.max(parseInt(w, 10), 100), 2048)}x${Math.min(Math.max(parseInt(h, 10), 100), 2048)}`;
    const markerParam = marker === 'true' ? `&markers=color:red%7C${lat},${lng}` : '';
    const staticUrl = `https://maps.googleapis.com/maps/api/staticmap?center=${lat},${lng}&zoom=${zoom}&size=${size}${markerParam}&key=${key}&scale=2`;

    const resp = await axios.get(staticUrl, { responseType: 'arraybuffer' });
    const contentType = resp.headers['content-type'] || 'image/png';
    res.set('Content-Type', contentType);
    res.send(resp.data);
  } catch (err) {
    console.error('map-proxy error', err?.message || err);
    res.status(500).send('Error fetching map');
  }
});

// For local testing
if (require.main === module) {
  const port = process.env.PORT || 8080;
  app.listen(port, () => console.log(`Map proxy listening on http://localhost:${port}`));
}

module.exports = app;