# Anime News Scraper - Implementation Plan

## Project Overview

Build a local n8n-based news aggregation system that:
- Monitors multiple anime, manga, idol, and Japanese news sources
- Fetches full article content (not just RSS snippets)
- Stores articles in PostgreSQL or JSON for manual curation
- Runs hourly with rate-limiting protection

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   ANIME NEWS AGGREGATION SYSTEM                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [Schedule Trigger: Every 1 Hour]                                    │
│                    │                                                 │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 DISCOVERY LAYER                              │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                              │    │
│  │  [RSS Feeds]                    [Web Scraping]               │    │
│  │  • Get article list             • Scrape listing pages       │    │
│  │  • Title, URL, snippet          • Extract article URLs       │    │
│  │  • Published date               • Site-specific selectors    │    │
│  │                                                              │    │
│  │  Output: List of article URLs to process                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                    │                                                 │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 CONTENT FETCH LAYER                          │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                              │    │
│  │  [Loop Over Each Article URL]                                │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [Wait Node: 2-3 seconds] ──> Rate limiting protection       │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [HTTP Request: Fetch Article Page]                          │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [HTML Extract: Parse Content]                               │    │
│  │    • Full article text                                       │    │
│  │    • Main image URL                                          │    │
│  │    • Author                                                  │    │
│  │    • Additional metadata                                     │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                    │                                                 │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 PROCESSING LAYER                             │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                              │    │
│  │  [Merge RSS Metadata + Scraped Content]                      │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [Remove Duplicates: Check by URL]                           │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [Filter: Keywords & Categories]                             │    │
│  │    • anime, manga, idol, seiyuu, j-pop                       │    │
│  │           │                                                  │    │
│  │           ▼                                                  │    │
│  │  [Code Node: Transform & Clean Data]                         │    │
│  │    • Standardize date formats                                │    │
│  │    • Clean HTML from content                                 │    │
│  │    • Extract image URLs                                      │    │
│  │    • Set status = 'new'                                      │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                    │                                                 │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 STORAGE LAYER                                │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                              │    │
│  │  Option A: PostgreSQL                                        │    │
│  │  ────────────────────                                        │    │
│  │  • news_items table                                          │    │
│  │  • Queryable via SQL                                         │    │
│  │  • Supports status tracking                                  │    │
│  │                                                              │    │
│  │  Option B: JSON Files                                        │    │
│  │  ────────────────────                                        │    │
│  │  • Daily JSON files: news-YYYY-MM-DD.json                    │    │
│  │  • Easy to read/edit in any text editor                      │    │
│  │  • Portable, no database setup needed                        │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                    │                                                 │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 CURATION LAYER                               │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                              │    │
│  │  Manual review of collected articles:                        │    │
│  │  • Mark as: reviewed, selected, rejected                     │    │
│  │  • Add notes for content creation                            │    │
│  │  • Export selected articles for content planning             │    │
│  │                                                              │    │
│  │  Interface options:                                          │    │
│  │  • SQL queries (pgAdmin, DBeaver)                            │    │
│  │  • JSON file viewing (VS Code, Notepad)                      │    │
│  │  • Custom simple web UI (optional)                           │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
anime-news-scrapper/
│
├── docker-compose.yml              # n8n + PostgreSQL container setup
├── .env                            # Environment variables (passwords, etc.)
├── .env.example                    # Template for .env
├── README.md                       # Project documentation
│
├── docs/
│   ├── implementation-plan.md      # This file
│   ├── sources.md                  # News sources list & selectors
│   ├── workflow-guide.md           # How to use n8n workflows
│   └── troubleshooting.md          # Common issues & solutions
│
├── database/
│   ├── schema.sql                  # PostgreSQL table definitions
│   └── init.sql                    # Initial data (source list)
│
├── n8n/
│   ├── workflows/
│   │   ├── main-workflow.json      # Primary aggregation workflow
│   │   ├── source-ann.json         # Anime News Network specific
│   │   ├── source-crunchyroll.json # Crunchyroll specific
│   │   └── ...                     # Other source-specific workflows
│   │
│   └── credentials/
│       └── .gitkeep                # Credentials stored in n8n UI
│
├── scripts/
│   ├── start.ps1                   # Start all services
│   ├── stop.ps1                    # Stop all services
│   ├── export-news.ps1             # Export curated news to JSON
│   └── query-news.ps1              # Query database helper
│
└── output/
    └── .gitkeep                    # Exported JSON files land here
