#!/usr/bin/env python3
"""
LLMEval Static Website Generator

Generates static HTML pages from evaluation results with 3-level hierarchy:

1. Root index (runs/index.html):
   - One row per run with three columns: Date/Time, Overall Score, Models Score
   - Models Score column lists all models with their score (tasks_passed/total_tasks)
   - Color-coded by model pass rate (green/orange/red)

2. Run overview (runs/run_*/index.html):
   - For multi-task runs only
   - Model × task grid showing ✅/❌ status
   - Overall score per model

3. Task detail (runs/run_*/task_*/index.html or runs/run_*/index.html):
   - Test-level results for one task
   - Model rankings with individual test columns

Supports both structures:
- Old: run_*/model/result.json (single task per run)
- New: run_*/task_*/model/result.json (multi-task runs)

Usage:
    python llmwebsite.py [--force]

Options:
    --force    Regenerate all pages (bypasses caching)
"""

import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path


def normalize_model_name(model_name):
    """Normalize model name for directory structure."""
    return model_name.replace("/", "-")


def calculate_task_pass_rate(task_models):
    """
    Calculate the pass rate for a task.

    Args:
        task_models: List of model dicts for a task

    Returns:
        float: Pass rate (0.0 to 1.0)
    """
    if not task_models:
        return 0.0

    passed_count = sum(1 for m in task_models if m.get("passed", False))
    return passed_count / len(task_models)


def get_task_cell_class(pass_rate):
    """
    Get CSS class based on pass rate.

    Args:
        pass_rate: Float from 0.0 to 1.0

    Returns:
        str: CSS class name
    """
    if pass_rate >= 1.0:
        return "task-cell-green"
    elif pass_rate >= 0.5:
        return "task-cell-orange"
    else:
        return "task-cell-red"


def generate_model_completion_bar(task_models):
    """
    Generate HTML for model completion bar with tags.

    Args:
        task_models: List of model dicts for a task

    Returns:
        str: HTML string with model tags
    """
    html = '<div class="model-list">'

    # Sort models: passed first, then failed
    sorted_models = sorted(
        task_models, key=lambda m: (not m.get("passed", False), m.get("model", ""))
    )

    # Limit display to first 5 models
    for model in sorted_models[:5]:
        display_name, full_name = strip_model_prefix(model.get("model", "Unknown"))
        status_class = "success" if model.get("passed", False) else "error"
        status_icon = "✓" if model.get("passed", False) else "✗"

        html += f'<span class="model-tag {status_class}" title="{escape_html(full_name)}">{escape_html(display_name)} {status_icon}</span>'

    if len(sorted_models) > 5:
        html += f'<span class="model-tag">+{len(sorted_models) - 5} more</span>'

    html += "</div>"
    return html


def extract_task_name(run_dir, models):
    """
    Extract task name from run directory structure.
    Tries to get task_name from result.json files first.
    """
    # Try to get from result.json files (preferred)
    if models:
        for model in models:
            task_name = model.get("task_name")
            if task_name:
                return task_name

    # Fallback: use run directory name
    return run_dir.name.replace("run_", "")


def load_run_data(run_dir):
    """
    Load all result.json files from a run directory.

    Supports both structures:
    - Old: run_*/model/result.json (single task)
    - New: run_*/task_*/model/result.json (multi-task)

    Returns:
        dict: {
            'run_id': str,
            'timestamp': datetime,
            'tasks': {
                'task_name': {
                    'models': [model_data, ...]
                },
                ...
            }
        }
    """
    run_id = run_dir.name

    # Extract timestamp from run directory name (run_YYYYMMDD_HHMMSS)
    timestamp_str = run_id.replace("run_", "")
    try:
        timestamp = datetime.strptime(timestamp_str, "%Y%m%d_%H%M%S")
    except ValueError:
        timestamp = datetime.fromtimestamp(run_dir.stat().st_mtime)

    # Check for new structure (task subdirectories)
    # Note: Task directories can start with 'task' or 'test' (e.g., test_multiple_tests)
    task_dirs = [
        d
        for d in run_dir.iterdir()
        if d.is_dir() and (d.name.startswith("task") or d.name.startswith("test"))
    ]

    tasks = {}

    if task_dirs:
        # New multi-task structure: run_*/task_*/model/result.json
        for task_dir in task_dirs:
            task_name = task_dir.name
            models = []

            result_files = list(task_dir.glob("*/result.json"))
            for result_file in result_files:
                model_data = _load_model_result(result_file, task_dir.name)
                if model_data:
                    models.append(model_data)

            if models:
                tasks[task_name] = {"models": models}
    else:
        # Old single-task structure: run_*/model/result.json
        models = []
        result_files = list(run_dir.glob("*/result.json"))

        for result_file in result_files:
            model_data = _load_model_result(result_file, None)
            if model_data:
                models.append(model_data)

        # Extract task name from result.json or infer from directory structure
        task_name = extract_task_name(run_dir, models)
        if models:
            tasks[task_name] = {"models": models}

    return {"run_id": run_id, "timestamp": timestamp, "tasks": tasks}


