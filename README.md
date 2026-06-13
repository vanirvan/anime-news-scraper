# Anime News Scraper

A local n8n-based news aggregation system for collecting and curating anime, manga, idol, and Japanese news from multiple sources.

---

## Overview

This project helps you:

- Monitor 20+ anime, manga, idol, and Japanese news sources
- Fetch full article content (not just RSS snippets)
- Store articles locally for manual curation
- Run automated hourly collection with rate-limiting protection

---

## Quick Start

### Prerequisites

- Docker Desktop (Windows)
- 4GB RAM minimum
- 10GB disk space

### Installation

```powershell
# Clone or navigate to project
cd anime-news-scrapper

# Create .env file
copy .env.example .env

# Edit .env and set your passwords
notepad .env

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### Access

| Service | URL |
|---------|-----|
| n8n | http://localhost:5678 |
| PostgreSQL | localhost:5432 |

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/implementation-plan.md](docs/implementation-plan.md) | Full implementation plan with phases |
| [docs/sources.md](docs/sources.md) | News sources list and selector documentation |
| [docs/workflow-guide.md](docs/workflow-guide.md) | How to create and use n8n workflows |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and solutions |

---

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   News Sources  │────▶│       n8n       │────▶│   PostgreSQL    │
│  RSS + Web      │     │   Workflows     │     │   Database      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌───────────────┐
                                                │  Manual       │
                                                │  Curation     │
                                                └───────────────┘
```

### RSS + Scrape Hybrid Approach

1. **RSS feeds** → Get list of new articles (title, URL, snippet)
2. **HTTP Request** → Fetch each article's full page
3. **HTML Extract** → Parse full content, images, author
4. **PostgreSQL** → Store complete article data

---

## Project Structure

```
anime-news-scrapper/
├── docker-compose.yml          # Docker services configuration
├── .env                        # Environment variables
├── .env.example                # Template for .env
├── README.md                   # This file
│
├── docs/                       # Documentation
│   ├── implementation-plan.md
│   ├── sources.md
│   ├── workflow-guide.md
│   └── troubleshooting.md
│
├── database/                   # Database setup
│   ├── schema.sql
│   └── init.sql
│
├── n8n/                        # n8n configuration
│   ├── workflows/
│   └── credentials/
│
├── scripts/                    # Helper scripts
│   ├── start.ps1
│   ├── stop.ps1
│   └── export-news.ps1
│
└── output/                     # Exported articles
```

---

## Basic Usage

### Starting Services

```powershell
docker-compose up -d
```

### Stopping Services

```powershell
docker-compose down
```

### Viewing Logs

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f postgres
```

### Checking Database

```powershell
# Connect to PostgreSQL
docker exec -it anime-news-db psql -U postgres -d anime_news

# Query new articles
SELECT id, title, source, published_at 
FROM news_items 
WHERE status = 'new' 
ORDER BY published_at DESC 
LIMIT 20;
```

---

## Workflows

### Main Workflow

The primary workflow runs every hour and:

1. Fetches articles from all configured sources
2. Scrapes full content for each article
3. Deduplicates by URL
4. Stores in PostgreSQL

### Creating Workflows

See [docs/workflow-guide.md](docs/workflow-guide.md) for detailed instructions.

### Importing Workflows

1. Open n8n at http://localhost:5678
2. Click menu (three dots) → Import from File
3. Select workflow JSON from `n8n/workflows/`

---

## News Sources

### Supported Categories

- **Anime & Manga**: ANN, Crunchyroll, MAL, VIZ, etc.
- **Japanese News**: NHK World, Japan Today, Natalie
- **Idol & J-Pop**: Oricon, Natalie Music, Model Press
- **Seiyuu**: Seiyuu Grand Prix, Voice Newtype

### Adding New Sources

1. Analyze the website (see [docs/sources.md](docs/sources.md))
2. Document RSS URL and HTML selectors
3. Add to n8n workflow
4. Test and verify

---

## Curation Workflow

### Option A: SQL Queries

```sql
-- View new articles
SELECT * FROM news_items WHERE status = 'new' ORDER BY published_at DESC;

-- Mark as selected
UPDATE news_items SET status = 'selected' WHERE id IN (1, 2, 3);

-- Mark as rejected
UPDATE news_items SET status = 'rejected' WHERE id = 4;

-- Export selected
SELECT title, url, source, content FROM news_items WHERE status = 'selected';
```

### Option B: JSON Export

Run the export workflow to generate JSON files in `output/` directory.

---

## Common Tasks

### Check System Status

```powershell
docker-compose ps
```

### Restart n8n

```powershell
docker-compose restart n8n
```

### Backup Database

```powershell
docker exec anime-news-db pg_dump -U postgres anime_news > backup.sql
```

### Clear Old Articles

```sql
DELETE FROM news_items WHERE status = 'rejected' AND created_at < NOW() - INTERVAL '30 days';
```

---

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed solutions.

### Quick Fixes

| Issue | Solution |
|-------|----------|
| Can't access n8n | Check if container is running: `docker-compose ps` |
| Database error | Restart: `docker-compose restart postgres` |
| RSS feed fails | Check if URL is accessible in browser |
| 403 Forbidden | Add User-Agent header, increase delay |
| Duplicate articles | Check URL normalization in code |

---

## Configuration

### Environment Variables (.env)

```env
# n8n
N8N_PORT=5678
N8N_BASIC_AUTH_USER=admin
N8N_PASSWORD=your_password

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DB=anime_news

# Timezone
GENERIC_TIMEZONE=Asia/Tokyo
```

### Rate Limiting

Default configuration:
- 2-3 seconds between article requests
- 5 seconds between sources
- Max retries: 3

Adjust in n8n workflow → Wait nodes.

---

## Next Steps

1. Read [docs/implementation-plan.md](docs/implementation-plan.md) for full setup guide
2. Analyze your target sources using [docs/sources.md](docs/sources.md)
3. Configure n8n workflows
4. Start collecting and curating news

---

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## License

MIT License - Feel free to use and modify for your own projects.
