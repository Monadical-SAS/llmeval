#!/usr/bin/env python3
"""
LLMEval Static Website Generator

Generates static HTML pages from evaluation results:
- Root index page (runs/index.html) with last 50 runs
- Per-run detail pages (runs/run_*/index.html) with model rankings
- Copies static assets to runs/static/

Usage:
    python llmwebsite.py [--force]

Options:
    --force    Regenerate all run detail pages (bypasses caching)
"""

import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path


def normalize_model_name(model_name):
    """Normalize model name for directory structure."""
    return model_name.replace("/", "-")


def extract_task_name(run_dir, models):
    """
    Extract task name from run directory structure.
    Tries to get task_name from result.json files first.
    """
    # Try to get from result.json files (preferred)
    if models:
        for model in models:
            task_name = model.get('task_name')
            if task_name:
                return task_name

    # Fallback: use run directory name
    return run_dir.name.replace("run_", "")


def load_run_data(run_dir):
    """
    Load all result.json files from a run directory.

    Returns:
        dict: {
            'run_id': str,
            'timestamp': datetime,
            'task_name': str,
            'models': [model_data, ...]
        }
    """
    run_id = run_dir.name

    # Extract timestamp from run directory name (run_YYYYMMDD_HHMMSS)
    timestamp_str = run_id.replace("run_", "")
    try:
        timestamp = datetime.strptime(timestamp_str, "%Y%m%d_%H%M%S")
    except ValueError:
        timestamp = datetime.fromtimestamp(run_dir.stat().st_mtime)

    # Load all result.json files
    models = []
    result_files = list(run_dir.glob("*/result.json"))

    for result_file in result_files:
        try:
            with open(result_file, 'r') as f:
                data = json.load(f)

            # Calculate global score (percentage of tests passed)
            test_results = data.get('test_results', [])
            if test_results:
                passed_tests = sum(1 for t in test_results if t.get('passed', False))
                total_tests = len(test_results)
                global_score = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
            else:
                # No tests, consider as 100% if result is Pass
                global_score = 100 if data.get('result') == '✅ Pass' else 0

            # Add computed fields
            data['global_score'] = global_score
            data['model_dir'] = result_file.parent.name
            data['passed'] = data.get('result') == '✅ Pass'

            models.append(data)
        except (json.JSONDecodeError, FileNotFoundError) as e:
            print(f"Warning: Could not load {result_file}: {e}")
            continue

    # Extract task name from result.json or infer from directory structure
    task_name = extract_task_name(run_dir, models)

    return {
        'run_id': run_id,
        'timestamp': timestamp,
        'task_name': task_name,
        'models': models
    }


def generate_run_detail_page(run_dir, run_data, force=False):
    """
    Generate the index.html for a specific run.

    Args:
        run_dir: Path to run directory
        run_data: Run data dict from load_run_data()
        force: If True, regenerate even if index.html exists
    """
    index_path = run_dir / "index.html"

    # Skip if already exists (caching) unless force is True
    if index_path.exists() and not force:
        return False

    models = run_data['models']

    # Sort models by global score descending
    models_sorted = sorted(models, key=lambda m: m['global_score'], reverse=True)

    # Calculate statistics
    total_models = len(models_sorted)
    passed_models = sum(1 for m in models_sorted if m['passed'])
    success_rate = (passed_models / total_models * 100) if total_models > 0 else 0

    durations = [m.get('duration_seconds', 0) for m in models_sorted]
    min_duration = min(durations) if durations else 0
    max_duration = max(durations) if durations else 0
    avg_duration = sum(durations) / len(durations) if durations else 0

    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="LLM Evaluation - {run_data['run_id']}">
    <title>{run_data['run_id']} - LLM Evaluation</title>
    <link rel="stylesheet" href="../static/style.css">
</head>
<body class="run-page">
    <header>
        <div class="container">
            <div class="header-title">
                <a href="../index.html" class="logo-link"><h1>LLM Evaluation</h1></a>
                <a href="../index.html" class="breadcrumb-link"><h2 class="breadcrumb">← {run_data['run_id']}</h2></a>
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
        test_results = model.get('test_results', [])
        for test in test_results:
            all_test_names.add(test.get('name', 'unknown'))

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
        test_results = model.get('test_results', [])

        # Create a mapping of test name to test result
        test_map = {test.get('name', 'unknown'): test for test in test_results}

        duration_str = format_duration(model.get('duration_seconds', 0))
        session_kb = model.get('session_size_kb', 0)

        # Strip model name prefix for display but keep full name for tooltip
        display_name, full_name = strip_model_prefix(model.get('model', 'Unknown'))
        model_session_link = f'{model["model_dir"]}/session.txt'

        html += f"""                            <tr>
                                <td data-sort="{model['global_score']}">{model['global_score']:.1f}%</td>
                                <td><a href="{model_session_link}" title="{escape_html(full_name)}">{escape_html(display_name)}</a></td>
                                <td>{duration_str}</td>
                                <td>{session_kb:.1f}</td>
"""

        # Add a cell for each test
        for test_name in sorted_test_names:
            if test_name in test_map:
                test = test_map[test_name]
                passed = test.get('passed', False)
                output_file = test.get('output_file', '')
                status_icon = '✅' if passed else '❌'

                if output_file:
                    html += f'                                <td class="test-cell"><a href="{model["model_dir"]}/{output_file}">{status_icon}</a></td>\n'
                else:
                    html += f'                                <td class="test-cell">{status_icon}</td>\n'
            else:
                html += '                                <td class="test-cell">—</td>\n'

        html += '                            </tr>\n'

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

    <script src="../static/main.js"></script>
