# LLMEval Static Website & Docker Deployment Specifications

## Overview
Create a fully static website to display LLMEval results with Docker deployment infrastructure including automated daily evaluation runs.

## 1. Static Website Requirements

### 1.1 Root Index Page (`runs/index.html`)
**Purpose**: Display overview of all evaluation runs

**Layout**:
- Header with "LLMEval Results" title and Monadical branding
- Filter controls:
  - Model filter (dropdown/search)
  - Date range picker
  - Task filter (dropdown)
- Results table (last 50 runs maximum):
  - Date/Time column (sortable)
  - Task Name column (sortable)
  - Models Tested count
  - Tests Passed/Failed counts
  - Success Rate percentage
  - OK Models column (list of passed model names)
  - Failed Models column (list of failed model names)
  - Link to run detail page
- Footer with link back to monadical.com

**Data Source**: Aggregate from all `runs/run_*/*/result.json` files

### 1.2 Run Detail Page (`runs/run_YYYYMMDD_HHMMSS/index.html`)
**Purpose**: Show detailed results for a specific run

**Layout**:
- Header with run identifier and task name
- Summary statistics:
  - Total models tested
  - Success rate
  - Duration stats (min/max/avg)
- Models table (sorted by global score descending):
  - Rank
  - Model name
  - Global Score (% of tests passed)
  - Status (Pass/Fail)
  - Duration
  - Session Size (KB)
  - Per-test results with links
  - Link to session.txt
- Test results section:
  - Each test with pass/fail status
  - Link to test output file (test_test_*.txt)
- Footer with link back to index and monadical.com

**Data Source**: All `result.json` files in the run directory

**Caching**: Do NOT regenerate if `index.html` already exists

### 1.3 Design System (Monadical-inspired)

**Colors**:
- Primary: `#2563eb` (blue)
- Primary Dark: `#1e40af` (hover)
- Success: `#10b981` (green)
- Error: `#ef4444` (red)
- Warning: `#f59e0b` (orange)
- Background: `#ffffff` (white)
- Background Alt: `#f9fafb` (light gray)
- Border: `#e5e7eb`
- Text Primary: `#111827`
- Text Secondary: `#6b7280`
- Text Muted: `#9ca3af`

**Typography**:
- Font Family: `Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- H1: `2.5rem` (40px) / Bold / `1.2` line-height
- H2: `2rem` (32px) / Bold / `1.3` line-height
- H3: `1.5rem` (24px) / Semibold / `1.4` line-height
- Body: `1rem` (16px) / Regular / `1.6` line-height
- Small: `0.875rem` (14px)

**Spacing**:
- Container max-width: `1280px`
- Section padding: `4rem` vertical
- Card padding: `1.5rem`
- Grid gap: `2rem`

**Components**:
- Border radius cards: `0.5rem` (8px)
- Border radius buttons: `0.375rem` (6px)
- Box shadow: `0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)`
- Box shadow hover: `0 4px 6px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.06)`

**Footer**:
- Dark background: `#111827`
- White text
- "Powered by Monadical" with link to https://monadical.com
- Center aligned

### 1.4 Static Assets Structure
```
runs/
  static/
    style.css      # All CSS styling
    main.js        # Client-side filtering/sorting
  index.html       # Root index page
  run_*/
    index.html     # Run detail page (cached)
    */
      result.json  # Model results
      session.txt  # Session log
      test_*.txt   # Test outputs
      workspace/   # NOT accessible via web
```

## 2. Website Generator (`llmwebsite.py`)

**Purpose**: Generate static HTML files from evaluation results

**Functionality**:
1. Scan all `runs/run_*/` directories
2. Parse all `result.json` files
3. Extract task name from run directory structure
4. Generate root `runs/index.html`:
   - Aggregate data from all runs
   - Limit to 50 most recent runs
   - Include filter data (all models, dates, tasks)
5. Generate per-run `runs/run_*/index.html`:
   - Skip if file already exists (caching)
   - Calculate global score per model
   - Sort models by score descending
   - Generate links to all output files
6. Copy static assets:
   - Copy `static/style.css` to `runs/static/style.css`
   - Copy `static/main.js` to `runs/static/main.js`

**Command Line**:
```bash
python llmwebsite.py [--force]  # --force regenerates all run pages
```

**Dependencies**: Python stdlib only (json, pathlib, datetime, shutil)

## 3. llmeval.py Modifications

**Changes Required**:
1. Add `task_name` field to `result.json`:
   - Extract from task directory name (e.g., `tasks/task1_file_list` → `task1_file_list`)
   - Store in result.json for each model

**Example result.json update**:
```json
{
  "model": "litellm/openrouter/openai/gpt-4",
  "task_name": "task1_file_list",
  "status": "Complete",
  "result": "✅ Pass",
  ...
}
```

## 4. Nginx Configuration

**File**: `nginx.conf.example`

**Requirements**:
- Serve `runs/` directory as document root
- Block access to all `workspace/` subdirectories (403 Forbidden)
- Proper MIME types for .html, .css, .js, .txt, .json
- Enable directory listing: NO
- Default file: index.html
- Caching headers for static assets
- Port: 80 (configurable)

**Security**:
```nginx
location ~* /workspace/ {
    deny all;
    return 403;
}
```

## 5. Docker Infrastructure

### 5.1 Dockerfile

**Base Image**: `ubuntu:22.04` or `debian:bookworm`

**Installed Components**:
- Python 3.13+ with uv
- Podman (for cubbi to run containers)
- Cubbi CLI
- Cron
- Nginx
- Git (for potential updates)