def _load_model_result(result_file, task_dir_name=None):
    """
    Load a single model result from result.json.

    Args:
        result_file: Path to result.json
        task_dir_name: Name of task directory (for new structure), or None

    Returns:
        dict: Model data with computed fields, or None if load failed
    """
    try:
        with open(result_file, "r") as f:
            data = json.load(f)

        # Calculate global score (percentage of tests passed)
        test_results = data.get("test_results", [])
        if test_results:
            passed_tests = sum(1 for t in test_results if t.get("passed", False))
            total_tests = len(test_results)
            global_score = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
        else:
            # No tests, consider as 100% if result is Pass
            global_score = 100 if data.get("result") == "✅ Pass" else 0

        # Add computed fields
        data["global_score"] = global_score
        data["model_dir"] = result_file.parent.name
        data["passed"] = data.get("result") == "✅ Pass"

        # Store task_dir_name if present (for new structure)
        if task_dir_name:
            data["task_dir"] = task_dir_name

        return data
    except (json.JSONDecodeError, FileNotFoundError) as e:
        print(f"Warning: Could not load {result_file}: {e}")
        return None


def generate_task_detail_page(
    run_dir, task_name, task_data, static_source, run_timestamp=None, force=False
):
    """
    Generate the task detail page (test-level view) for a specific task.

    Note: Links will preserve URL filter parameters via JavaScript on click.

    Args:
        run_dir: Path to run directory
        task_name: Name of the task
        task_data: Task data dict with 'models' key
        static_source: Path to static source directory (for cache busting)
        run_timestamp: Optional datetime of the run (for display)
        force: If True, regenerate even if index.html exists

    Returns:
        bool: True if generated, False if skipped (cached)
    """
    # Determine output path based on structure
    task_dir = run_dir / task_name
    if task_dir.exists() and task_dir.is_dir():
        # New structure: write to run_*/task_*/index.html
        index_path = task_dir / "index.html"
        path_prefix = ".."
    else:
        # Old structure: write to run_*/index.html (backward compatibility)
        index_path = run_dir / "index.html"
        path_prefix = "."

    # Skip if already exists (caching) unless force is True
    if index_path.exists() and not force:
        return False

    models = task_data["models"]

    # Load task prompt from workspace
    task_prompt = ""
    if models:
        # Get the first model's workspace to find task.md
        first_model = models[0]
        if path_prefix == "..":
            task_md_path = task_dir / first_model["model_dir"] / "workspace" / "task.md"
        else:
            task_md_path = run_dir / first_model["model_dir"] / "workspace" / "task.md"

        if task_md_path.exists():
            try:
                with open(task_md_path, "r") as f:
                    task_prompt = f.read().strip()
            except Exception as e:
                print(f"  Warning: Could not read task.md: {e}")

    # Sort models by global score descending
    models_sorted = sorted(models, key=lambda m: m["global_score"], reverse=True)

    # Calculate statistics
    total_models = len(models_sorted)
    passed_models = sum(1 for m in models_sorted if m["passed"])
    success_rate = (passed_models / total_models * 100) if total_models > 0 else 0

    durations = [m.get("duration_seconds", 0) for m in models_sorted]
    min_duration = min(durations) if durations else 0
    max_duration = max(durations) if durations else 0
    avg_duration = sum(durations) / len(durations) if durations else 0

    # Format task prompt for HTML
    task_prompt_html = escape_html(task_prompt).replace("\n", "<br>")

    # Generate HTML
    run_id = run_dir.name

    # Create user-friendly breadcrumb with datetime
    if run_timestamp:
        run_display = f"Run of {run_timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
    else:
        run_display = run_id

    breadcrumb = f"{run_display} / {task_name}" if path_prefix == ".." else run_display
    parent_link = (
        f"{path_prefix}/index.html" if path_prefix == ".." else "../index.html"
    )
    static_path = f"{path_prefix}/../static" if path_prefix == ".." else "../static"

    # Get cache-busting versions
    css_version = get_static_file_version(static_source, "style.css")
    js_version = get_static_file_version(static_source, "main.js")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="LLM Evaluation - {breadcrumb}">
    <title>{breadcrumb} - LLM Evaluation</title>
    <link rel="stylesheet" href="{static_path}/style.css?v={css_version}">