</body>
</html>
"""

    # Write the file
    with open(index_path, 'w') as f:
        f.write(html)

    return True


def generate_root_index_page(runs_dir, all_runs):
    """
    Generate the root index.html with overview of all runs.

    Args:
        runs_dir: Path to runs directory
        all_runs: List of run data dicts, sorted by date descending
    """
    # Limit to last 50 runs
    recent_runs = all_runs[:50]

    # Collect unique models and tasks for filters
    all_models = set()
    all_tasks = set()

    for run in recent_runs:
        all_tasks.add(run['task_name'])
        for model in run['models']:
            all_models.add(model.get('model', 'Unknown'))

    # Sort for consistent display
    sorted_models = sorted(all_models)
    sorted_tasks = sorted(all_tasks)

    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="LLM Evaluation - Automated LLM Model Evaluation">
    <title>LLM Evaluation</title>
    <link rel="stylesheet" href="static/style.css">
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
                <div class="filter-group">
                    <label for="filter-task">Task</label>
                    <select id="filter-task">
                        <option value="">All Tasks</option>
"""

    for task in sorted_tasks:
        html += f'                        <option value="{escape_html(task)}">{escape_html(task)}</option>\n'

    html += f"""                    </select>
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
                            <th class="sortable">Models</th>
                            <th class="sortable">Passed</th>
                            <th class="sortable">Failed</th>
                            <th class="sortable">Success Rate</th>
                            <th>OK Models</th>
                            <th>Failed Models</th>
                        </tr>
                    </thead>
                    <tbody>
"""

    # Generate table rows
    for run in recent_runs:
        models = run['models']
        total_models = len(models)
        passed_models = [m for m in models if m['passed']]
        failed_models = [m for m in models if not m['passed']]

        num_passed = len(passed_models)
        num_failed = len(failed_models)
        success_rate = (num_passed / total_models * 100) if total_models > 0 else 0

        # Create model lists with stripped names and tooltips
        ok_models_html = '<div class="model-list">'
        for model in passed_models[:5]:  # Limit display
            display_name, full_name = strip_model_prefix(model.get("model", "Unknown"))
            ok_models_html += f'<span class="model-tag success" data-model-full="{escape_html(full_name)}" title="{escape_html(full_name)}">{escape_html(display_name)}</span>'
        if len(passed_models) > 5:
            ok_models_html += f'<span class="model-tag">+{len(passed_models) - 5} more</span>'
        ok_models_html += '</div>'

        failed_models_html = '<div class="model-list">'
        for model in failed_models[:5]:  # Limit display
            display_name, full_name = strip_model_prefix(model.get("model", "Unknown"))
            failed_models_html += f'<span class="model-tag error" data-model-full="{escape_html(full_name)}" title="{escape_html(full_name)}">{escape_html(display_name)}</span>'
        if len(failed_models) > 5:
            failed_models_html += f'<span class="model-tag">+{len(failed_models) - 5} more</span>'
        failed_models_html += '</div>'

        if not passed_models:
            ok_models_html = '<span class="text-muted">None</span>'
        if not failed_models:
            failed_models_html = '<span class="text-muted">None</span>'

        date_str = run['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
        date_sort = run['timestamp'].isoformat()

        html += f"""                            <tr>
                                <td data-sort="{date_sort}"><a href="{run['run_id']}/index.html" class="date-link">{date_str}</a></td>
                                <td data-sort="{total_models}">{total_models}</td>
                                <td data-sort="{num_passed}"><span class="badge badge-success">{num_passed}</span></td>
                                <td data-sort="{num_failed}"><span class="badge badge-error">{num_failed}</span></td>
                                <td data-sort="{success_rate}">{success_rate:.1f}%</td>
                                <td>{ok_models_html}</td>
                                <td>{failed_models_html}</td>
                            </tr>
"""

    html += """                        </tbody>
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

    <script src="static/main.js"></script>
</body>
</html>
"""

    # Write the file
    index_path = runs_dir / "index.html"
    with open(index_path, 'w') as f:
        f.write(html)

    print(f"Generated root index: {index_path}")


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
    return (str(text)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&#39;"))


def main():
    parser = argparse.ArgumentParser(
        description="Generate static HTML website from LLMEval results"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force regeneration of all run detail pages (bypass caching)"
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
    run_dirs = sorted([d for d in runs_dir.iterdir() if d.is_dir() and d.name.startswith("run_")])

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

            if not run_data['models']:
                print(f"  Warning: No models found in {run_dir.name}, skipping")
                continue

            all_runs.append(run_data)

            # Generate detail page
            was_generated = generate_run_detail_page(run_dir, run_data, force=args.force)

            if was_generated:
                print(f"  ✓ Generated index.html ({len(run_data['models'])} models)")
                generated_count += 1
            else:
                print(f"  ⊙ Skipped (cached)")
                skipped_count += 1

        except Exception as e:
            print(f"  Error processing {run_dir.name}: {e}")
            continue

    # Sort runs by date descending (most recent first)
    all_runs.sort(key=lambda r: r['timestamp'], reverse=True)

    # Generate root index page
    print("\nGenerating root index page...")
    generate_root_index_page(runs_dir, all_runs)

    # Copy static assets
    print("\nCopying static assets...")
    copy_static_assets(static_source, runs_dir)

    # Print summary
    print("\n" + "="*60)
    print("Summary:")
    print(f"  Total runs processed: {len(all_runs)}")
    print(f"  Detail pages generated: {generated_count}")
    print(f"  Detail pages skipped (cached): {skipped_count}")
    print(f"  Root index: {runs_dir / 'index.html'}")
    print("="*60)

    return 0


if __name__ == "__main__":
    exit(main())
