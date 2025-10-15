#!/usr/bin/env python3

import argparse
import asyncio
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import re
import structlog
from rich.live import Live
from rich.table import Table


def strip_ansi(text):
    """Remove ANSI escape sequences from text."""
    ansi_escape = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")
    return ansi_escape.sub("", text)


def escape_markdown_code_blocks(text):
    """Escape triple backticks in text to prevent breaking markdown code blocks."""
    # Replace ``` with escaped version to prevent breaking markdown formatting
    return text.replace("```", "\\`\\`\\`")


CUBBIX_COMMAND_TEMPLATE = [
    "cubbix",
    "-i",
    "opencode",
    "--model",
    "{model}",
    "--no-shell",
    "--run",
    """
    if [ -f install.sh ]; then bash install.sh; fi;
    cd input && goose run -i ../task.md
    """,
    ".",
]

RUNS_DIR = "runs"
WORKSPACE_SUBDIR = "workspace"


def setup_logging(verbose):
    if verbose:
        structlog.configure(
            processors=[
                structlog.stdlib.filter_by_level,
                structlog.stdlib.PositionalArgumentsFormatter(),
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.StackInfoRenderer(),
                structlog.processors.format_exc_info,
                structlog.dev.ConsoleRenderer(),
            ],
            wrapper_class=structlog.stdlib.BoundLogger,
            logger_factory=structlog.stdlib.LoggerFactory(),
            cache_logger_on_first_use=True,
        )
        logger = structlog.get_logger()
        import logging

        logging.basicConfig(level=logging.DEBUG, format="%(message)s")
        return logger
    else:
        structlog.configure(
            processors=[
                structlog.stdlib.filter_by_level,
                structlog.stdlib.PositionalArgumentsFormatter(),
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.StackInfoRenderer(),
                structlog.processors.format_exc_info,
                structlog.dev.ConsoleRenderer(),
            ],
            wrapper_class=structlog.stdlib.BoundLogger,
            logger_factory=structlog.stdlib.LoggerFactory(),
            cache_logger_on_first_use=True,
        )
        logger = structlog.get_logger()
        import logging

        logging.basicConfig(level=logging.INFO, format="%(message)s")
        return logger


def normalize_model_name(model_name):
    return model_name.replace("/", "-")


def create_status_table(model_statuses):
    table = Table(title="LLMEval Progress")
    table.add_column("Model", style="cyan", width=25)
    table.add_column("Status", style="magenta", width=12)
    table.add_column("Duration", style="yellow", width=10)
    table.add_column("Session KB", style="green", width=12)
    table.add_column("Result", style="bold", width=12)

    for model, status in model_statuses.items():
        table.add_row(
            model,
            status["status"],
            status["duration"],
            status["session_size"],
            status["result"],
        )
    return table


