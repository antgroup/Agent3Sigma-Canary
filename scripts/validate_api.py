#!/usr/bin/env python3
"""Validate model API settings from config.yaml with a tiny LLM request."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib import error, request

import yaml


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG_PATH = PROJECT_ROOT / "config.yaml"
SUPPORTED_PROVIDER_APIS = {"openai-completions", "anthropic-messages"}


@dataclass(frozen=True)
class ApiTarget:
    label: str
    base_url: str
    api_key: str
    model: str
    api: str
    effort: str | None = None


def _load_config(config_path: Path) -> dict[str, Any]:
    if not config_path.exists():
        raise FileNotFoundError(
            f"config.yaml not found at {config_path}. Run: cp config.example.yaml config.yaml"
        )

    with open(config_path, encoding="utf-8") as f:
        cfg = yaml.safe_load(f) or {}

    if not isinstance(cfg, dict):
        raise ValueError("config.yaml must contain a YAML mapping at the top level")

    return cfg


def _collect_provider_targets(cfg: dict[str, Any]) -> tuple[list[ApiTarget], list[str]]:
    targets: list[ApiTarget] = []
    errors: list[str] = []

    providers = cfg.get("providers") or {}
    if not isinstance(providers, dict):
        return targets, ["providers must be a mapping"]

    for provider_id, provider in providers.items():
        if not isinstance(provider, dict):
            errors.append(f"providers.{provider_id} must be a mapping")
            continue

        provider_api = provider.get("api", "openai-completions")
        models = provider.get("models") or []
        if not isinstance(models, list):
            errors.append(f"providers.{provider_id}.models must be a list")
            continue

        for index, model in enumerate(models):
            if not isinstance(model, dict):
                errors.append(f"providers.{provider_id}.models[{index}] must be a mapping")
                continue

            model_id = str(model.get("id") or "")
            api = str(model.get("api") or provider_api or "openai-completions")
            label_suffix = model_id or f"models[{index}]"
            targets.append(
                ApiTarget(
                    label=f"providers.{provider_id}.{label_suffix}",
                    base_url=str(provider.get("base_url") or ""),
                    api_key=str(provider.get("api_key") or ""),
                    model=model_id,
                    api=api,
                    effort=None,
                )
            )

    return targets, errors


def _collect_role_targets(cfg: dict[str, Any]) -> tuple[list[ApiTarget], list[str]]:
    targets: list[ApiTarget] = []
    errors: list[str] = []

    roles = cfg.get("roles") or {}
    if not isinstance(roles, dict):
        return targets, ["roles must be a mapping"]

    for role_name in sorted(roles):
        role = roles[role_name]
        if role is None:
            continue
        if not isinstance(role, dict):
            errors.append(f"roles.{role_name} must be a mapping")
            continue

        targets.append(
            ApiTarget(
                label=f"roles.{role_name}",
                base_url=str(role.get("base_url") or ""),
                api_key=str(role.get("api_key") or ""),
                model=str(role.get("model") or ""),
                api="openai-completions",
                effort=(
                    str(role["effort"])
                    if role_name == "judge" and role.get("effort") is not None
                    else None
                ),
            )
        )

    return targets, errors


def _join_endpoint(base_url: str, suffix: str) -> str:
    base = base_url.rstrip("/")
    suffix = suffix.strip("/")
    if base.endswith(f"/{suffix}"):
        return base
    return f"{base}/{suffix}"


def _join_anthropic_messages_endpoint(base_url: str) -> str:
    base = base_url.rstrip("/")
    if base.endswith("/messages"):
        return base
    if base.endswith("/v1"):
        return f"{base}/messages"
    return f"{base}/v1/messages"


def _post_json(
    url: str,
    payload: dict[str, Any],
    headers: dict[str, str],
    timeout_seconds: float,
) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(url, data=data, headers=headers, method="POST")

    try:
        with request.urlopen(req, timeout=timeout_seconds) as resp:
            raw = resp.read().decode("utf-8")
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"HTTP {exc.code} {exc.reason}: {body}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"Connection error: {exc.reason}") from exc

    try:
        decoded = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON response: {raw[:500]}") from exc

    if not isinstance(decoded, dict):
        raise RuntimeError("JSON response is not an object")

    return decoded


def _extract_openai_text(response: dict[str, Any]) -> str:
    choices = response.get("choices") or []
    if not choices or not isinstance(choices[0], dict):
        return ""

    first = choices[0]
    message = first.get("message")
    if isinstance(message, dict):
        content = message.get("content")
        if isinstance(content, str):
            return content.strip()
        if isinstance(content, list):
            parts = [
                block.get("text", "")
                for block in content
                if isinstance(block, dict) and block.get("type") == "text"
            ]
            return "\n".join(parts).strip()

    text = first.get("text")
    return text.strip() if isinstance(text, str) else ""


def _extract_anthropic_text(response: dict[str, Any]) -> str:
    content = response.get("content") or []
    if not isinstance(content, list):
        return ""

    parts = [
        block.get("text", "")
        for block in content
        if isinstance(block, dict) and block.get("type") == "text"
    ]
    return "\n".join(parts).strip()


def _call_openai_compatible(
    target: ApiTarget,
    prompt: str,
    timeout_seconds: float,
    max_tokens: int,
) -> str:
    payload: dict[str, Any] = {
        "model": target.model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
    }
    if target.effort:
        payload["reasoning_effort"] = target.effort

    response = _post_json(
        url=_join_endpoint(target.base_url, "chat/completions"),
        payload=payload,
        headers={
            "Authorization": f"Bearer {target.api_key}",
            "Content-Type": "application/json",
        },
        timeout_seconds=timeout_seconds,
    )
    return _extract_openai_text(response)


def _call_anthropic_messages(
    target: ApiTarget,
    prompt: str,
    timeout_seconds: float,
    max_tokens: int,
) -> str:
    response = _post_json(
        url=_join_anthropic_messages_endpoint(target.base_url),
        payload={
            "model": target.model,
            "max_tokens": max_tokens,
            "messages": [{"role": "user", "content": prompt}],
        },
        headers={
            "x-api-key": target.api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        },
        timeout_seconds=timeout_seconds,
    )
    return _extract_anthropic_text(response)


def _validate_target(
    target: ApiTarget,
    prompt: str,
    timeout_seconds: float,
    max_tokens: int,
) -> str:
    missing = [
        field
        for field, value in (
            ("base_url", target.base_url),
            ("api_key", target.api_key),
            ("model", target.model),
        )
        if not value
    ]
    if missing:
        raise RuntimeError(f"missing required field(s): {', '.join(missing)}")

    if target.api not in SUPPORTED_PROVIDER_APIS:
        raise RuntimeError(
            f"unsupported api '{target.api}'. Supported: "
            f"{', '.join(sorted(SUPPORTED_PROVIDER_APIS))}"
        )

    if target.api == "anthropic-messages":
        text = _call_anthropic_messages(target, prompt, timeout_seconds, max_tokens)
    else:
        text = _call_openai_compatible(target, prompt, timeout_seconds, max_tokens)

    if not text:
        raise RuntimeError("API call succeeded but returned no assistant text")

    return text


def _preview(text: str, limit: int = 120) -> str:
    compact = " ".join(text.split())
    if len(compact) <= limit:
        return compact
    return f"{compact[:limit - 3]}..."


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate model APIs in config.yaml by sending a 'hello' request."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Path to config.yaml",
    )
    parser.add_argument(
        "--scope",
        choices=["all", "providers", "roles"],
        default="all",
        help="Which config section to validate",
    )
    parser.add_argument(
        "--prompt",
        default="hello",
        help="Prompt sent to each model",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="Per-request timeout in seconds",
    )
    parser.add_argument(
        "--max-tokens",
        type=int,
        default=25600,
        help="Maximum output tokens for each validation request",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()

    try:
        cfg = _load_config(args.config)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1

    targets: list[ApiTarget] = []
    config_errors: list[str] = []

    if args.scope in ("all", "providers"):
        provider_targets, provider_errors = _collect_provider_targets(cfg)
        targets.extend(provider_targets)
        config_errors.extend(provider_errors)

    if args.scope in ("all", "roles"):
        role_targets, role_errors = _collect_role_targets(cfg)
        targets.extend(role_targets)
        config_errors.extend(role_errors)

    print(f"[INFO] Loaded config: {args.config}")
    print(f"[INFO] Validating {len(targets)} API target(s)")

    passed = 0
    failed = len(config_errors)

    for message in config_errors:
        print(f"[FAIL] config: {message}")

    for index, target in enumerate(targets, start=1):
        print(f"[{index}/{len(targets)}] {target.label}")
        effort_suffix = f" effort={target.effort}" if target.effort else ""
        print(
            f"      api={target.api} model={target.model} "
            f"base_url={target.base_url}{effort_suffix}"
        )
        try:
            text = _validate_target(
                target=target,
                prompt=args.prompt,
                timeout_seconds=args.timeout,
                max_tokens=args.max_tokens,
            )
        except Exception as exc:
            failed += 1
            print(f"      [FAIL] {exc}")
        else:
            passed += 1
            print(f"      [OK] {_preview(text)}")

    print("")
    print(f"[SUMMARY] passed={passed} failed={failed} total={passed + failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
