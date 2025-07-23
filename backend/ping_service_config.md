# Render Keep-Alive Configuration

## Problem
Free Render instances go to sleep after 15 minutes of inactivity, causing delays when the instance wakes up.

## Solution
This backend now includes multiple keep-alive mechanisms:

### 1. Internal Keep-Alive (Already Implemented)
- The server pings itself every 10 minutes via `/health` endpoint
- Automatic reconnection to Finnhub WebSocket when connection is lost
- Connection health monitoring every 30 seconds

### 2. External Ping Services (Recommended)

#### Option A: UptimeRobot (Free)
1. Go to https://uptimerobot.com/
2. Create a free account
3. Add a new monitor:
   - Monitor Type: HTTP(s)
   - Friendly Name: Stock Tracker Backend
   - URL: `https://your-app-name.onrender.com/ping`
   - Monitoring Interval: 5 minutes
   - Alert When Down: Yes

#### Option B: Cron-job.org (Free)
1. Go to https://cron-job.org/
2. Create a free account
3. Add a new cronjob:
   - URL: `https://your-app-name.onrender.com/ping`
   - Schedule: Every 5 minutes
   - Timezone: Your timezone

#### Option C: GitHub Actions (Free)
Create `.github/workflows/ping-backend.yml`:
```yaml
name: Ping Backend
on:
  schedule:
    - cron: '*/5 * * * *'  # Every 5 minutes
  workflow_dispatch:  # Manual trigger

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Backend
        run: |
          curl -f https://your-app-name.onrender.com/ping || echo "Ping failed"
```

#### Option D: Simple HTML with JavaScript
Create a simple HTML file and open it in a browser tab:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Backend Keep-Alive</title>
</head>
<body>
    <h1>Backend Keep-Alive</h1>
    <p>Last ping: <span id="lastPing">Never</span></p>
    <p>Status: <span id="status">Unknown</span></p>
    
    <script>
        const BACKEND_URL = 'https://your-app-name.onrender.com/ping';
        
        async function pingBackend() {
            try {
                const response = await fetch(BACKEND_URL);
                const data = await response.json();
                document.getElementById('lastPing').textContent = new Date().toLocaleString();
                document.getElementById('status').textContent = 'Online';
                document.getElementById('status').style.color = 'green';
            } catch (error) {
                document.getElementById('status').textContent = 'Offline';
                document.getElementById('status').style.color = 'red';
            }
        }
        
        // Ping immediately
        pingBackend();
        
        // Ping every 5 minutes
        setInterval(pingBackend, 5 * 60 * 1000);
    </script>
</body>
</html>
```

## New Endpoints

### `/ping` - Keep-alive endpoint
- Returns: `{"pong": "2024-01-01T12:00:00Z"}`
- Use this for external ping services

### `/status` - Connection status
- Returns detailed connection information
- Useful for monitoring

### `/health` - Enhanced health check
- Now includes Finnhub connection status
- Used by internal keep-alive mechanism

## Benefits
1. **Prevents Sleep**: External pings keep the instance alive
2. **Fast Recovery**: When instance wakes up, it immediately reconnects to Finnhub
3. **Automatic Reconnection**: Handles connection drops gracefully
4. **Monitoring**: Easy to check if everything is working

## Recommended Setup
1. Use UptimeRobot (Option A) for reliable monitoring
2. Keep the internal keep-alive as backup
3. Monitor the `/status` endpoint to ensure Finnhub connection is healthy

## Cost
- All solutions above are **FREE**
- No need to upgrade Render instance
- Minimal resource usage 