# LLMEval Refactoring Plan

## Overview
Transform LLMEval from "one run = one task" to "one run = multiple tasks" architecture.

---

## Current Architecture

### Directory Structure
```
runs/
  run_20251020_165410/           # One run = ONE task
    litellm-model1/               # Model directory
      workspace/                  # Working directory
      session.txt                 # LLM session log
      result.json                 # Results metadata
      test_test.txt               # Test outputs
    litellm-model2/
      ...
    summary.md                    # Summary for this single task
    summary-detailed.md
    index.html                    # Run detail page
```

### Data Flow (Current)
1. **llmeval.py** runs with `--model model1,model2 --task tasks/task1`
2. Creates `runs/run_YYYYMMDD_HHMMSS/`
3. For each model, creates `{normalized-model}/` directory
4. Executes task in `workspace/` subdirectory
5. Saves `result.json` with `task_name` field
6. Generates summary files for ONE task

### Website (Current)
- **Root index (`runs/index.html`)**: One row per run (= one task with N models)
  - Columns: Date | Models | Passed | Failed | Success Rate | OK Models | Failed Models
- **Run detail (`runs/run_*/index.html`)**: One row per model
  - Columns: Score | Model | Duration | Session | Test1 | Test2 | Test3...

---

## Target Architecture

### Directory Structure (New)
```
runs/
  run_20251020_165410/                    # One run = MULTIPLE tasks
    task1_file_list/                      # Task directory
      litellm-model1/                     # Model directory
        workspace/                        # Working directory
        session.txt                       # LLM session log
        result.json                       # Results for model1 on task1
        test_test_1.txt                   # Test outputs
      litellm-model2/
        workspace/
        session.txt
        result.json                       # Results for model2 on task1
      summary.md                          # Summary for task1
      summary-detailed.md
      index.html                          # Task detail page (NEW)
    task2_fix_python_syntax/              # Another task
      litellm-model1/
        ...
      litellm-model2/
        ...
      summary.md
      index.html                          # Task detail page (NEW)
    index.html                            # Run overview page (MODIFIED)
    run_metadata.json                     # Run-level metadata (NEW)
```

### Data Flow (New)
1. **llmeval.py** runs with `--model model1,model2 --task tasks/task1,tasks/task2`
2. Creates `runs/run_YYYYMMDD_HHMMSS/`
3. For each task:
   - Creates `{task_name}/` directory
   - For each model:
     - Creates `{task_name}/{normalized-model}/` directory
     - Executes task in `workspace/` subdirectory
     - Saves `result.json` with task and model info
   - Generates task-level summary files
   - Generates task detail page (`{task_name}/index.html`)
4. Generates run-level metadata (`run_metadata.json`)
5. Generates run overview page (`index.html`)

### Website Pages (New)

#### 1. Root Index (`runs/index.html`)
**Purpose**: Show all runs with task completion status

**Layout**: One row per run
```
Columns: Date/Time | Task1 | Task2 | Task3 | ... | Summary
```

**Visual Design**:
- Each task column shows model completion bars like `[model1 ✓] [model2 ✗] [model3 ✓]`
- Bar color coding:
  - **Green**: All models passed (100%)
  - **Orange**: ≥50% models passed
  - **Red**: <50% models passed
- Summary column: Overall stats (e.g., "12/15 tasks passed")
- Click on date → Go to run overview page
- Click on task cell → Go to task detail page

#### 2. Run Overview Page (`runs/run_*/index.html`)
**Purpose**: Show how all models performed across all tasks in this run

**Layout**: One row per model
```
Columns: Model | Task1 | Task2 | Task3 | ... | Overall Score
```

**Visual Design**:
- Each task column shows: `✅` (passed all tests) or `❌` (failed)
- Cells are clickable → Go to task detail page filtered to that model
- Overall score: Percentage of tasks passed
- Stats cards at top: Total models, Total tasks, Overall success rate

#### 3. Task Detail Page (`runs/run_*/task_name/index.html`) **[NEW]**
**Purpose**: Show how each model performed on individual tests for this task

**Layout**: One row per model
```
Columns: Score | Model | Duration | Session (KB) | Test1 | Test2 | Test3 | ...
```

**Visual Design**:
- Same as current run detail page, but scoped to one task
- Each test column: `✅` or `❌` with link to test output

---

## Implementation Plan

### Phase 1: llmeval.py Refactoring

#### Changes Required:

1. **CLI Arguments**
   - Modify `--task` to accept comma-separated list of task paths
   - Parse into list: `tasks = [Path(t.strip()) for t in args.task.split(",")]`

2. **Directory Structure**
   - Change from: `runs/run_*/` {model_dir} `/workspace/`
   - Change to: `runs/run_*/` {task_name} `/` {model_dir} `/workspace/`
   - Update `execute_model_task_impl()` to accept both `task_dir` and `task_name`

3. **Execution Flow**
   - Wrap current logic in outer loop: `for task_dir in tasks:`
   - For each task, run all models concurrently
   - Update `model_statuses` structure to be task-aware:
     ```python
     task_statuses = {
         'task1': {
             'model1': {...},
             'model2': {...}
         },
         'task2': {...}
     }
     ```