```

---

## Implementation Phases

### Phase 1: Environment Setup (Day 1)

#### Tasks:
- [ ] Install Docker Desktop (Windows)
- [ ] Create project directory structure
- [ ] Create docker-compose.yml for n8n + PostgreSQL
- [ ] Create .env file with credentials
- [ ] Start containers: `docker-compose up -d`
- [ ] Verify n8n accessible at http://localhost:5678
- [ ] Verify PostgreSQL accessible

#### Commands:
```powershell
# Start containers
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f n8n

# Stop containers
docker-compose down
```

---

### Phase 2: Database Setup (Day 1)

#### Tasks:
- [ ] Create database schema (schema.sql)
- [ ] Initialize with default sources (init.sql)
- [ ] Connect to PostgreSQL from n8n
- [ ] Add PostgreSQL credentials in n8n

#### Database Schema:

```sql
-- Main news items table
CREATE TABLE news_items (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    url TEXT UNIQUE NOT NULL,
    source VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    published_at TIMESTAMP,
    content TEXT,
    content_snippet TEXT,
    image_url TEXT,
    author VARCHAR(200),
    fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'new',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sources tracking table
CREATE TABLE news_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    base_url TEXT NOT NULL,
    rss_url TEXT,
    type VARCHAR(20) NOT NULL,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    selectors JSONB,
    last_fetched_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_news_items_status ON news_items(status);
CREATE INDEX idx_news_items_published ON news_items(published_at DESC);
CREATE INDEX idx_news_items_category ON news_items(category);
CREATE INDEX idx_news_items_source ON news_items(source);
CREATE INDEX idx_news_sources_active ON news_sources(is_active);
```

---

### Phase 3: Source Analysis (Day 1-2)

#### Tasks:
- [ ] Identify target news sources
- [ ] Check RSS availability for each source
- [ ] Analyze HTML structure for each source
- [ ] Document CSS selectors for each source
- [ ] Update docs/sources.md with findings

#### Source Categories:

**Anime & Manga:**
- [ ] Anime News Network
- [ ] Crunchyroll News
- [ ] MyAnimeList News
- [ ] VIZ Media Blog
- [ ] Anime Corner

**Japanese News:**
- [ ] NHK World
- [ ] Japan Today
- [ ] Natalie Comic
- [ ] Oricon News

**Idol & J-Pop:**
- [ ] Natalie Music
- [ ] Oricon Idol
- [ ] Model Press

---

### Phase 4: Workflow Development (Day 2-3)

#### 4.1 Base Workflow Template

Create main-workflow.json with:

```
1. Schedule Trigger (Every 1 Hour)
   └─> Trigger at minute 0 of every hour

2. Get Active Sources (PostgreSQL Query)
   └─> SELECT * FROM news_sources WHERE is_active = true

3. For Each Source (Loop)
   │
   ├─> [If RSS exists]
   │     └─> RSS Read Node
   │           └─> Get list of articles
   │
   └─> [If No RSS]
         └─> HTTP Request (listing page)
               └─> HTML Extract (article URLs)
                     └─> Get list of articles

4. For Each Article URL (Loop)
   │
   └─> Wait Node (2-3 seconds)
         └─> Rate limiting protection
               └─> HTTP Request (article page)
                     └─> HTML Extract (content, image, author)
                           └─> Code Node (transform data)

5. Merge All Articles
   └─> Combine from all sources

6. Remove Duplicates
   └─> Check by URL

7. Filter by Keywords
   └─> anime, manga, idol, seiyuu, etc.

8. Insert to PostgreSQL
   └─> INSERT INTO news_items (...)
```

#### 4.2 Site-Specific Selectors

For each source, define selectors in news_sources table:

```json
{
  "title": "h1.article-title",
  "content": "div.article-body",
  "image": "img.article-image",
  "author": "span.author-name",
  "date": "time.published-date"
}
```

---

### Phase 5: Rate Limiting & Error Handling (Day 3)

#### Tasks:
- [ ] Add Wait nodes between requests
- [ ] Implement retry logic for failed requests
- [ ] Add error handling for missing selectors
- [ ] Log failed scrapes for manual review

#### Rate Limiting Strategy:

```
Between articles: 2-3 seconds delay
Between sources:  5 seconds delay
On error:         Exponential backoff (1s, 2s, 4s, 8s)
Max retries:      3
```

#### Error Handling:

```javascript
// Code node for error handling
try {
  // Process article
} catch (error) {
  return [{
    json: {
      error: error.message,
      url: item.json.url,
      source: item.json.source,
      timestamp: new Date().toISOString()
    }
  }];
}
```

---

### Phase 6: Testing (Day 3-4)

#### Tasks:
- [ ] Test each source individually
- [ ] Test full workflow end-to-end
- [ ] Verify data in PostgreSQL
- [ ] Check duplicate detection
- [ ] Verify rate limiting works
- [ ] Test error scenarios

#### Test Checklist:

```
□ RSS feed returns articles
□ HTTP request succeeds for each site
□ HTML extract returns correct data
□ Duplicates are properly filtered
□ Data inserted into PostgreSQL correctly
□ Workflow runs on schedule
□ Errors are logged properly
□ Rate limiting prevents blocks
```

---

### Phase 7: Curation Interface (Day 4)

#### Option A: SQL-Based Curation

```sql
-- View new articles
SELECT id, title, source, category, published_at, status
FROM news_items
WHERE status = 'new'
ORDER BY published_at DESC;

-- Mark as selected
UPDATE news_items SET status = 'selected', updated_at = NOW()
WHERE id IN (1, 2, 3);

-- Mark as rejected
UPDATE news_items SET status = 'rejected', updated_at = NOW()
WHERE id = 4;

-- Export selected articles
SELECT * FROM news_items WHERE status = 'selected';
```

#### Option B: JSON Export Workflow

```
1. Manual Trigger
   └─> Query PostgreSQL
         └─> Filter by status
               └─> Code Node (format JSON)
                     └─> Write File
                           └─> output/curated-YYYY-MM-DD.json
```

---

### Phase 8: Automation & Monitoring (Day 5)

#### Tasks:
- [ ] Set up n8n to auto-start on machine boot
- [ ] Create notification workflow for errors
- [ ] Create weekly digest workflow
- [ ] Add logging to track fetch statistics

#### Monitoring Dashboard (Optional):

```
Daily Stats:
- Articles fetched: X
- New articles: X
- Errors: X
- Top sources: X, Y, Z

Query:
SELECT 
  DATE(fetched_at) as date,
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'new' THEN 1 END) as new_count,
  source
