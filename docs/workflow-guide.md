# Workflow Guide

This guide explains how to create, configure, and use n8n workflows for the anime news scraper.

---

## Table of Contents

1. [Getting Started with n8n](#getting-started-with-n8n)
2. [Creating Your First Workflow](#creating-your-first-workflow)
3. [Node Reference](#node-reference)
4. [Workflow Patterns](#workflow-patterns)
5. [Testing & Debugging](#testing--debugging)
6. [Best Practices](#best-practices)

---

## Getting Started with n8n

### Accessing n8n

After starting the Docker containers:

```powershell
docker-compose up -d
```

Access n8n at: **http://localhost:5678**

### Initial Setup

1. **First Launch**
   - Create admin account
   - Set your timezone (recommended: Asia/Tokyo)
   - Skip the welcome wizard

2. **Add Credentials**
   - Go to **Credentials** menu
   - Add **PostgreSQL** credential
   - Test connection

### n8n Interface Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Header: Workflow name, Save, Execute, Activate toggle      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐                    Canvas Area                │
│   │ Sidebar │                                                 │
│   │         │     ┌──────┐      ┌──────┐      ┌──────┐     │
│   │ Nodes   │     │ Node │ ──── │ Node │ ──── │ Node │     │
│   │ Search  │     └──────┘      └──────┘      └──────┘     │
│   │         │                                                 │
│   │ Trigger │                                                 │
│   │ Actions │                                                 │
│   │ Logic   │                                                 │
│   │         │                                                 │
│   └─────────┘                                                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Bottom: Execution history, zoom controls                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Creating Your First Workflow

### Step 1: Create New Workflow

1. Click **+** button (top right) or **Add Workflow**
2. Rename workflow: Click "My workflow" and type new name
3. Save: `Ctrl + S`

### Step 2: Add Trigger Node

1. Click **+** on canvas
2. Search for "Schedule Trigger"
3. Configure:
   - Trigger interval: Hours
   - Hours between triggers: 1

### Step 3: Add Action Nodes

For each action:
1. Click **+** on previous node's output
2. Search for node type
3. Configure parameters
4. Connect to next node

### Step 4: Test Workflow

1. Click **Execute Workflow** button
2. Watch execution in real-time
3. Check output of each node
4. Fix any errors

### Step 5: Activate Workflow

1. Toggle **Inactive** to **Active** (top right)
2. Workflow will now run automatically

---

## Node Reference

### Trigger Nodes

#### Schedule Trigger

Runs workflow at specified intervals.

```
Configuration:
├── Rule Type: Interval
│   ├── Interval: Hours
│   └── Hours: 1
│
└── OR Rule Type: Cron
    └── Expression: "0 * * * *" (every hour)
```

**Example Cron Expressions:**
| Expression | Meaning |
|------------|---------|
| `0 * * * *` | Every hour at minute 0 |
| `0 */2 * * *` | Every 2 hours |
| `0 9 * * *` | Daily at 9:00 AM |
| `0 9,18 * * *` | Twice daily at 9 AM and 6 PM |

#### RSS Feed Trigger

Monitors RSS feed for new items.

```
Configuration:
└── RSS Feed URL: https://example.com/feed.xml
```

---

### Action Nodes

#### RSS Read

Fetches RSS feed once (not continuous monitoring).

```
Configuration:
└── URL: https://www.animenewsnetwork.com/news/rss.xml
```

**Output Structure:**
```json
{
  "title": "Article Title",
  "link": "https://...",
  "pubDate": "2026-06-09T10:00:00.000Z",
  "content": "<p>Full HTML content...</p>",
  "contentSnippet": "Plain text snippet...",
  "creator": "Author Name",
  "categories": ["anime", "manga"]
}
```

#### HTTP Request

Fetches web pages or API endpoints.

```
Configuration:
├── Method: GET
├── URL: https://example.com/article
└── Options:
    ├── Timeout: 10000 ms
    └── Response Format: String (for HTML)
```

**For JSON APIs:**
```
├── Response Format: JSON
```

**For paginated APIs:**
```
├── Pagination:
│   ├── Pagination Mode: Update a Parameter in Each Request
│   ├── Type: Page Number
│   └── Next Page Parameter: page
```

#### HTML Extract

Parses HTML content using CSS selectors.

```
Configuration:
├── Operation: Extract HTML Content
├── Source Data: Binary (from HTTP Request)
│
└── Extraction Values:
    ├── Key: title
    │   ├── CSS Selector: h1.article-title
    │   └── Return Value: Text
    │
    ├── Key: content
    │   ├── CSS Selector: div.article-body
    │   └── Return Value: Text
    │
    ├── Key: image
    │   ├── CSS Selector: img.featured
    │   ├── Return Value: Attribute
    │   └── Attribute: src
    │
    └── Key: author
        ├── CSS Selector: span.author
        └── Return Value: Text
```

**Return Value Options:**
| Option | Description |
|--------|-------------|
| Text | Get inner text |
| HTML | Get inner HTML |
| Attribute | Get specific attribute (e.g., src, href) |

#### PostgreSQL

Database operations.

```
Insert Configuration:
├── Operation: Insert
├── Table: news_items
└── Columns:
    └── Mapping Mode: Auto-map Input Data
```

```
Query Configuration:
├── Operation: Execute Query
└── Query: SELECT * FROM news_items WHERE status = 'new'
```

```
Update Configuration:
├── Operation: Update
├── Table: news_items
├── Columns: status, updated_at
└── Filter Key: id
```

---

### Logic Nodes

#### If

Conditional branching.

```
Configuration:
├── Condition: Boolean
│   ├── Value 1: {{ $json.status }}
│   ├── Operation: Equals
│   └── Value 2: new
│
└── OR Condition: String
    ├── Value 1: {{ $json.title }}
    ├── Operation: Contains
    └── Value 2: anime
```

**Multiple Conditions:**
```
├── Combine: OR / AND
└── Conditions:
    ├── Condition 1: title contains "anime"
    ├── Condition 2: title contains "manga"
    └── Condition 3: title contains "idol"
```

#### Switch

Multiple conditional branches.

```
Configuration:
├── Mode: Rules
└── Output:
    ├── Output 1: category == 'anime'
    ├── Output 2: category == 'manga'
    ├── Output 3: category == 'idol'
    └── Default: Fallback
```

#### Merge

Combine data from multiple inputs.

```
Configuration:
├── Mode: Append
│   └── Simply combine all inputs
│
├── Mode: Merge by Key
│   └── Merge items with matching key
│
└── Mode: Keep Key Matches
    └── Only keep matching items
```

#### Loop Over Items (Split in Batches)

Process items one at a time.

```
Configuration:
├── Batch Size: 1
└── Options:
    └── Reset: False (continue from last batch)
```

#### Wait

Pause execution.

```
Configuration:
├── Unit: Seconds
└── Amount: 3
```

---

### Transform Nodes

#### Code

Custom JavaScript or Python transformations.

```
Configuration:
├── Language: JavaScript
└── Code:
```

```javascript
// Transform items
return items.map(item => ({
  json: {
    title: item.json.title?.trim(),
    url: item.json.link || item.json.url,
    content: item.json.contentSnippet || item.json.content,
    published_at: new Date(item.json.pubDate).toISOString(),
    status: 'new'
  }
}));
```

**Useful Code Patterns:**

```javascript
// Filter items
return items.filter(item => {
  const title = item.json.title?.toLowerCase() || '';
  return title.includes('anime') || title.includes('manga');
});

// Extract date from string
const date = new Date(item.json.pubDate);
const formatted = date.toISOString().split('T')[0];

// Clean HTML tags
const cleanText = item.json.content
  .replace(/<[^>]*>/g, '')
  .replace(/\s+/g, ' ')
  .trim();

// Extract first image URL
const imgMatch = item.json.content?.match(/<img[^>]+src="([^">]+)"/);
const imageUrl = imgMatch ? imgMatch[1] : null;
```

#### Filter

Filter items by conditions.

```
Configuration:
├── Conditions:
│   ├── Value 1: {{ $json.status }}
│   ├── Operation: Equals
│   └── Value 2: new
└── Keep: Keep matching items
```

#### Remove Duplicates

Remove duplicate items.

```
Configuration:
├── Compare: Selected Fields
├── Fields to Compare: url
└── Options:
    └── Remove: Remove duplicates
```

#### Set (Edit Fields)

Modify or add fields.

```
Configuration:
├── Mode: Manual Mapping
└── Fields:
    ├── Name: status
    │   └── Value: new
    │
    ├── Name: fetched_at
    │   └── Value: {{ $now.toISO() }}
    │
    └── Name: source
        └── Value: Anime News Network
```

---

## Workflow Patterns

### Pattern 1: RSS + Scrape Hybrid

```
[Schedule Trigger]
        │
        ▼
[RSS Read] ────> Gets list of articles with URLs
        │
        ▼
[Loop Over Items]
        │
        ▼
[Wait: 2 sec] ────> Rate limiting
        │
        ▼
[HTTP Request] ────> Fetch article page
        │
        ▼
[HTML Extract] ────> Parse content
        │
        ▼
[Code] ────> Combine RSS + scraped data
        │
        ▼
[PostgreSQL Insert]
```

### Pattern 2: Multi-Source Parallel

```
[Schedule Trigger]
        │
        ├─── [Source A: RSS + Scrape]
        │           │
        │           ▼
        │      [Transform A]
        │           │
        │           │
        ├─── [Source B: RSS]
        │           │
        │           ▼
        │      [Transform B]
        │           │
        │           │
        └─── [Source C: Scrape Only]
                    │
                    ▼
               [Transform C]
                    │
                    │
                    ▼
        [Merge All Sources]
                    │
                    ▼
        [Remove Duplicates]
                    │
                    ▼
        [PostgreSQL Insert]
```

### Pattern 3: Error Handling

```
[HTTP Request]
        │
        ├─── Success ────> [HTML Extract]
        │                         │
        │                         ▼
        │                   [Continue...]
        │
        └─── Error ────> [Error Trigger]
                                │
                                ▼
                          [Log Error]
                                │
                                ▼
                          [Send Notification]
```

### Pattern 4: Rate Limiting Loop

```
[Get List of Articles]
        │
        ▼
[Loop Over Items: Batch Size 1]
        │
        ▼
[Wait: 3 seconds] ────> Delay between requests
        │
        ▼
[HTTP Request]
        │
        ▼
[Process Article]
        │
        ▼
[Continue Loop] ────> Returns to start of loop
```

---

## Testing & Debugging

### Manual Testing

1. **Execute Workflow**
   - Click **Execute Workflow** button
   - All nodes execute sequentially

2. **Execute Node**
   - Click specific node
   - Click **Execute Node** button
   - Only that node executes

3. **Partial Execution**
   - Click on a node
   - Execute from that node
   - Uses previous execution data

### Viewing Output

1. Click on any executed node
2. Switch between tabs:
   - **Input**: Data received
   - **Output**: Data produced
   - **JSON**: Raw JSON view

### Debugging Tips

**Add Debug Nodes:**
```
[Any Node] ────> [Set Node: Log data]
                        │
                        ▼
                  Check output
```

**Use Stop Node:**
```
[Node 1]
    │
    ▼
[Node 2]
    │
    ▼
[Stop] ────> Workflow stops here for testing
```

**Check Variables:**
```javascript
// In Code node, log to see data
console.log('Item data:', JSON.stringify(items[0].json));
return items;
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot read property 'x' of undefined` | Missing field | Check if field exists before accessing |
| `HTTP 403 Forbidden` | Blocked by site | Add delay, change user agent |
| `HTTP 429 Too Many Requests` | Rate limited | Increase wait time between requests |
| `Connection refused` | Service not running | Check Docker containers |
| `Query failed` | SQL error | Check table/column names |

---

## Best Practices

### 1. Naming Conventions

```
Nodes: Use descriptive names
├── Good: "RSS - Anime News Network"
├── Good: "HTTP - Fetch Article Page"
├── Bad: "HTTP Request 1"
└── Bad: "Node 5"
```

### 2. Add Comments

Use **Sticky Note** nodes to document:
- What the workflow does
- Important configuration notes
- Date of last update

### 3. Error Handling

Always handle potential failures:
```
[HTTP Request]
    │
    ├── Success ──> Continue
    │
    └── Error ────> Log and Continue
```

### 4. Rate Limiting

Add delays between requests:
```
[Loop]
    │
    ▼
[Wait: 2-3 seconds] ────> Prevent rate limiting
    │
    ▼
[HTTP Request]
```

### 5. Data Validation

Validate data before inserting:
```javascript
// In Code node
if (!item.json.title || !item.json.url) {
  throw new Error('Missing required fields');
}
```

### 6. Use Expressions

Reference previous node data:
```javascript
// Get field from previous node
{{ $json.title }}

// Get field from specific node
{{ $node["RSS Read"].json["title"] }}

// Get first item's field
{{ $json[0].title }}

// Current timestamp
{{ $now.toISO() }}

// Format date
{{ $json.pubDate.toFormat('yyyy-MM-dd') }}
```

### 7. Backup Workflows

Export workflows regularly:
1. Open workflow
2. Click **...** menu
3. Select **Download**
4. Save as JSON file

### 8. Version Control

Store workflow JSON files in:
```
n8n/workflows/
├── main-workflow.json
├── source-ann.json
└── source-crunchyroll.json
```

---

## Expressions Reference

### Common Expressions

```javascript
// Current date/time
{{ $now.toISO() }}                           // 2026-06-09T12:38:34.000Z
{{ $now.toFormat('yyyy-MM-dd') }}            // 2026-06-09
{{ $now.plus({days: 1}).toISO() }}           // Tomorrow

// String manipulation
{{ $json.title.toUpperCase() }}              // UPPERCASE
{{ $json.title.toLowerCase() }}              // lowercase
{{ $json.title.substring(0, 50) }}           // First 50 chars
{{ $json.title.trim() }}                     // Remove whitespace

// Array operations
{{ $json.items.length }}                     // Array length
{{ $json.items[0] }}                         // First item
{{ $json.items.join(', ') }}                 // Join with comma

// Object operations
{{ Object.keys($json) }}                     // Get all keys
{{ Object.values($json) }}                   // Get all values
{{ $json.hasOwnProperty('title') }}          // Check if key exists

// Conditional
{{ $json.status === 'new' ? 'New article' : 'Old article' }}

// Math
{{ $json.price * 1.1 }}                      // Add 10%
{{ Math.round($json.rating) }}               // Round number
{{ Math.floor($json.rating) }}               // Floor number

// Regex
{{ $json.content.match(/<img.*?src="(.*?)"/)?.[1] }}  // Extract image URL
```

---

## Quick Reference: Node Shortcuts

| Action | Shortcut |
|--------|----------|
| Add node | Click **+** or drag from sidebar |
| Delete node | Select + `Delete` key |
| Copy node | `Ctrl + C` |
| Paste node | `Ctrl + V` |
| Duplicate node | `Ctrl + D` |
| Save workflow | `Ctrl + S` |
| Execute workflow | `Ctrl + Enter` |
| Undo | `Ctrl + Z` |
| Redo | `Ctrl + Y` |
| Zoom in | `Ctrl + +` |
| Zoom out | `Ctrl + -` |
| Fit to screen | `Ctrl + 0` |
| Search nodes | `Ctrl + F` |

---

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Expression Reference](https://docs.n8n.io/code-examples/expressions/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n Workflow Templates](https://n8n.io/workflows/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-09 | Initial workflow guide |
