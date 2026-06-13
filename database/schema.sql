-- Table definition for storing scraped news items
CREATE TABLE IF NOT EXISTS news_items (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    url TEXT UNIQUE NOT NULL,
    image_url TEXT, -- thumbnail/cover image
    content TEXT,
    source VARCHAR(100) DEFAULT 'Anime News Network',
    status VARCHAR(50) DEFAULT 'new',
    published_at TIMESTAMP, -- uploaded_at / published_at
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index on url for faster deduplication queries
CREATE INDEX IF NOT EXISTS idx_news_items_url ON news_items(url);