**Setup Steps**:
1. Install system dependencies
2. Install uv and Python dependencies
3. Install podman and configure for rootless
4. Install cubbi
5. Copy application code to `/app/`
6. Setup cron configuration
7. Configure nginx to serve `/app/runs/`
8. Set proper permissions

**Working Directory**: `/app/`

### 5.2 docker-compose.yml

**Service Name**: `llmeval`

**Configuration**:
- Build from Dockerfile
- Privileged mode: `true` (required for podman-in-docker)
- Volumes:
  - `./runs:/app/runs` (persistent results)
  - `./config:/app/config:ro` (read-only configs)
  - Podman storage volume (for container images)
- Ports:
  - `8080:80` (nginx)
- Environment variables:
  - `LITELLM_API_KEY`
  - `OPENROUTER_API_KEY`
  - `TZ=America/Chicago` (CST timezone)
- Restart policy: `unless-stopped`

### 5.3 scripts/generate.sh

**Purpose**: Main script executed by cron to run evaluations

**Steps**:
1. Change to `/app/` directory
2. Build cubbi opencode image: `cubbi image build opencode`
   - This is cached, so subsequent runs are fast
3. Read models from `config/models.txt`
4. Read tasks from `config/tasks.txt`
5. For each task:
   - Run `uv run python llmeval.py --model <models> --task <task>`
6. Generate static website: `uv run python llmwebsite.py`
7. Log output to `/app/logs/generate_$(date).log`

**Error Handling**:
- Continue on individual task failures
- Log all errors
- Exit with non-zero code if critical failure

### 5.4 scripts/entrypoint.sh

**Purpose**: Container startup script

**Steps**:
1. Setup podman storage if needed
2. Install cron job:
   - `0 12 * * * /app/scripts/generate.sh >> /app/logs/cron.log 2>&1`
   - Timezone: CST (America/Chicago)
3. Start nginx
4. Start cron
5. Tail logs to keep container running

**Signal Handling**: Graceful shutdown for nginx and cron

### 5.5 Configuration Files

**config/models.txt**:
```
litellm/openrouter/anthropic/claude-sonnet-4
litellm/openrouter/openai/gpt-4
litellm/openrouter/deepseek/deepseek-r1-0528
```

**config/tasks.txt**:
```
tasks/task1_file_list
tasks/task2_fix_python_syntax
tasks/task4_web_fetch
```

**.env.example**:
```
LITELLM_API_KEY=your_key_here
OPENROUTER_API_KEY=your_key_here
TZ=America/Chicago
```

## 6. Testing Workflow

**Local Testing**:
```bash
# Build the image
docker-compose build

# Start the service
docker-compose up -d

# Run generate script manually
docker-compose exec llmeval bash /app/scripts/generate.sh

# Check the website
open http://localhost:8080

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**Validation Checklist**:
- [ ] Website accessible at http://localhost:8080
- [ ] Root index shows runs table
- [ ] Filters work (model, date, task)
- [ ] Clicking run shows detail page
- [ ] Model rankings displayed correctly
- [ ] Links to session.txt and test outputs work
- [ ] workspace/ directory returns 403
- [ ] Cron job scheduled correctly
- [ ] generate.sh completes successfully
- [ ] Static website regenerates after eval run

## 7. File Structure

```
evals/
  llmeval.py              # Modified to add task_name
  llmwebsite.py           # NEW: Static site generator
  specs.md                # NEW: This file
  static/                 # NEW: Static assets (source)
    style.css
    main.js
  scripts/                # NEW: Docker scripts
    generate.sh
    entrypoint.sh
  config/                 # NEW: Configuration
    models.txt
    tasks.txt
  Dockerfile              # NEW
  docker-compose.yml      # NEW
  nginx.conf.example      # NEW
  .env.example            # NEW
  runs/                   # Generated
    static/               # Copied from static/
    index.html            # Generated
    run_*/
      index.html          # Generated (cached)
      */
        result.json
        session.txt
        test_*.txt
        workspace/        # Not web accessible
```

## 8. Implementation Tasks

### Task 1: Website Static Assets
- Create `static/style.css` with Monadical-inspired design
- Create `static/main.js` with filtering/sorting logic

### Task 2: Website Generator
- Create `llmwebsite.py` with HTML generation logic
- Implement run page caching
- Implement static asset copying

### Task 3: llmeval.py Modifications
- Add task_name extraction and storage in result.json

### Task 4: Nginx Configuration
- Create `nginx.conf.example` with security rules

### Task 5: Docker Infrastructure
- Create `Dockerfile` with all dependencies
- Create `docker-compose.yml`
- Create `scripts/generate.sh`
- Create `scripts/entrypoint.sh`
- Create configuration files and examples

### Task 6: Testing & Validation
- Build and test Docker setup
- Validate website functionality
- Verify cron execution
- Test security (workspace blocking)

## 9. Success Criteria

1. ✅ Static website displays all runs correctly
2. ✅ Filtering and sorting work client-side
3. ✅ Run detail pages show model rankings and test results
4. ✅ All links to outputs work correctly
5. ✅ workspace/ directories are blocked by nginx
6. ✅ Docker container builds successfully
7. ✅ Cron job runs daily at 12:00 CST
8. ✅ generate.sh completes full workflow
9. ✅ Website updates after evaluation runs
10. ✅ Footer links back to monadical.com
11. ✅ Design matches Monadical aesthetic
12. ✅ Manual testing via docker-compose exec works