FROM news_items
WHERE fetched_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(fetched_at), source
ORDER BY date DESC;
```

---

## Configuration

### Environment Variables (.env)

```env
# n8n Configuration
N8N_PORT=5678
N8N_BASIC_AUTH_USER=admin
N8N_PASSWORD=your_secure_password_here

# PostgreSQL Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_db_password_here
POSTGRES_DB=anime_news

# n8n Database (for workflow storage)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=anime_news
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=your_db_password_here

# Timezone
GENERIC_TIMEZONE=Asia/Tokyo
```

### Docker Compose

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: anime-news-n8n
    restart: unless-stopped
    ports:
      - "${N8N_PORT}:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
    volumes:
      - ./n8n/data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:15-alpine
    container_name: anime-news-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./database/init.sql:/docker-entrypoint-initdb.d/02-init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

---

## Workflow JSON Template

### Main Workflow Structure

```json
{
  "name": "Anime News Aggregator - Main",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{"field": "cronExpression", "expression": "0 * * * *"}]
        }
      },
      "name": "Schedule - Hourly",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT * FROM news_sources WHERE is_active = true ORDER BY id"
      },
      "name": "Get Active Sources",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "position": [450, 300]
    },
    {
      "parameters": {
        "mode": "each"
      },
      "name": "Loop Over Sources",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "position": [650, 300]
    },
    {
      "parameters": {
        "conditions": {
          "conditions": [
            {
              "value1": "={{$json.rss_url}}",
              "operation": "isNotEmpty"
            }
          ]
        }
      },
      "name": "Has RSS?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2,
      "position": [850, 300]
    },
    {
      "parameters": {
        "url": "={{$json.rss_url}}"
      },
      "name": "RSS Read",
      "type": "n8n-nodes-base.rssFeedRead",
      "typeVersion": 1,
      "position": [1050, 200]
    },
    {
      "parameters": {
        "url": "={{$json.base_url}}",
        "options": {}
      },
      "name": "HTTP - Listing Page",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1050, 400]
    },
    {
      "parameters": {
        "operation": "extractHtmlContent",
        "sourceData": "binary",
        "extractionValues": {
          "values": [
            {
              "key": "article_urls",
              "cssSelector": "a.article-link",
              "returnValue": "attribute",
              "attribute": "href"
            }
          ]
        }
      },
      "name": "HTML Extract - URLs",
      "type": "n8n-nodes-base.html",
      "typeVersion": 1,
      "position": [1250, 400]
    },
    {
      "parameters": {
        "mode": "each",
        "batchSize": 1,
        "options": {}
      },
      "name": "Loop Over Articles",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "position": [1450, 300]
    },
    {
      "parameters": {
        "amount": 3,
        "unit": "seconds"
      },
      "name": "Wait - Rate Limit",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "position": [1650, 300]
    },
    {
      "parameters": {
        "url": "={{$json.link || $json.url}}",
        "options": {}
      },
      "name": "HTTP - Article Page",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1850, 300]
    },
    {
      "parameters": {
        "operation": "extractHtmlContent",
        "sourceData": "binary",
        "extractionValues": {
          "values": [
            {"key": "content", "cssSelector": "article", "returnValue": "text"},
            {"key": "image", "cssSelector": "article img", "returnValue": "attribute", "attribute": "src"}
          ]
        }
      },
      "name": "HTML Extract - Content",
      "type": "n8n-nodes-base.html",
      "typeVersion": 1,
      "position": [2050, 300]
    },
    {
      "parameters": {
        "language": "javascript",
        "jsCode": "// Transform and clean data\nreturn items.map(item => ({\n  json: {\n    title: item.json.title,\n    url: item.json.link || item.json.url,\n    source: item.json.source || 'unknown',\n    category: item.json.category || 'general',\n    content: item.json.content,\n    content_snippet: (item.json.contentSnippet || item.json.content || '').substring(0, 300),\n    image_url: item.json.image,\n    author: item.json.creator || item.json.author,\n    published_at: item.json.pubDate || new Date().toISOString(),\n    status: 'new',\n    fetched_at: new Date().toISOString()\n  }\n}));"
      },
      "name": "Code - Transform",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [2250, 300]
    },
    {
      "parameters": {
        "mode": "combine",
        "combinationMode": "multiplex"
      },
      "name": "Merge All",
      "type": "n8n-nodes-base.merge",
      "typeVersion": 3,
      "position": [2450, 300]
    },
    {
      "parameters": {
        "operation": "removeKeyDuplicates",
        "keyToCheck": "url"
      },
      "name": "Remove Duplicates",
      "type": "n8n-nodes-base.removeDuplicates",
      "typeVersion": 1,
      "position": [2650, 300]
    },
    {
      "parameters": {
        "operation": "insert",
        "table": "news_items",
        "columns": {
          "mappingMode": "autoMapInputData"
        }
      },
      "name": "PostgreSQL - Insert",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "position": [2850, 300]
    }
  ],
  "connections": {
    "Schedule - Hourly": {
      "main": [[{"node": "Get Active Sources"}]]
    },
    "Get Active Sources": {
      "main": [[{"node": "Loop Over Sources"}]]
    },
    "Loop Over Sources": {
      "main": [[{"node": "Has RSS?"}]]
    },
    "Has RSS?": {
      "main": [
        [{"node": "RSS Read"}],
        [{"node": "HTTP - Listing Page"}]
      ]
    },
    "RSS Read": {
      "main": [[{"node": "Loop Over Articles"}]]
    },
    "HTTP - Listing Page": {
      "main": [[{"node": "HTML Extract - URLs"}]]
    },
    "HTML Extract - URLs": {
      "main": [[{"node": "Loop Over Articles"}]]
    },
    "Loop Over Articles": {
      "main": [[{"node": "Wait - Rate Limit"}]]
    },
    "Wait - Rate Limit": {
      "main": [[{"node": "HTTP - Article Page"}]]
    },
    "HTTP - Article Page": {
      "main": [[{"node": "HTML Extract - Content"}]]
    },
    "HTML Extract - Content": {
      "main": [[{"node": "Code - Transform"}]]
    },
    "Code - Transform": {
      "main": [[{"node": "Merge All"}]]
    },
    "Merge All": {
      "main": [[{"node": "Remove Duplicates"}]]
    },
    "Remove Duplicates": {
      "main": [[{"node": "PostgreSQL - Insert"}]]
    }
  }
}
```

---

## Maintenance

### Daily Tasks
- [ ] Check workflow execution logs
- [ ] Review new articles
- [ ] Mark articles as selected/rejected

### Weekly Tasks
- [ ] Review error logs
- [ ] Check source availability
- [ ] Update selectors if sites changed
- [ ] Backup PostgreSQL data

### Monthly Tasks
- [ ] Clean old rejected articles (optional)
- [ ] Update source list
- [ ] Review and optimize queries

---

## Troubleshooting

### Common Issues

#### n8n not starting
```powershell
# Check logs
docker-compose logs n8n

