"""Check task input files without starting agents, containers, or model calls."""

from pathlib import Path

from lib_tasks import Task


def memory_context_path(context: str, project: Path) -> Path | None:
    """NARA context accepts either a file path or inline multiline memory."""
    return None if "\n" in context else project / context


def missing_task_inputs(tasks: list[Task], project: Path) -> dict[str, list[str]]:
    missing = {}
    for task in tasks:
        paths = []
        for spec in task.workspace_files:
            if isinstance(spec, dict) and "content" not in spec and spec.get("source"):
                paths.append(project / "assets" / spec["source"])
        for step in task.frontmatter.get("pre_setup", []) or []:
            if not isinstance(step, dict):
                continue
            kind = step.get("type")
            if kind == "memory" and step.get("context"):
                path = memory_context_path(step["context"], project)
                if path is not None:
                    paths.append(path)
            elif kind == "seed_history" and step.get("path"):
                paths.append(project / step["path"])
        absent = sorted({str(path) for path in paths if not path.is_file()})
        if absent:
            missing[str(task.file_path or task.task_id)] = absent
    return missing
