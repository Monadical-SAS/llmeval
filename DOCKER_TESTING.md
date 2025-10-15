# Docker Deployment Testing Guide

## Prerequisites

1. Docker and Docker Compose installed
2. API keys for LLM providers (LiteLLM, OpenRouter)
3. Cubbi configured with providers

## Setup

1. Create environment file:
```bash
cp .env.example .env
# Edit .env and add your API keys
```

2. Update configuration files:
```bash
# Edit config/models.txt to add models you want to test
# Edit config/tasks.txt to add task paths
```

## Testing Workflow

### Step 1: Build the Docker Image

```bash
docker-compose build
```

This will:
- Install Ubuntu 22.04
- Install Python 3.13, uv, podman, cubbi, cron, nginx
- Copy application code
- Configure nginx
- Should take 5-10 minutes on first build

### Step 2: Start the Container

```bash
docker-compose up -d
```

This will:
- Start the container in background
- Mount volumes (./runs, ./config, ./logs)
- Expose port 8080 for the website
- Setup cron for daily runs

### Step 3: Verify Container is Running

```bash
docker-compose ps
docker-compose logs
```

You should see:
- Container status: Up
- Nginx started successfully
- Cron daemon started
- No errors in logs

### Step 4: Run Manual Evaluation

```bash
docker-compose exec llmeval bash /app/scripts/generate.sh
```

This will:
1. Build cubbi opencode image (takes a few minutes first time, then cached)
2. Run llmeval.py for each task in config/tasks.txt
3. Generate static website with llmwebsite.py
4. Log everything to `logs/generate_YYYYMMDD_HHMMSS.log`

Watch the progress:
```bash
# In another terminal
docker-compose logs -f
```

### Step 5: View the Website

Open your browser to:
```
http://localhost:8080
```

You should see:
- Root index page with list of runs
- Ability to filter by model/date/task
- Click on a run to see detailed results
- Model rankings with test results
- Links to session.txt and test output files

### Step 6: Test Security

Try to access workspace directory (should fail):
```
http://localhost:8080/run_YYYYMMDD_HHMMSS/model-name/workspace/
```

Should return: **403 Forbidden**

### Step 7: Test Automated Cron Run

Check cron is configured:
```bash
docker-compose exec llmeval crontab -l
```

Should show:
```
0 12 * * * /app/scripts/generate.sh >> /app/logs/cron.log 2>&1
```

To test immediately without waiting for scheduled time:
```bash
docker-compose exec llmeval bash -c "/app/scripts/generate.sh >> /app/logs/cron.log 2>&1"
```

### Step 8: Check Logs

```bash
# View all logs
docker-compose logs

# View specific log file
docker-compose exec llmeval cat /app/logs/generate_*.log

# View cron log
docker-compose exec llmeval cat /app/logs/cron.log

# Follow logs in real-time
docker-compose logs -f
```

## Common Issues

### Issue: Docker build fails with "permission denied"

**Solution**: Make sure you're running with appropriate permissions:
```bash
sudo docker-compose build
```

### Issue: Container exits immediately

**Solution**: Check logs for errors:
```bash
docker-compose logs
```

Common causes:
- Missing .env file
- Invalid nginx configuration
- Script permissions not set

### Issue: Website shows 404

**Solution**:
1. Check nginx is running: `docker-compose exec llmeval nginx -t`
2. Check runs directory has content: `ls -la runs/`
3. Generate website manually: `docker-compose exec llmeval python /app/llmwebsite.py`

### Issue: Evaluation fails with "cubbi not found"

**Solution**:
1. Check cubbi is installed: `docker-compose exec llmeval which cubbi`
2. Rebuild if needed: `docker-compose build --no-cache`

### Issue: Workspace directories accessible via web

**Solution**:
1. Check nginx config: `docker-compose exec llmeval nginx -t`
2. Reload nginx: `docker-compose exec llmeval nginx -s reload`
3. Test with curl: `curl http://localhost:8080/run_*/*/workspace/` (should return 403)

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Production Deployment

For production use:

1. Update `.env` with production API keys
2. Configure proper domain in `nginx.conf.example`
3. Setup SSL/TLS certificates
4. Use a reverse proxy (e.g., Caddy, Traefik)
5. Monitor logs regularly
6. Backup `runs/` directory periodically

## Success Criteria

✅ Docker image builds without errors
✅ Container starts and stays running
✅ Nginx serves website on port 8080
✅ Can run manual evaluation via generate.sh
✅ Website displays runs correctly
✅ Filtering and sorting work
✅ Workspace directories return 403
✅ Cron job is configured
✅ Logs are generated
✅ Can access session.txt and test output files

If all criteria are met, your deployment is successful!