# Restart
docker-compose restart n8n
```

#### PostgreSQL connection failed
```powershell
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres
```

#### RSS feed returns empty
- Check if RSS URL is correct
- Verify site is accessible
- Check if RSS format changed

#### Web scraping fails
- Site may have changed structure
- Check selectors in news_sources table
- Site may be blocking requests
- Try increasing wait time between requests

#### Duplicates not removed
- Check URL normalization in Code node
- Verify Remove Duplicates node configuration

---

## Future Enhancements

### Phase 9+ (Optional)

1. **AI Integration**
   - Summarize long articles
   - Translate Japanese content
   - Auto-categorize articles

2. **Web UI**
   - Simple React/Vue dashboard
   - Article review interface
   - Statistics and analytics

3. **Notifications**
   - Telegram bot for new articles
   - Email digest
   - Discord webhook

4. **Content Creation Helpers**
   - Export to Notion
   - Generate content outlines
   - Track trending topics

5. **Advanced Scraping**
   - Puppeteer for JS-rendered content
   - Handle login-required sites
   - Screenshot capture

---

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [CSS Selectors Reference](https://www.w3schools.com/cssref/css_selectors.php)
- [RSS Specification](https://www.rssboard.org/rss-specification)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-09 | Initial implementation plan |

---

## Next Steps

1. Review this implementation plan
2. Set up environment (Docker, n8n, PostgreSQL)
3. Analyze target news sources (see docs/sources.md)
4. Build and test workflows
5. Start curating content