</head>
<body class="run-page">
    <header>
        <div class="container">
            <div class="header-title">
                <a href="{"../../index.html" if path_prefix == ".." else "../index.html"}" class="logo-link"><h1>LLM Evaluation</h1></a>
                <a href="{parent_link}" class="breadcrumb-link"><h2 class="breadcrumb">← Back to {run_display}</h2></a>
            </div>
            <div class="header-meta">
                <a href="https://monadical.com" target="_blank" rel="noopener" class="monadical-logo">
                    <img src="{static_path}/monadical-logo.png" alt="Monadical">
                </a>
            </div>
        </div>
    </header>

    <main>
        <div class="container">
            <h2 class="section-title">Task <code>{escape_html(task_name)}</code></h2>
            <div class="task-prompt">
                <div class="task-prompt-content">{task_prompt_html}</div>
            </div>

            <h2 class="section-title">Results</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">{total_models}</div>
                    <div class="stat-label">Models Tested</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{success_rate:.1f}%</div>
                    <div class="stat-label">Success Rate</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{format_duration(avg_duration)}</div>
                    <div class="stat-label">Avg Duration</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{format_duration(min_duration)} - {format_duration(max_duration)}</div>
                    <div class="stat-label">Duration Range</div>
                </div>
            </div>

            <h2 class="section-title">Details</h2>
            <div class="filters">
                <div class="filter-group">
                    <label for="filter-model">Model</label>
                    <input type="text" id="filter-model" placeholder="Filter by model...">
                </div>
                <div class="filter-actions">
                    <button id="clear-filters" class="btn btn-secondary">Clear Filters</button>
                </div>
            </div>

            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th class="sortable"><span>Score</span></th>
                            <th class="sortable"><span>Model</span></th>
                            <th class="sortable"><span>Duration</span></th>
                            <th class="sortable"><span>Session (KB)</span></th>
"""

    # Collect all unique test names across all models
    all_test_names = set()
    for model in models_sorted:
        test_results = model.get("test_results", [])
        for test in test_results:
            all_test_names.add(test.get("name", "unknown"))

    # Sort test names for consistent ordering
    sorted_test_names = sorted(all_test_names)

    # Add test column headers with rotation
    for test_name in sorted_test_names:
        html += f'                            <th class="sortable test-header"><span>{escape_html(test_name)}</span></th>\n'

    html += """                        </tr>
                    </thead>
                    <tbody>
"""

    # Generate table rows
    for rank, model in enumerate(models_sorted, start=1):
        test_results = model.get("test_results", [])

        # Create a mapping of test name to test result
        test_map = {test.get("name", "unknown"): test for test in test_results}

        duration_str = format_duration(model.get("duration_seconds", 0))
        session_kb = model.get("session_size_kb", 0)

        # Strip model name prefix for display but keep full name for tooltip
        display_name, full_name = strip_model_prefix(model.get("model", "Unknown"))

        # Adjust paths based on structure and check for session.txt vs error.txt
        if path_prefix == "..":
            # New structure: we're at run_*/task_*/index.html, model files are at run_*/task_*/model_dir/
            model_dir_path = task_dir / model["model_dir"]
            model_test_prefix = model["model_dir"]
        else:
            # Old structure: we're at run_*/index.html, model files are at run_*/model_dir/
            model_dir_path = run_dir / model["model_dir"]
            model_test_prefix = model["model_dir"]

        # Check if session.txt exists, otherwise use error.txt
        session_file = model_dir_path / "session.txt"
        error_file = model_dir_path / "error.txt"

        if session_file.exists():
            model_session_link = f"{model['model_dir']}/session.txt"
        elif error_file.exists():
            model_session_link = f"{model['model_dir']}/error.txt"
        else:
            model_session_link = (
                f"{model['model_dir']}/session.txt"  # Fallback to session.txt
            )

        html += f"""                            <tr data-model-full="{escape_html(full_name)}">
                                <td data-sort="{model["global_score"]}">{model["global_score"]:.1f}%</td>
                                <td><a href="{model_session_link}" title="{escape_html(full_name)}">{escape_html(display_name)}</a></td>
                                <td>{duration_str}</td>
                                <td>{session_kb:.1f}</td>