4. **Summary Generation**
   - `generate_summary()` becomes `generate_task_summary(run_dir, task_name, model_statuses)`
   - Called once per task, writes to `{run_dir}/{task_name}/summary.md`
   - Add new `generate_run_metadata(run_dir, task_statuses)`:
     - Writes `run_metadata.json` with:
       ```json
       {
         "run_id": "run_20251020_165410",
         "timestamp": "2025-10-20T16:54:10",
         "tasks": ["task1_file_list", "task2_fix_python_syntax"],
         "models": ["litellm/model1", "litellm/model2"],
         "summary": {
           "total_tasks": 2,
           "total_models": 2,
           "task_results": {
             "task1_file_list": {
               "models_passed": 1,
               "models_failed": 1
             }
           }
         }
       }
       ```

5. **Rich UI Updates**
   - Update status table to show: `Model | Task | Status | Duration | Result`
   - Group by task or flatten to show all model×task combinations

#### Key Functions to Modify:

- `main()`: Parse multiple tasks, loop over tasks
- `execute_model_task_impl()`: Update paths to include task directory
- `generate_summary()` → `generate_task_summary()`: Scoped to one task
- **NEW** `generate_run_metadata()`: Generate run-level JSON
- `create_status_table()`: Handle multi-task display

---

### Phase 2: llmwebsite.py Refactoring

#### Changes Required:

1. **Data Loading**
   - `load_run_data()` must now:
     - Scan for task directories (subdirs in run dir)
     - For each task dir, load all `*/result.json` files
     - Return structure:
       ```python
       {
         'run_id': 'run_20251020_165410',
         'timestamp': datetime(...),
         'tasks': {
           'task1_file_list': {
             'models': [model_data1, model_data2, ...]
           },
           'task2_fix_python_syntax': {
             'models': [...]
           }
         }
       }
       ```
   - Load `run_metadata.json` if available

2. **Root Index Generation** (`generate_root_index_page()`)

   **Table Structure**:
   ```html
   <th>Date/Time</th>
   <th>Task1</th>
   <th>Task2</th>
   ...
   <th>Overall</th>
   ```

   **Row Generation**:
   - For each run:
     - Date cell: Link to `{run_id}/index.html`
     - For each task:
       - Calculate: `models_passed / total_models`
       - Generate model completion bar (HTML/CSS):
         ```html
         <div class="task-result-bar">
           <span class="model-tag success">[model1 ✓]</span>
           <span class="model-tag error">[model2 ✗]</span>
         </div>
         ```
       - Color-code cell background:
         - Green: 100%
         - Orange: ≥50%
         - Red: <50%
       - Make cell clickable → `{run_id}/{task_name}/index.html`
     - Overall cell: Summary stats

   **Filtering**:
   - Keep model filter (filters runs by models used)
   - Keep task filter (shows/hides task columns)

3. **Run Overview Page** (`generate_run_overview_page()`) **[NEW]**

   **Purpose**: Replace current run detail page

   **Table Structure**:
   ```html
   <th>Model</th>
   <th>Task1</th>
   <th>Task2</th>
   ...
   <th>Overall Score</th>
   ```

   **Row Generation**:
   - For each model:
     - Model cell: Display name with tooltip
     - For each task:
       - Check if model passed all tests in that task
       - Show: `✅` or `❌`
       - Make cell clickable → `{task_name}/index.html#{model_id}`
     - Overall score: `(tasks_passed / total_tasks) × 100%`

   **Stats Cards**:
   - Total Models
   - Total Tasks
   - Overall Success Rate (% of model×task pairs that passed)

4. **Task Detail Page** (`generate_task_detail_page()`) **[NEW]**

   **Purpose**: Replicate current run detail page logic, scoped to one task

   **Table Structure**: (Same as current)
   ```html
   <th>Score</th>
   <th>Model</th>
   <th>Duration</th>
   <th>Session (KB)</th>
   <th>Test1</th>
   <th>Test2</th>
   ...
   ```

   **Row Generation**:
   - Same logic as current `generate_run_detail_page()`
   - But only for models in this task
   - Links updated: `../{model_dir}/session.txt`

#### Key Functions to Modify/Add:

- `load_run_data()`: Multi-task aware
- `generate_root_index_page()`: Task columns + bars
- **NEW** `generate_run_overview_page()`: Model rows × task columns
- **NEW** `generate_task_detail_page()`: Replicate current detail page per task
- **NEW** `calculate_task_stats()`: Helper for model completion bars
- **NEW** `get_bar_color_class()`: Returns CSS class based on pass rate

---

### Phase 3: CSS/JS Enhancements

#### CSS Additions (static/style.css):

