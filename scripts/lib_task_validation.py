"""Check task inputs and toolset requirements before starting agents or containers."""

from pathlib import Path
import re

from lib_tasks import Task


def validate_task_toolsets(tasks: list[Task], image: str, *, docker_mode: bool,
                          check_runtime: bool = True) -> None:
    """Validate optional requirements; only declared toolsets constrain the runtime."""
    required = []
    for task in tasks:
        value = task.frontmatter.get("required_toolset")
        if value is None:
            continue
        if not isinstance(value, str):
            raise ValueError(f"{task.task_id}: required_toolset must be a string or empty")
        value = value.strip()
        if not value:
            continue
        if value != "safety_research":
            raise ValueError(f"{task.task_id}: unknown required_toolset {value!r}; expected 'safety_research' or empty")
        required.append(task.task_id)
    if not required or not check_runtime:
        return

    context = (f"{len(required)} task(s) require required_toolset: safety_research "
               f"(e.g. {', '.join(required[:3])}). ")
    hint = ("Build an image with bash workflow/workflow_step_1_image_builder.sh --safety-research, "
            "then set DOCKER_IMAGE to the resulting image name containing '-safety_research'.")
    if not docker_mode:
        raise ValueError(context + "Run with --docker so the required image can be verified. " + hint)

    # Match the image's final repository component or tag, excluding registry/
    # namespace prefixes and digests. Accept both current and legacy separators.
    name = (image or "").rsplit("/", 1)[-1].split("@", 1)[0]
    if not re.search(r"(?:^|[-_.:])safety_research(?:$|[-_.:])", name):
        raise ValueError(context + f"DOCKER_IMAGE={image!r} does not identify the required toolset. " + hint)


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