"""

        # Add a cell for each test
        for test_name in sorted_test_names:
            if test_name in test_map:
                test = test_map[test_name]
                passed = test.get("passed", False)
                output_file = test.get("output_file", "")
                status_icon = "✅" if passed else "❌"

                if output_file:
                    html += f'                                <td class="test-cell"><a href="{model_test_prefix}/{output_file}">{status_icon}</a></td>\n'
                else:
                    html += f'                                <td class="test-cell">{status_icon}</td>\n'
            else:
                html += '                                <td class="test-cell">—</td>\n'

        html += "                            </tr>\n"

    html += f"""                        </tbody>
                    </table>
                </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <div class="footer-content">
                <p>Built with love by <a href="https://monadical.com" target="_blank" rel="noopener" class="footer-logo-link">
                    <img src="{static_path}/monadical-logo.png" alt="Monadical" height="20">
                </a></p>
            </div>
        </div>
    </footer>

    <script src="{static_path}/main.js?v={js_version}"></script>
</body>
</html>
"""

    # Write the file
    with open(index_path, "w") as f:
        f.write(html)

    return True


def generate_run_overview_page(run_dir, run_data, static_source, force=False):
    """
    Generate the run overview page (model x task grid) for a multi-task run.

    Args:
        run_dir: Path to run directory
        run_data: Run data dict from load_run_data()
        static_source: Path to static source directory (for cache busting)
        force: If True, regenerate even if index.html exists

    Returns:
        bool: True if generated, False if skipped (cached)
    """
    index_path = run_dir / "index.html"

    # Skip if already exists (caching) unless force is True
    if index_path.exists() and not force:
        return False

    tasks = run_data["tasks"]
    run_id = run_data["run_id"]
    run_timestamp = run_data.get("timestamp")

    # Collect all unique models across all tasks
    all_models = {}  # model_name -> {task_name: model_data}
    task_names_sorted = sorted(tasks.keys())

    for task_name, task_data in tasks.items():
        for model in task_data["models"]:
            model_name = model.get("model", "Unknown")
            if model_name not in all_models:
                all_models[model_name] = {}
            all_models[model_name][task_name] = model

    # Calculate overall statistics
    total_models = len(all_models)
    total_tasks = len(tasks)

    # Calculate overall success rate (across all model-task combinations)
    total_combinations = 0
    passed_combinations = 0
    for model_name, task_results in all_models.items():
        for task_name in task_names_sorted:
            if task_name in task_results:
                total_combinations += 1
                if task_results[task_name].get("passed", False):
                    passed_combinations += 1

    overall_success_rate = (
        (passed_combinations / total_combinations * 100)
        if total_combinations > 0
        else 0
    )

    # Sort models by overall score (percentage of tasks passed)
    def calc_model_score(model_name):
        task_results = all_models[model_name]
        passed = sum(1 for t in task_results.values() if t.get("passed", False))
        return (passed / total_tasks * 100) if total_tasks > 0 else 0

    models_sorted = sorted(all_models.keys(), key=calc_model_score, reverse=True)

    # Get cache-busting versions
    css_version = get_static_file_version(static_source, "style.css")
    js_version = get_static_file_version(static_source, "main.js")

    # Create user-friendly breadcrumb with datetime
    if run_timestamp:
        run_display = f"Run of {run_timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
    else:
        run_display = run_id

    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="LLM Evaluation - {run_display}">
    <title>{run_display} - LLM Evaluation</title>
    <link rel="stylesheet" href="../static/style.css?v={css_version}">
</head>
<body class="run-page overview-page">
    <header>
        <div class="container">
            <div class="header-title">
                <a href="../index.html" class="logo-link"><h1>LLM Evaluation</h1></a>
                <a href="../index.html" class="breadcrumb-link"><h2 class="breadcrumb">← Back to main page</h2></a>
            </div>
            <div class="header-meta">
                <a href="https://monadical.com" target="_blank" rel="noopener" class="monadical-logo">
                    <img src="../static/monadical-logo.png" alt="Monadical">
                </a>
            </div>
        </div>
    </header>

    <main>
        <div class="container">
            <h2 class="section-title">{run_display}</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">{total_models}</div>
                    <div class="stat-label">Models Tested</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{total_tasks}</div>
                    <div class="stat-label">Total Tasks</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{overall_success_rate:.1f}%</div>
                    <div class="stat-label">Overall Success Rate</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{passed_combinations}/{total_combinations}</div>
                    <div class="stat-label">Passed Combinations</div>
                </div>
            </div>

            <h2 class="section-title">Details</h2>
            <div class="filters">
                <div class="filter-group">
                    <label for="filter-model">Model</label>
                    <input type="text" id="filter-model" placeholder="Filter by model...">
                </div>
                <div class="filter-actions">
                    <button id="clear-filters" class="btn btn-secondary">Clear Filters</button>
                </div>
            </div>

            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th class="sortable"><span>Score</span></th>
                            <th class="sortable"><span>Model</span></th>
"""

    # Add task column headers with rotation
    for task_name in task_names_sorted:
        html += f'                            <th class="sortable task-header"><span>{escape_html(task_name)}</span></th>\n'

    html += """                        </tr>
                    </thead>
                    <tbody>
"""

    # Generate table rows
    for model_name in models_sorted:
        task_results = all_models[model_name]
        display_name, full_name = strip_model_prefix(model_name)
        overall_score = calc_model_score(model_name)

        html += f"""                            <tr data-model-full="{escape_html(full_name)}">
                                <td data-sort="{overall_score}">{overall_score:.1f}%</td>
                                <td title="{escape_html(full_name)}">{escape_html(display_name)}</td>
"""

        # Add task cells
        for task_name in task_names_sorted:
            if task_name in task_results:
                model_data = task_results[task_name]
                passed = model_data.get("passed", False)
                status_icon = "✅" if passed else "❌"
                task_link = f"{task_name}/index.html"

                html += f'                                <td class="test-cell"><a href="{task_link}">{status_icon}</a></td>\n'
            else:
                html += '                                <td class="test-cell">—</td>\n'

        html += "                            </tr>\n"

    html += """                        </tbody>
                    </table>
                </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <div class="footer-content">
                <p>Built with love by <a href="https://monadical.com" target="_blank" rel="noopener" class="footer-logo-link">
                    <img src="../static/monadical-logo.png" alt="Monadical" height="20">
                </a></p>
            </div>
        </div>
    </footer>

    <script src="../static/main.js?v={js_version}"></script>
</body>
</html>
"""

    # Write the file
    with open(index_path, "w") as f:
        f.write(html)

    return True


