# Deployment Guide for Render

This guide will help you deploy your stock market backend to Render.

## Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **Git Repository**: Your code should be in a Git repository (GitHub, GitLab, etc.)
3. **Finnhub API Key**: Sign up at [finnhub.io](https://finnhub.io) to get your API key

## Files Created for Deployment

1. **`backend/Dockerfile.prod`** - Production-ready Docker configuration
2. **`render.yaml`** - Render deployment configuration
3. **`backend/.dockerignore`** - Docker build optimization
4. **Updated `backend/config.go`** - Environment variable handling for production

## Step-by-Step Deployment

### 1. Push Your Code to Git

Ensure all your changes are committed and pushed to your Git repository:

```bash
git add .
git commit -m "Add Render deployment configuration"
git push origin main
```

### 2. Deploy to Render

#### Option A: Using render.yaml (Recommended)

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" and select "Blueprint"
3. Connect your Git repository
4. Render will automatically detect the `render.yaml` file
5. Review the configuration and click "Apply"

#### Option B: Manual Setup

1. **Create Database:**
   - Go to Render Dashboard
   - Click "New +" → "PostgreSQL"
   - Name: `stock-market-db`
   - Plan: Free
   - Database Name: `stock_tracker`
   - User: `stock_user`
   - Click "Create Database"

2. **Create Web Service:**
   - Click "New +" → "Web Service"
   - Connect your Git repository
   - Name: `stock-market-backend`
   - Environment: `Docker`
   - Docker Context: `./backend`
   - Dockerfile Path: `./backend/Dockerfile.prod`
   - Plan: Free
   - Click "Create Web Service"

### 3. Set Environment Variables

In your web service settings, add these environment variables:

| Variable | Value | Source |
|----------|-------|---------|
| `API_KEY` | `your_finnhub_api_key` | Manual |
| `DB_HOST` | Database host | Auto-generated from database |
| `DB_USER` | Database user | Auto-generated from database |
| `DB_PASSWORD` | Database password | Auto-generated from database |
| `DB_NAME` | Database name | Auto-generated from database |
| `DB_SSL_MODE` | `require` | Manual |

### 4. Configure Database Connection

1. Go to your database dashboard
2. Copy the connection details
3. In your web service, go to "Environment"
4. Add the database environment variables (if not auto-configured)

### 5. Deploy and Test

1. Your service will automatically deploy after setup
2. Monitor the deploy logs for any issues
3. Test the health endpoint: `https://your-app.onrender.com/health`
4. Test the API endpoints:
   - `GET /symbols` - Get available symbols
   - `GET /stocks-history` - Get historical data
   - `WS /ws` - WebSocket connection

## Frontend Configuration

Update your Flutter app's `frontend/lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Production URLs (replace with your actual Render URL)
  static const String baseUrl = 'https://your-app-name.onrender.com';
  static const String wsUrl = 'wss://your-app-name.onrender.com/ws';
  
  // Development URLs (for local testing)
  static const String devBaseUrl = 'http://localhost:8080';
  static const String devWsUrl = 'ws://localhost:8080/ws';
  
  // Other constants...
}
```

## Environment-Specific Configuration

Consider creating environment-specific configurations:

```dart
class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  static String get baseUrl => isProduction 
    ? 'https://your-app-name.onrender.com'
    : 'http://localhost:8080';
    
  static String get wsUrl => isProduction
    ? 'wss://your-app-name.onrender.com/ws'
    : 'ws://localhost:8080/ws';
}
```

## Common Issues and Solutions

### 1. Database Connection Issues
- Ensure `DB_SSL_MODE` is set to `require`
- Check database connection variables
- Verify database is running and accessible

### 2. API Key Issues
- Ensure your Finnhub API key is valid
- Check API key permissions
- Verify environment variable name matches code

### 3. CORS Issues
- CORS is configured in the backend to allow all origins
- For production, consider restricting origins

### 4. WebSocket Connection Issues
- Ensure WebSocket URL uses `wss://` for HTTPS
- Check firewall and network settings
- Monitor connection logs

## Monitoring and Logs

1. **View Logs**: Go to your service → "Logs" tab
2. **Monitor Health**: Use the `/health` endpoint
3. **Database Metrics**: Monitor database performance in Render dashboard
4. **Alerts**: Set up alerts for service downtime

## Scaling Considerations

### Free Tier Limitations
- Services sleep after 15 minutes of inactivity
- Database has connection limits
- Limited compute resources

### Upgrade Options
- **Starter Plan**: Prevents sleeping, more resources
- **Professional Plan**: Better performance, more database connections
- **Custom Plans**: Enterprise-level features

## Security Best Practices

1. **Environment Variables**: Never commit sensitive data
2. **Database Security**: Use strong passwords, enable SSL
3. **API Keys**: Rotate regularly, use least privilege
4. **CORS**: Restrict origins in production
5. **HTTPS**: Always use HTTPS in production

## Maintenance

1. **Regular Updates**: Keep dependencies updated
2. **Database Backups**: Render provides automatic backups
3. **Monitor Performance**: Watch for slow queries
4. **Error Tracking**: Implement proper error logging

## Support

- [Render Documentation](https://render.com/docs)
- [Render Community](https://community.render.com)
- [GitHub Issues](https://github.com/your-username/your-repo/issues)

## Next Steps

1. Deploy the backend following this guide
2. Test all endpoints
3. Update your Flutter app with the production URLs
4. Deploy your Flutter app (web/mobile)
5. Set up monitoring and alerts 