```css
/* Task result bars in root index */
.task-result-bar {
  display: flex;
  gap: 0.25rem;
  flex-wrap: wrap;
}

/* Cell background colors based on pass rate */
.task-cell-green {
  background-color: rgba(16, 185, 129, 0.1);
}

.task-cell-orange {
  background-color: rgba(245, 158, 11, 0.1);
}

.task-cell-red {
  background-color: rgba(239, 68, 68, 0.1);
}

/* Clickable task cells */
.task-cell {
  cursor: pointer;
  transition: background-color 0.2s;
}

.task-cell:hover {
  filter: brightness(0.95);
}

/* Model tags in bars */
.model-tag-mini {
  padding: 0.125rem 0.25rem;
  font-size: 0.65rem;
}
```

#### JS Enhancements (static/main.js):

- Task column filtering (show/hide columns based on task filter)
- Model tag filtering in bars (same as current)
- Sorting by task columns (sort by pass rate)

---

## Migration Strategy

### Step 1: Backup
```bash
cp -r runs/ runs.backup/
```

### Step 2: Clear Runs
```bash
rm -rf runs/run_*/
```

### Step 3: Test Single Task (Backwards Compatibility Check)
```bash
# Old style (should still work)
uv run python llmeval.py --model litellm/model1 --task tasks/task1
```

Expected: Works but creates new directory structure `runs/run_*/task1/model1/`

### Step 4: Test Multiple Tasks
```bash
uv run python llmeval.py --model litellm/model1,litellm/model2 --task tasks/task1,tasks/task2
```

Expected: Creates `runs/run_*/task1/` and `runs/run_*/task2/`

### Step 5: Generate Website
```bash
uv run python llmwebsite.py --force
```

Expected: New 3-level page hierarchy

### Step 6: Verify
- Open `runs/index.html` → Check task columns and bars
- Click on run → Check model×task grid
- Click on task → Check test details

---

## Testing Checklist

### llmeval.py
- [x] Single task execution works
- [x] Multiple task execution works
- [x] Directory structure correct: `run_*/task_*/model_*/workspace/`
- [x] `result.json` contains correct `task_name`
- [x] Task summaries generated in `run_*/task_*/summary.md`
- [x] Run metadata generated in `run_*/run_metadata.json`
- [x] Rich UI shows multi-task progress
- [x] Concurrency works across tasks and models
- [x] Timeouts work per model×task

### llmwebsite.py
- [x] Root index shows task columns
- [x] Task cells show model completion bars
- [x] Bar colors correct (green/orange/red)
- [x] Run overview page shows model×task grid
- [x] Task detail pages generated per task
- [x] Links work: root → run overview → task detail
- [x] Filtering works (model, task)
- [x] Sorting works (date, pass rate)
- [x] Caching works (only regenerate on `--force`)

### Integration
- [x] Run llmeval.py with multiple tasks
- [x] Generate website with llmwebsite.py
- [x] Navigate all 3 levels in browser
- [x] Test filtering and sorting
- [x] Verify mobile responsiveness

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully:
- Phase 1: llmeval.py refactored (commit 448eed0)
- Phase 2: llmwebsite.py refactored (commit d45c123)
- Phase 3: CSS/JS enhancements (included in Phase 2)
- Testing: All tests passed (commits a8e0ac2, 9b240f9)
- Documentation: CLAUDE.md updated (commit ded5c24)

**Branch**: `multi-task-refactor`
**Total commits**: 5
**Ready for**: User review and merge to main

---

## Backwards Compatibility

**Breaking Changes**:
- Old runs will NOT be compatible (different directory structure)
- User must clear `runs/` directory before using new version

**Mitigation**:
- Document migration in CLAUDE.md
- Provide backup/restore instructions
- Update `.gitignore` to preserve old runs in separate directory

---

## Deliverables

### Modified Files:
1. `llmeval.py` - Multi-task execution
2. `llmwebsite.py` - 3-level page generation
3. `static/style.css` - Task bar styles
4. `static/main.js` - Task column filtering
5. `CLAUDE.md` - Updated documentation

### New Files:
1. `run_metadata.json` (per run) - Run-level summary
2. `{task_name}/index.html` (per task per run) - Task detail pages

### Deleted Files:
None (but old run structure incompatible)

---

## Timeline Estimate

- Phase 1 (llmeval.py): 2-3 hours
- Phase 2 (llmwebsite.py): 3-4 hours
- Phase 3 (CSS/JS): 1 hour
- Testing & debugging: 2 hours

**Total**: ~8-10 hours of development

---

## Open Questions

1. **Task naming**: Use directory name or extract from `task.md`?
   - **Decision**: Use directory name for consistency

2. **Concurrency model**: Run all model×task pairs concurrently or task-by-task?
   - **Decision**: Flatten to all pairs, respect `--concurrent` limit

3. **Summary files**: Keep task-level summaries or only run-level?
   - **Decision**: Keep both (task-level for detail, run-level for overview)

4. **Filtering**: Should root index filter show/hide task columns or just rows?
   - **Decision**: Filter rows by task name, always show all columns

---

## Next Steps

After approval:
1. Create feature branch: `git checkout -b multi-task-refactor`
2. Implement Phase 1 (llmeval.py)
3. Test with single and multiple tasks
4. Implement Phase 2 (llmwebsite.py)
5. Implement Phase 3 (CSS/JS)
6. Full integration testing
7. Update documentation
8. Merge to main