def generate_root_index_page(runs_dir, all_runs, static_source):
    """
    Generate the root index.html with overview of all runs.

    Args:
        runs_dir: Path to runs directory
        all_runs: List of run data dicts, sorted by date descending
        static_source: Path to static source directory (for cache busting)
    """
    # Limit to last 50 runs
    recent_runs = all_runs[:50]

    # Collect unique models for filters
    all_models = set()

    for run in recent_runs:
        for task_name, task_data in run["tasks"].items():
            for model in task_data["models"]:
                all_models.add(model.get("model", "Unknown"))

    # Sort for consistent display
    sorted_models = sorted(all_models)

    # Get cache-busting versions
    css_version = get_static_file_version(static_source, "style.css")
    js_version = get_static_file_version(static_source, "main.js")

    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="LLM Evaluation - Automated LLM Model Evaluation">
    <title>LLM Evaluation</title>
    <link rel="stylesheet" href="static/style.css?v={css_version}">
</head>
<body>
    <header>
        <div class="container">
            <div class="header-title">
                <a href="index.html" class="logo-link"><h1>LLM Evaluation</h1></a>
            </div>
            <div class="header-meta">
                <a href="https://monadical.com" target="_blank" rel="noopener" class="monadical-logo">
                    <img src="static/monadical-logo.png" alt="Monadical">
                </a>
            </div>
        </div>
    </header>

    <main>
        <div class="container">
            <div class="filters">
                <div class="filter-group">
                    <label for="filter-model">Model</label>
                    <input type="text" id="filter-model" placeholder="Filter by model...">
                </div>
                <div class="filter-actions">
                    <button id="clear-filters" class="btn btn-secondary">Clear Filters</button>
                </div>
            </div>

            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th class="sortable" data-sort-type="date">Date/Time</th>
                            <th>Models Score</th>
                        </tr>
                    </thead>
                    <tbody>
