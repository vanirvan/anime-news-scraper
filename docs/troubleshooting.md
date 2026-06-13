# Troubleshooting Guide

Common issues and solutions for the anime news scraper.

---

## Table of Contents

1. [Docker & Container Issues](#docker--container-issues)
2. [n8n Issues](#n8n-issues)
3. [PostgreSQL Issues](#postgresql-issues)
4. [RSS Feed Issues](#rss-feed-issues)
5. [Web Scraping Issues](#web-scraping-issues)
6. [Workflow Issues](#workflow-issues)
7. [Performance Issues](#performance-issues)

---

## Docker & Container Issues

### Container Won't Start

**Symptoms:**
- `docker-compose up` fails
- Container exits immediately

**Check:**
```powershell
# View container logs
docker-compose logs n8n
docker-compose logs postgres

# Check container status
docker-compose ps

# Check if ports are in use
netstat -ano | findstr :5678
netstat -ano | findstr :5432
```

**Solutions:**

| Issue | Solution |
|-------|----------|
| Port 5678 in use | Change port in docker-compose.yml |
| Port 5432 in use | Change port or stop existing PostgreSQL |
| Volume permission error | Run PowerShell as Administrator |
| Out of memory | Increase Docker memory allocation |

**Port Conflicts:**
```yaml
# Change ports in docker-compose.yml
services:
  n8n:
    ports:
      - "5679:5678"  # Use 5679 externally
  
  postgres:
    ports:
      - "5433:5432"  # Use 5433 externally
```

### Container Keeps Restarting

**Check logs:**
```powershell
docker-compose logs --tail=100 n8n
```

**Common causes:**
- Database connection failed
- Invalid environment variables
- Volume mount issues

### Reset Everything

```powershell
# Stop all containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Rebuild and start
docker-compose up -d --build
```

---

## n8n Issues

### Can't Access n8n Web Interface

**Symptoms:**
- Browser shows "can't connect"
- Timeout error

**Check:**
```powershell
# Is n8n container running?
docker-compose ps n8n

# Check n8n logs
docker-compose logs n8n

# Try internal access from container
docker exec -it anime-news-n8n wget -q -O- http://localhost:5678
```

**Solutions:**

| Issue | Solution |
|-------|----------|
| Container not running | `docker-compose start n8n` |
| Wrong URL | Use http://localhost:5678 (not https) |
| Firewall blocking | Allow port 5678 in Windows Firewall |
| Browser cache | Clear cache or use incognito |

### n8n Shows "Connection Lost"

**Cause:** n8n process crashed or restarted

**Solution:**
```powershell
# Restart n8n
docker-compose restart n8n

# Check for errors
docker-compose logs --tail=50 n8n
```

### Workflow Won't Save

**Symptoms:**
- "Failed to save" error
- Changes lost after refresh

**Causes:**
1. Database connection issue
2. Out of disk space
3. Permission issues

**Check:**
```powershell
# Check disk space
docker system df

# Check n8n data volume
docker exec -it anime-news-n8n df -h /home/node/.n8n
```

### Credentials Not Working

**Symptoms:**
- "Credential not found" error
- "Connection failed" when testing

**Solutions:**

| Credential Type | Fix |
|-----------------|-----|
| PostgreSQL | Verify host is `postgres` (not localhost) |
| HTTP Header | Check header name and value format |
| Query Parameter | Ensure proper URL encoding |

**Test PostgreSQL Connection:**
```powershell
# Connect from host
docker exec -it anime-news-db psql -U postgres -d anime_news

# Test from n8n container
docker exec -it anime-news-n8n nc -zv postgres 5432
```

---

## PostgreSQL Issues

### Connection Refused

**Error:** `Connection refused` or `could not connect to server`

**Check:**
```powershell
# Is PostgreSQL running?
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres
```

**Solutions:**

| Issue | Solution |
|-------|----------|
| Container not running | `docker-compose start postgres` |
| Still initializing | Wait 30 seconds, try again |
| Wrong host | Use `postgres` (container name), not localhost |
| Wrong port | Use `5432` (internal port) |

### Authentication Failed

**Error:** `FATAL: password authentication failed`

**Check credentials in .env:**
```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password_here
POSTGRES_DB=anime_news
```

**Reset password:**
```powershell
# Connect to PostgreSQL
docker exec -it anime-news-db psql -U postgres

# Change password
ALTER USER postgres PASSWORD 'new_password';
```

### Database Doesn't Exist

**Error:** `FATAL: database "anime_news" does not exist`

**Create database:**
```powershell
# Connect to PostgreSQL
docker exec -it anime-news-db psql -U postgres

# Create database
CREATE DATABASE anime_news;

# Connect to it
\c anime_news

# Run schema
\i /docker-entrypoint-initdb.d/01-schema.sql
```

### Table Doesn't Exist

**Error:** `relation "news_items" does not exist`

**Check tables:**
```powershell
docker exec -it anime-news-db psql -U postgres -d anime_news -c "\dt"
```

**Create tables manually:**
```powershell
# Copy schema to container
docker cp database/schema.sql anime-news-db:/tmp/

# Execute schema
docker exec -it anime-news-db psql -U postgres -d anime_news -f /tmp/schema.sql
```

### Query Timeout

**Error:** `Query read timeout`

**Causes:**
- Too many rows
- Missing indexes
- Slow query

**Solutions:**
```sql
-- Add indexes
CREATE INDEX IF NOT EXISTS idx_news_items_status ON news_items(status);
CREATE INDEX IF NOT EXISTS idx_news_items_published ON news_items(published_at DESC);

-- Limit query results
SELECT * FROM news_items WHERE status = 'new' LIMIT 100;

-- Analyze query
EXPLAIN ANALYZE SELECT * FROM news_items WHERE status = 'new';
```

---

## RSS Feed Issues

### RSS Feed Returns Empty

**Symptoms:**
- RSS node succeeds but returns no items
- Empty array in output

**Check:**
1. Open RSS URL in browser
2. Verify it shows XML content
3. Check for `<item>` elements

**Common causes:**

| Issue | Solution |
|-------|----------|
| Invalid RSS URL | Verify correct URL |
| RSS moved | Check website for new RSS URL |
| No recent posts | Site may not have posted recently |
| XML parsing error | RSS may be malformed |

**Test RSS in browser:**
```
https://www.animenewsnetwork.com/news/rss.xml
```

Should show XML like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>...</title>
      <link>...</link>
    </item>
  </channel>
</rss>
```

### RSS Feed Timeout

**Error:** `ETIMEDOUT` or `Request timeout`

**Solutions:**
```
In n8n RSS node:
├── Options
│   └── Timeout: 30000  (increase to 30 seconds)
```

### RSS Content Missing

**Symptoms:**
- RSS returns items
- `content` or `contentSnippet` is empty

**Explanation:**
Some RSS feeds only include title and link, not full content.

**Solution:**
Use RSS for discovery, then scrape the URL:
```
[RSS Read]
    │
    ▼
[HTTP Request: Fetch article URL]
    │
    ▼
[HTML Extract: Get full content]
```

### RSS Character Encoding Issues

**Symptoms:**
- Garbled text
- Weird characters like `â€™` instead of `'`

**Solution:**
```javascript
// In Code node, fix encoding
const decodedText = decodeURIComponent(escape(item.json.title));
```

---

## Web Scraping Issues

### HTTP 403 Forbidden

**Error:** `HTTP 403` or `Access Denied`

**Causes:**
- Site blocks automated requests
- Bot detection
- Rate limiting

**Solutions:**

1. **Add User-Agent header:**
```
In HTTP Request node:
├── Options
│   └── Header Parameters
│       ├── Name: User-Agent
│       └── Value: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

2. **Add delay between requests:**
```
[Loop]
    │
    ▼
[Wait: 5 seconds]
    │
    ▼
[HTTP Request]
```

3. **Try different time:**
Some sites have stricter limits during peak hours.

### HTTP 429 Too Many Requests

**Error:** `HTTP 429` or `Rate limit exceeded`

**Cause:** Too many requests in short time

**Solutions:**

1. **Increase wait time:**
```
[Wait: 10 seconds]  (between each request)
```

2. **Reduce batch size:**
```
[Loop Over Items: Batch Size 1]
```

3. **Implement exponential backoff:**
```javascript
// In Code node
const retryCount = item.json.retryCount || 0;
const waitTime = Math.pow(2, retryCount) * 1000; // 1s, 2s, 4s, 8s...
```

### HTML Extract Returns Empty

**Symptoms:**
- HTTP request succeeds
- HTML Extract returns empty values

**Causes:**

1. **Wrong selector:**
```javascript
// Test selector in browser console
document.querySelector('h1.article-title')?.textContent
```

2. **Content loaded via JavaScript:**
Some sites render content dynamically.

**Check:**
- View page source (Ctrl+U)
- Search for content in HTML
- If not found, site uses JavaScript rendering

**Solution for JS-rendered sites:**
Need Puppeteer/Playwright (not covered in basic setup).

3. **Different page structure:**
Different article types may have different selectors.

**Solution:**
Use multiple fallback selectors:
```javascript
// In Code node
const title = 
  $('h1.article-title').text() ||
  $('h1.title').text() ||
  $('h1').first().text();
```

### SSL/Certificate Errors

**Error:** `UNABLE_TO_VERIFY_LEAF_SIGNATURE`

**Solution:**
```
In HTTP Request node:
├── Options
│   └── Reject Unauthorized: false
```

### Redirect Issues

**Symptoms:**
- HTTP request follows redirect
- Ends up on wrong page

**Check redirect chain:**
```powershell
curl -I -L "https://example.com/article"
```

**Solutions:**
```
In HTTP Request node:
├── Options
│   └── Redirect
│       ├── Redirect: Manual  (handle yourself)
│       └── or Follow: Automatic
```

---

## Workflow Issues

### Workflow Doesn't Run on Schedule

**Check:**
1. Is workflow activated? (toggle in top right)
2. Is n8n running?
3. Check execution history

```powershell
# Check n8n is running
docker-compose ps n8n

# Check n8n logs
docker-compose logs --tail=50 n8n
```

**Common causes:**

| Issue | Solution |
|-------|----------|
| Workflow inactive | Toggle to Active |
| Cron expression wrong | Use simple interval first |
| n8n restarted | Workflows stay active, but check |
| Timezone mismatch | Set GENERIC_TIMEZONE in .env |

### Workflow Stuck Running

**Symptoms:**
- Workflow shows "Running" forever
- Can't execute again

**Force stop:**
```powershell
# Restart n8n
docker-compose restart n8n
```

**Prevent:**
Add timeout to HTTP requests:
```
[HTTP Request]
├── Options
│   └── Timeout: 10000  (10 seconds)
```

### Duplicate Items Inserted

**Symptoms:**
- Same article appears multiple times
- URL column should prevent this

**Causes:**

1. **URL variations:**
```javascript
// Same article, different URLs
https://example.com/article
https://example.com/article?ref=rss
https://example.com/article#comments
```

**Solution - normalize URLs:**
```javascript
// In Code node, before insert
const url = new URL(item.json.url);
item.json.url = url.origin + url.pathname; // Remove query params and hash
```

2. **Remove Duplicates not working:**
```
Check configuration:
├── Compare: Selected Fields
├── Fields to Compare: url (not URL)
└── Case Sensitive: false
```

### Workflow Execution Order Wrong

**Symptoms:**
- Nodes execute in wrong order
- Data missing in later nodes

**Check:**
1. Visual connections in workflow
2. Node order in execution view

**Common mistake:**
```
Wrong:
[Node A] ──> [Node B]
    │
    └──────> [Node C]

Node C runs parallel with Node B, doesn't wait for B's output
```

**Fix:**
```
Correct:
[Node A] ──> [Node B] ──> [Node C]
```

---

## Performance Issues

### Slow Workflow Execution

**Causes:**

1. **Too many HTTP requests:**
```
If processing 100 articles with 3 second delays:
100 × 3 = 300 seconds = 5 minutes
```

**Solutions:**
- Filter RSS items first (only process last 20)
- Run multiple workflows in parallel for different sources
- Cache results

2. **Large HTML pages:**
Some sites have massive HTML (5MB+)

**Solution:**
```
In HTTP Request:
├── Options
│   └── Response Format: String
│   └── Timeout: 30000
```

3. **No database indexes:**

**Add indexes:**
```sql
CREATE INDEX idx_news_items_status ON news_items(status);
CREATE INDEX idx_news_items_url ON news_items(url);
CREATE INDEX idx_news_items_published ON news_items(published_at DESC);
```

### Out of Memory

**Symptoms:**
- n8n crashes
- Container restarts

**Check memory:**
```powershell
docker stats anime-news-n8n
```

**Solutions:**

1. **Increase Docker memory:**
Docker Desktop > Settings > Resources > Memory

2. **Process in batches:**
```
[Loop Over Items: Batch Size 10]
```

3. **Clear old executions:**
In n8n: Settings > Executions > Clear old executions

### Disk Full

**Check:**
```powershell
docker system df
```

**Clean up:**
```powershell
# Remove unused containers, networks, images
docker system prune -a

# Remove unused volumes
docker volume prune
```

---

## Quick Diagnostic Commands

```powershell
# Check all containers
docker-compose ps

# Check all logs
docker-compose logs --tail=100

# Check specific service
docker-compose logs --tail=50 n8n
docker-compose logs --tail=50 postgres

# Check container resources
docker stats --no-stream

# Restart everything
docker-compose restart

# Full reset (WARNING: deletes data)
docker-compose down -v
docker-compose up -d

# Check PostgreSQL
docker exec -it anime-news-db psql -U postgres -d anime_news -c "SELECT COUNT(*) FROM news_items;"

# Check n8n health
curl http://localhost:5678/healthz
```

---

## Getting Help

### Information to Gather

Before asking for help, collect:

1. **Error message:** Full text of error
2. **n8n version:** Settings > About
3. **Docker logs:** `docker-compose logs n8n`
4. **Workflow export:** Download workflow JSON
5. **Steps to reproduce:** What you did before error

### Resources

- [n8n Community Forum](https://community.n8n.io/)
- [n8n Documentation](https://docs.n8n.io/)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-09 | Initial troubleshooting guide |
