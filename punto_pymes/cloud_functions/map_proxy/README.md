Map Proxy for Google Static Maps

Purpose
- Proxy Google Static Maps requests so the API key stays on the server (not embedded in the mobile client).

Local run
1. Install dependencies:

```bash
cd cloud_functions/map_proxy
npm install
```

2. Run locally:

```bash
GOOGLE_MAPS_API_KEY=YOUR_API_KEY npm start
# then open: http://localhost:8080/?lat=-0.2&lng=-78.5&w=600&h=300
```

Deploy to Google Cloud Functions (HTTP)
1. Zip or deploy using `gcloud`:

```bash
gcloud functions deploy mapProxy \
  --region=us-central1 \
  --runtime=nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=app \
  --set-env-vars=GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```

Notes
- Use a restricted API key (HTTP referrers or set up IAM) and billing enabled for Static Maps.
- After deployment, copy the function URL and set `googleMapFunctionUrl` in `lib/config/supabase_config.dart` to that URL.
- Consider adding authentication to the function to avoid abuse.