"""

    # Generate table rows
    for run in recent_runs:
        date_str = run["timestamp"].strftime("%Y-%m-%d %H:%M:%S")
        date_sort = run["timestamp"].isoformat()

        # Calculate model scores for this run
        # model_name -> (tasks_passed, total_tasks)
        model_scores = {}

        for task_name, task_data in run["tasks"].items():
            for model_data in task_data["models"]:
                model_name = model_data.get("model", "Unknown")
                passed = model_data.get("passed", False)

                if model_name not in model_scores:
                    model_scores[model_name] = {"passed": 0, "total": 0}

                model_scores[model_name]["total"] += 1
                if passed:
                    model_scores[model_name]["passed"] += 1

        # Always link to run overview page (run_*/index.html)
        # This ensures consistent navigation even for single-task runs
        run_link = f"{run['run_id']}/index.html"

        html += f"""                            <tr>
                                <td data-sort="{date_sort}"><a href="{run_link}" class="date-link">{date_str}</a></td>
                                <td>
"""

        # Generate models score list
        html += '                                    <div class="model-list">\n'

        # Sort models: by pass rate (descending), then by name
        sorted_model_items = sorted(
            model_scores.items(),
            key=lambda x: (
                x[1]["passed"] / x[1]["total"] if x[1]["total"] > 0 else 0,
                x[0],
            ),
            reverse=True,
        )

        for model_name, scores in sorted_model_items:
            display_name, full_name = strip_model_prefix(model_name)
            passed = scores["passed"]
            total = scores["total"]
            pass_rate = passed / total if total > 0 else 0

            # Determine color class based on pass rate
            if pass_rate >= 1.0:
                status_class = "success"
            elif pass_rate >= 0.5:
                status_class = "warning"
            else:
                status_class = "error"

            html += f'                                        <span class="model-tag {status_class}" title="{escape_html(full_name)}" data-model-full="{escape_html(full_name)}"><span class="model-name">{escape_html(display_name)}</span><span class="model-score">{passed}/{total}</span></span>\n'

        html += "                                    </div>\n"
        html += "                                </td>\n"
        html += "                            </tr>\n"

    html += f"""                        </tbody>
                    </table>
                </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <div class="footer-content">
                <p>Built with love by <a href="https://monadical.com" target="_blank" rel="noopener" class="footer-logo-link">
                    <img src="static/monadical-logo.png" alt="Monadical" height="20">
                </a></p>
            </div>
        </div>
    </footer>

    <script src="static/main.js?v={js_version}"></script>