def format_duration(seconds):
    if seconds < 60:
        return f"{seconds:.0f}s"
    minutes = int(seconds // 60)
    secs = int(seconds % 60)
    return f"{minutes}m {secs}s"


def get_file_size_kb(file_path):
    try:
        size_bytes = os.path.getsize(file_path)
        return f"{size_bytes / 1024:.1f}"
    except (OSError, FileNotFoundError):
        return "0.0"


async def run_command(command, cwd, output_file=None, logger=None, verbose=False):
    if logger:
        logger.info("Starting command", command=" ".join(command), cwd=str(cwd))

    process = await asyncio.create_subprocess_exec(
        *command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=os.environ.copy(),
    )

    output_lines = []
    async for line in process.stdout:
        decoded_line = line.decode("utf-8", errors="replace")
        output_lines.append(decoded_line)

    await process.wait()

    output_text = "".join(output_lines)
    if output_file:
        with open(output_file, "w") as f:
            f.write(output_text)

    if logger:
        logger.info(
            "Command completed",
            returncode=process.returncode,
            output_file=str(output_file) if output_file else None,
            output_lines=len(output_lines),
        )

    return process.returncode, output_text


async def execute_model_task(
    model,
    task_dir,
    run_dir,
    model_statuses,
    semaphore,
    logger=None,
    verbose=False,
    timeout=300,
):
    async with semaphore:
        try:
            return await execute_model_task_with_timeout(
                model,
                task_dir,
                run_dir,
                model_statuses,
                logger,
                verbose,
                timeout=timeout,
            )
        except asyncio.TimeoutError:
            model_statuses[model]["status"] = "Timeout"
            model_statuses[model]["result"] = "❌ Timeout"
            if logger:
                logger.error(f"Task timed out after {timeout} seconds", model=model)
            return
        except Exception as e:
            model_statuses[model]["status"] = "Failed"
            model_statuses[model]["result"] = "❌ Error"
            if logger:
                logger.error(f"Task failed with exception", model=model, error=str(e))
            return


async def execute_model_task_with_timeout(
    model, task_dir, run_dir, model_statuses, logger=None, verbose=False, timeout=300
):
    return await asyncio.wait_for(
        execute_model_task_impl(
            model, task_dir, run_dir, model_statuses, logger, verbose
        ),
        timeout=timeout,
    )


async def execute_model_task_impl(
    model, task_dir, run_dir, model_statuses, logger=None, verbose=False
):
    # Extract task name from task directory
    task_name = task_dir.name
    start_time = time.time()
    normalized_model = normalize_model_name(model)
    model_dir = run_dir / normalized_model
    workspace_dir = model_dir / WORKSPACE_SUBDIR

    if logger:
        logger.info(
            "Starting model execution",
            model=model,
            normalized_model=normalized_model,
            workspace_dir=str(workspace_dir),
            verbose_mode=verbose,
        )

    model_statuses[model] = {
        "status": "Preparing",
        "duration": "0s",
        "session_size": "0.0",
        "result": "-",
        "start_time": start_time,
        "test_results": [],
    }

    try:
        workspace_dir.mkdir(parents=True, exist_ok=True)
        if logger:
            logger.info("Created workspace directory", workspace_dir=str(workspace_dir))

        task_md = task_dir / "task.md"
        if task_md.exists():
            shutil.copy2(task_md, workspace_dir)
            if logger:
                logger.info("Copied task.md to workspace")

        install_sh = task_dir / "install.sh"
        if install_sh.exists():
            shutil.copy2(install_sh, workspace_dir)
            if logger:
                logger.info("Copied install.sh to workspace")

        test_files = sorted(
            [f for f in task_dir.glob("*.sh") if f.name.startswith("test")]
        )
        for test_file in test_files:
            shutil.copy2(test_file, workspace_dir)
            if logger:
                logger.info(f"Copied {test_file.name} to workspace")

        input_workspace_dir = workspace_dir / "input"

        input_dir = task_dir / "input"
        if input_dir.exists():
            shutil.copytree(input_dir, input_workspace_dir, dirs_exist_ok=True)
            if logger:
                logger.info("Copied input directory contents to workspace/input")
        else:
            input_workspace_dir.mkdir(exist_ok=True)
            if logger:
                logger.info("Created empty input directory")

        if logger:
            logger.info(
                "Created input directory and copied files",
                input_dir=str(input_workspace_dir),
            )

        model_statuses[model]["status"] = "Running"

        cubbix_command = [
            cmd.format(model=model) if "{model}" in cmd else cmd
            for cmd in CUBBIX_COMMAND_TEMPLATE
        ]

        if logger:
            logger.info(
                "Starting cubbix execution",
                cubbix_command=" ".join(cubbix_command),
                cwd=str(workspace_dir),
            )

        returncode, _ = await run_command(
            cubbix_command,
            workspace_dir,
            model_dir / "session.txt",
            logger,
            verbose,
        )

        session_size = get_file_size_kb(model_dir / "session.txt")
        model_statuses[model]["session_size"] = session_size

        if returncode != 0:
            model_statuses[model]["status"] = "Failed"
            model_statuses[model]["result"] = "❌ Exec"
            if logger:
                logger.error(
                    "Cubbix execution failed",
                    returncode=returncode,
                    session_size_kb=session_size,
                )
            return

        if logger:
            logger.info(
                "Cubbix execution completed successfully", session_size_kb=session_size
            )

        model_statuses[model]["status"] = "Testing"

        test_files = sorted(
            [f for f in workspace_dir.glob("*.sh") if f.name.startswith("test")]
        )
        test_results = []

        if test_files:
            for test_file in test_files:
                if logger:
                    logger.info(
                        f"Starting test execution: {test_file.name}",
                        cwd=str(workspace_dir),
                    )

                test_output_name = f"test_{test_file.stem}.txt"
                returncode, _ = await run_command(
                    ["bash", test_file.name],
                    workspace_dir,
                    model_dir / test_output_name,
                    logger,
                    verbose,
                )

                test_results.append(
                    {
                        "name": test_file.name,
                        "passed": returncode == 0,
                        "returncode": returncode,
                        "output_file": test_output_name,
                    }
                )

                if returncode != 0:
                    model_statuses[model]["status"] = "Failed"
                    model_statuses[model]["result"] = f"❌ {test_file.name}"
                    model_statuses[model]["test_results"] = test_results
                    if logger:
                        logger.error(
                            f"Test execution failed: {test_file.name}",
                            returncode=returncode,
                        )
                    return

                if logger:
                    logger.info(
                        f"Test execution completed successfully: {test_file.name}"
                    )

            model_statuses[model]["test_results"] = test_results
        else:
            if logger:
                logger.info("No test files found, skipping test phase")
            model_statuses[model]["test_results"] = []

        model_statuses[model]["status"] = "Complete"
        model_statuses[model]["result"] = "✅ Pass"
        if logger:
            logger.info("Model execution completed successfully")

    except Exception as e:
        model_statuses[model]["status"] = "Failed"
        model_statuses[model]["result"] = "❌ Error"
        if logger:
            logger.error(
                "Unexpected error during model execution", error=str(e), model=model
            )
        with open(model_dir / "error.txt", "w") as f:
            f.write(str(e))

    finally:
        duration = time.time() - start_time
        model_statuses[model]["duration"] = format_duration(duration)

        result_data = {
            "model": model,
            "task_name": task_name,
            "status": model_statuses[model]["status"],
            "result": model_statuses[model]["result"],
            "duration_seconds": duration,
            "session_size_kb": float(model_statuses[model]["session_size"]),
            "timestamp": datetime.now().isoformat(),
            "command": " ".join(cubbix_command)
            if "cubbix_command" in locals()
            else "N/A",
            "test_results": model_statuses[model].get("test_results", []),
        }

        with open(model_dir / "result.json", "w") as f:
            json.dump(result_data, f, indent=2)

        if logger:
            logger.info(
                "Model task completed",
                model=model,
                final_status=model_statuses[model]["status"],
                duration=model_statuses[model]["duration"],
            )


async def update_display(model_statuses, live):
    while True:
        for model in model_statuses:
            if model_statuses[model]["status"] in ["Running", "Testing"]:
                elapsed = time.time() - model_statuses[model]["start_time"]
                model_statuses[model]["duration"] = format_duration(elapsed)

        live.update(create_status_table(model_statuses))
        await asyncio.sleep(0.5)


def generate_summary(run_dir, task_name, model_statuses, logger):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    run_path = run_dir.name

    logger.info(
        "Generating summary", task_name=task_name, total_models=len(model_statuses)
    )

    summary_lines = [
        f"# LLMEval Results - {timestamp}",
        "",
        f"## Task: {task_name}",
        f"**Run Path**: `runs/{run_path}`",
        "",
        "| Model | Duration | Session Size | Status | Result | Tests Passed |",
        "|-------|----------|--------------|--------|--------|--------------|",
    ]

    total_models = len(model_statuses)
    successful = sum(1 for s in model_statuses.values() if s["result"] == "✅ Pass")
    failed_exec = sum(1 for s in model_statuses.values() if s["result"] == "❌ Exec")
    failed_test = sum(1 for s in model_statuses.values() if s["result"] == "❌ Test")
    failed_error = sum(1 for s in model_statuses.values() if s["result"] == "❌ Error")
    total_session_size = sum(float(s["session_size"]) for s in model_statuses.values())

    for model, status in model_statuses.items():
        result_icon = "✅" if status["result"] == "✅ Pass" else "❌"
        result_text = status["result"].replace("✅ ", "").replace("❌ ", "")
        test_results = status.get("test_results", [])
        tests_passed = (
            f"{sum(1 for t in test_results if t['passed'])}/{len(test_results)}"
            if test_results
            else "N/A"
        )
        summary_lines.append(
            f"| {model} | {status['duration']} | {status['session_size']} KB | "
            f"{result_icon} | {result_text} | {tests_passed} |"
        )

    summary_lines.extend(
        [
            "",
            "## Statistics",
            f"- Total models tested: {total_models}",
            f"- Successful: {successful} ({successful / total_models * 100:.0f}%)"
            if total_models > 0
            else "- Successful: 0 (0%)",
            f"- Failed execution: {failed_exec} ({failed_exec / total_models * 100:.0f}%)"
            if total_models > 0
            else "- Failed execution: 0 (0%)",
            f"- Failed tests: {failed_test} ({failed_test / total_models * 100:.0f}%)"
            if total_models > 0
            else "- Failed tests: 0 (0%)",
            f"- Failed errors: {failed_error} ({failed_error / total_models * 100:.0f}%)"
            if total_models > 0
            else "- Failed errors: 0 (0%)",
            f"- Total session data: {total_session_size:.1f} KB",
        ]
    )

    summary_path = run_dir / "summary.md"
    with open(summary_path, "w") as f:
        f.write("\n".join(summary_lines))

    detailed_summary_lines = [
        f"# LLMEval Detailed Results - {task_name}",
        "",
        f"**Run Path**: `runs/{run_path}`",
        f"**Execution Date**: {timestamp}",
        f"**Total Models**: {total_models}",
        f"**Success Rate**: {successful}/{total_models} ({successful / total_models * 100:.1f}%)"
        if total_models > 0
        else "**Success Rate**: 0/0 (0.0%)",
        "",
    ]

    for model, status in model_statuses.items():
        result_icon = "✅" if status["result"] == "✅ Pass" else "❌"
        normalized_model = normalize_model_name(model)
        model_dir = run_dir / normalized_model

        detailed_summary_lines.extend(
            [
                f"## {result_icon} {model}",
                "",
                f"**Status**: {status['status']}",
                f"**Duration**: {status['duration']}",
                f"**Session Size**: {status['session_size']} KB",
                "",
            ]
        )

        session_file = model_dir / "session.txt"
        if session_file.exists():
            detailed_summary_lines.extend(
                [
                    "### Session Output",
                    "",
                    "```",
                ]
            )
            try:
                with open(session_file, "r") as f:
                    session_content = f.read()
                    # Strip ANSI codes and escape markdown code blocks
                    cleaned_content = strip_ansi(session_content)
                    escaped_content = escape_markdown_code_blocks(cleaned_content)
                    detailed_summary_lines.append(escaped_content)
            except Exception:
                detailed_summary_lines.append("Error reading session file")
            detailed_summary_lines.extend(
                [
                    "```",
                    "",
                ]
            )

        test_results = status.get("test_results", [])
        if test_results:
            detailed_summary_lines.extend(
                [
                    "### Test Results",
                    "",
                ]
            )
            for test_result in test_results:
                test_status = "✅ PASSED" if test_result["passed"] else "❌ FAILED"
                detailed_summary_lines.extend(
                    [
                        f"#### {test_result['name']} - {test_status}",
                        "",
                        "```",
                    ]
                )
                test_output_file = model_dir / test_result["output_file"]
                if test_output_file.exists():
                    try:
                        with open(test_output_file, "r") as f:
                            test_content = f.read()
                            # Strip ANSI codes and escape markdown code blocks
                            cleaned_content = strip_ansi(test_content)
                            escaped_content = escape_markdown_code_blocks(
                                cleaned_content
                            )
                            detailed_summary_lines.append(escaped_content)
                    except Exception:
                        detailed_summary_lines.append(
                            f"Error reading {test_result['output_file']}"
                        )
                else:
                    detailed_summary_lines.append(
                        f"Test output file not found: {test_result['output_file']}"
                    )
                detailed_summary_lines.extend(
                    [
                        "```",
                        "",
                    ]
                )

        error_file = model_dir / "error.txt"
        if error_file.exists():
            detailed_summary_lines.extend(
                [
                    "### Error Details",
                    "",
                    "```",
                ]
            )
            try:
                with open(error_file, "r") as f:
                    error_content = f.read()
                    # Strip ANSI codes and escape markdown code blocks
                    cleaned_content = strip_ansi(error_content)
                    escaped_content = escape_markdown_code_blocks(cleaned_content)
                    detailed_summary_lines.append(escaped_content)
            except Exception:
                detailed_summary_lines.append("Error reading error file")
            detailed_summary_lines.extend(
                [
                    "```",
                    "",
                ]
            )

        detailed_summary_lines.append("---")
        detailed_summary_lines.append("")

    detailed_summary_path = run_dir / "summary-detailed.md"
    with open(detailed_summary_path, "w") as f:
        f.write("\n".join(detailed_summary_lines))

    logger.info(
        "Summary generated",
        summary_path=str(summary_path),
        detailed_summary_path=str(detailed_summary_path),
        lines_written=len(summary_lines),
        detailed_lines_written=len(detailed_summary_lines),
    )


async def main():
    parser = argparse.ArgumentParser(description="Evaluate LLM models on tasks")
    parser.add_argument("--model", required=True, help="Comma-separated list of models")
    parser.add_argument("--task", required=True, help="Path to task directory")
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Use structlog instead of Rich console for detailed logging",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=300,
        help="Timeout in seconds for each model task (default: 300)",
    )
    parser.add_argument(
        "--concurrent",
        type=int,
        default=4,
        help="Maximum number of concurrent model tasks (default: 4)",
    )

    args = parser.parse_args()

    logger = setup_logging(args.verbose)

    models = [m.strip() for m in args.model.split(",")]
    task_dir = Path(args.task)

    if not task_dir.exists():
        logger.error("Task directory does not exist", task_dir=str(task_dir))
        sys.exit(1)

    if not (task_dir / "task.md").exists():
        logger.error("task.md not found in task directory", task_dir=str(task_dir))
        sys.exit(1)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = Path(RUNS_DIR) / f"run_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    logger.info(
        "Starting LLMEval run",
        models=models,
        task_dir=str(task_dir),
        run_dir=str(run_dir),
        verbose_mode=args.verbose,
        max_concurrent=args.concurrent,
        timeout_seconds=args.timeout,
    )

    model_statuses = {}
    for model in models:
        model_statuses[model] = {
            "status": "Pending",
            "duration": "0s",
            "session_size": "0.0",
            "result": "-",
            "start_time": 0,
            "test_results": [],
        }

    # Create semaphore to limit concurrent tasks
    semaphore = asyncio.Semaphore(args.concurrent)

    if args.verbose:
        model_tasks = [
            execute_model_task(
                model,
                task_dir,
                run_dir,
                model_statuses,
                semaphore,
                logger,
                True,
                args.timeout,
            )
            for model in models
        ]

        results = await asyncio.gather(*model_tasks, return_exceptions=True)

        # Log any exceptions that occurred
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(f"Task for model {models[i]} failed", error=str(result))

        logger.info("All model tasks completed")
    else:
        logger.info("Starting Rich console mode")
        with Live(create_status_table(model_statuses), refresh_per_second=2) as live:
            display_task = asyncio.create_task(update_display(model_statuses, live))

            model_tasks = [
                execute_model_task(
                    model,
                    task_dir,
                    run_dir,
                    model_statuses,
                    semaphore,
                    logger,
                    False,
                    args.timeout,
                )
                for model in models
            ]

            results = await asyncio.gather(*model_tasks, return_exceptions=True)

            # Log any exceptions that occurred
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    logger.error(
                        f"Task for model {models[i]} failed", error=str(result)
                    )

            display_task.cancel()

            live.update(create_status_table(model_statuses))

    generate_summary(run_dir, task_dir.name, model_statuses, logger)

    logger.info(
        "Run completed", run_dir=str(run_dir), summary_path=str(run_dir / "summary.md")
    )


if __name__ == "__main__":
    asyncio.run(main())