</body>
</html>
"""

    # Write the file
    index_path = runs_dir / "index.html"
    with open(index_path, "w") as f:
        f.write(html)

    print(f"Generated root index: {index_path}")


def get_static_file_version(static_source, filename):
    """
    Get cache-busting version string for a static file based on modification time.

    Args:
        static_source: Path to source static directory
        filename: Name of the file

    Returns:
        str: Version string (timestamp of last modification)
    """
    file_path = static_source / filename
    if file_path.exists():
        mtime = int(file_path.stat().st_mtime)
        return str(mtime)
    return "1"


def copy_static_assets(static_source, runs_dir):
    """
    Copy static assets from static/ to runs/static/

    Args:
        static_source: Path to source static directory
        runs_dir: Path to runs directory
    """
    static_dest = runs_dir / "static"

    # Create destination if it doesn't exist
    static_dest.mkdir(exist_ok=True)

    # Copy CSS and JS files
    for file in static_source.glob("*"):
        if file.is_file():
            shutil.copy2(file, static_dest / file.name)
            print(f"Copied {file.name} to {static_dest / file.name}")


def format_duration(seconds):
    """Format duration in seconds to human-readable string."""
    if seconds < 60:
        return f"{seconds:.0f}s"
    minutes = int(seconds // 60)
    secs = int(seconds % 60)
    return f"{minutes}m {secs}s"


def strip_model_prefix(model_name):
    """
    Strip litellm/openrouter/ prefix from model name for display.
    Returns (display_name, full_name) tuple.
    """
    full_name = model_name
    display_name = model_name

    # Strip litellm/openrouter/ prefix
    if display_name.startswith("litellm/openrouter/"):
        display_name = display_name.replace("litellm/openrouter/", "", 1)

    return (display_name, full_name)


def escape_html(text):
    """Escape HTML special characters."""
    if text is None:
        return ""
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&#39;")
    )


def main():
    parser = argparse.ArgumentParser(
        description="Generate static HTML website from LLMEval results"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force regeneration of all run detail pages (bypass caching)",
    )

    args = parser.parse_args()

    # Set up paths
    base_dir = Path(__file__).parent
    runs_dir = base_dir / "runs"
    static_source = base_dir / "static"

    # Validate directories
    if not runs_dir.exists():
        print(f"Error: Runs directory not found: {runs_dir}")
        return 1

    if not static_source.exists():
        print(f"Error: Static source directory not found: {static_source}")
        return 1

    # Find all run directories
    run_dirs = sorted(
        [d for d in runs_dir.iterdir() if d.is_dir() and d.name.startswith("run_")]
    )

    if not run_dirs:
        print("Warning: No run directories found")
        return 0

    print(f"Found {len(run_dirs)} run directories")

    # Load all run data
    all_runs = []
    generated_count = 0
    skipped_count = 0

    for run_dir in run_dirs:
        print(f"Processing {run_dir.name}...")

        try:
            run_data = load_run_data(run_dir)

            if not run_data["tasks"]:
                print(f"  Warning: No tasks found in {run_dir.name}, skipping")
                continue

            all_runs.append(run_data)

            # Determine if this is a multi-task run
            num_tasks = len(run_data["tasks"])
            is_multi_task = num_tasks > 1

            if is_multi_task:
                # Generate run overview page (model x task grid)
                was_overview_generated = generate_run_overview_page(
                    run_dir, run_data, static_source, force=args.force
                )

                # Generate task detail pages
                for task_name, task_data in run_data["tasks"].items():
                    was_task_generated = generate_task_detail_page(
                        run_dir,
                        task_name,
                        task_data,
                        static_source,
                        run_data.get("timestamp"),
                        force=args.force,
                    )
                    if was_task_generated:
                        print(
                            f"  ✓ Generated {task_name}/index.html ({len(task_data['models'])} models)"
                        )
                        generated_count += 1
                    else:
                        print(f"  ⊙ Skipped {task_name}/index.html (cached)")
                        skipped_count += 1

                if was_overview_generated:
                    print(f"  ✓ Generated run overview index.html ({num_tasks} tasks)")
                else:
                    print(f"  ⊙ Skipped run overview (cached)")
            else:
                # Single task run - generate both overview and task detail pages
                # Generate run overview page
                was_overview_generated = generate_run_overview_page(
                    run_dir, run_data, static_source, force=args.force
                )

                # Generate task detail page
                task_name = list(run_data["tasks"].keys())[0]
                task_data = run_data["tasks"][task_name]

                was_task_generated = generate_task_detail_page(
                    run_dir,
                    task_name,
                    task_data,
                    static_source,
                    run_data.get("timestamp"),
                    force=args.force,
                )

                if was_task_generated:
                    print(
                        f"  ✓ Generated {task_name}/index.html ({len(task_data['models'])} models)"
                    )
                    generated_count += 1
                else:
                    print(f"  ⊙ Skipped {task_name}/index.html (cached)")
                    skipped_count += 1

                if was_overview_generated:
                    print(f"  ✓ Generated run overview index.html (1 task)")
                else:
                    print(f"  ⊙ Skipped run overview (cached)")

        except Exception as e:
            print(f"  Error processing {run_dir.name}: {e}")
            import traceback

            traceback.print_exc()
            continue

    # Sort runs by date descending (most recent first)
    all_runs.sort(key=lambda r: r["timestamp"], reverse=True)

    # Generate root index page
    print("\nGenerating root index page...")
    generate_root_index_page(runs_dir, all_runs, static_source)

    # Copy static assets
    print("\nCopying static assets...")
    copy_static_assets(static_source, runs_dir)

    # Print summary
    print("\n" + "=" * 60)
    print("Summary:")
    print(f"  Total runs processed: {len(all_runs)}")
    print(f"  Detail pages generated: {generated_count}")
    print(f"  Detail pages skipped (cached): {skipped_count}")
    print(f"  Root index: {runs_dir / 'index.html'}")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    exit(main())
