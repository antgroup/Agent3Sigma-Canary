#!/usr/bin/env python3
"""PII scrubber which prefers Presidio's Python packages, then local rules."""

from __future__ import annotations

import json
import os
import re
import stat
import sys
import time
from pathlib import Path
from typing import Any, Iterable, Iterator, Tuple


SKILL_DIR = Path(__file__).resolve().parent.parent
MAPPING_DIR = Path(
    os.environ.get(
        "PRESIDIO_MAPPING_DIR",
        os.path.expanduser("~/.openclaw/presidio/mappings"),
    )
)
LANGUAGE = os.environ.get("PRESIDIO_LANGUAGE", "en")
PRESIDIO_SCORE_THRESHOLD = float(os.environ.get("PRESIDIO_SCORE_THRESHOLD", "0.35"))

LOCAL_PATTERNS = [
    (
        "EMAIL_ADDRESS",
        r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b",
        re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
        0.95,
    ),
    (
        "PHONE_NUMBER",
        r"(?<!\d)(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)\d{3}[-.\s]?\d{4}(?!\d)",
        re.compile(r"(?<!\d)(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)\d{3}[-.\s]?\d{4}(?!\d)"),
        0.95,
    ),
    (
        "CREDIT_CARD",
        r"(?<!\d)(?:\d[ -]*?){13,19}(?!\d)",
        re.compile(r"(?<!\d)(?:\d[ -]*?){13,19}(?!\d)"),
        0.95,
    ),
    (
        "US_SSN",
        r"\b\d{3}-\d{2}-\d{4}\b",
        re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
        0.95,
    ),
    (
        "IP_ADDRESS",
        r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
        re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b"),
        0.95,
    ),
    (
        "PERSON",
        r"\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2}\b",
        re.compile(r"\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2}\b"),
        0.80,
    ),
]

SAFE_PERSON_PHRASES = {
    "Customer Support",
    "Mock API",
    "Presidio PII",
}

SKIPPED_PRESIDIO_TYPES = {"URL"}


def _read_text(argv: list[str]) -> tuple[str, str]:
    session_id = argv[1] if len(argv) > 1 else str(int(time.time()))
    if len(argv) > 2:
        text = " ".join(argv[2:])
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
    else:
        print(json.dumps({"error": "No input text"}))
        raise SystemExit(1)
    return session_id, text


def _luhn_ok(value: str) -> bool:
    digits = [int(ch) for ch in re.sub(r"\D", "", value)]
    if len(digits) < 13:
        return False
    checksum = 0
    parity = len(digits) % 2
    for idx, digit in enumerate(digits):
        if idx % 2 == parity:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit
    return checksum % 10 == 0


def _span(entity: Any) -> tuple[int, int]:
    if isinstance(entity, dict):
        return int(entity["start"]), int(entity["end"])
    return int(entity.start), int(entity.end)


def _entity_type(entity: Any) -> str:
    if isinstance(entity, dict):
        return str(entity["entity_type"])
    return str(entity.entity_type)


def _score(entity: Any) -> float:
    if isinstance(entity, dict):
        return float(entity.get("score", 0.0))
    return float(getattr(entity, "score", 0.0))


def _overlaps(a: tuple[int, int], b: tuple[int, int]) -> bool:
    return a[0] < b[1] and a[1] > b[0]


def _valid_entity(entity_type: str, value: str) -> bool:
    if entity_type in SKIPPED_PRESIDIO_TYPES:
        return False
    if entity_type == "CREDIT_CARD" and not _luhn_ok(value):
        return False
    if entity_type == "IP_ADDRESS" and re.fullmatch(r"(?:\d{1,3}\.){3}\d{1,3}", value):
        if any(int(part) > 255 for part in value.split(".")):
            return False
    if entity_type == "PERSON" and value in SAFE_PERSON_PHRASES:
        return False
    return True


def _resolve_overlaps(entities: list[Any]) -> list[Any]:
    ranked = sorted(entities, key=lambda e: (-_score(e), -(_span(e)[1] - _span(e)[0])))
    kept: list[Any] = []
    for entity in ranked:
        entity_span = _span(entity)
        if any(_overlaps(entity_span, _span(k)) for k in kept):
            continue
        kept.append(entity)
    return sorted(kept, key=lambda e: _span(e)[0])


def _load_recognizer_config() -> dict[str, Any]:
    config_path = SKILL_DIR / "configs" / "recognizers.json"
    if not config_path.is_file():
        return {}
    try:
        return json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _allowlist_spans(text: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    config = _load_recognizer_config()
    for recognizer in config.get("ad_hoc_recognizers", []):
        for pattern in recognizer.get("patterns", []):
            try:
                score = float(pattern.get("score", 0.0))
                regex_text = pattern["regex"]
            except (KeyError, TypeError, ValueError):
                continue
            if score > 0:
                continue
            try:
                compiled = re.compile(regex_text, re.IGNORECASE | re.MULTILINE | re.DOTALL)
            except re.error:
                continue
            spans.extend((match.start(), match.end()) for match in compiled.finditer(text))
    return spans


def _filter_entities(text: str, entities: list[Any]) -> list[Any]:
    allow_spans = _allowlist_spans(text)
    filtered: list[Any] = []
    for entity in entities:
        start, end = _span(entity)
        if start < 0 or end > len(text) or start >= end:
            continue
        value = text[start:end]
        if any(_overlaps((start, end), allow_span) for allow_span in allow_spans):
            continue
        if not _valid_entity(_entity_type(entity), value):
            continue
        filtered.append(entity)
    return _resolve_overlaps(filtered)


def _find_local_entities(text: str) -> list[dict[str, Any]]:
    found: list[dict[str, Any]] = []
    for entity_type, _regex_text, pattern, score in LOCAL_PATTERNS:
        for match in pattern.finditer(text):
            value = match.group(0)
            if not _valid_entity(entity_type, value):
                continue
            found.append(
                {
                    "entity_type": entity_type,
                    "start": match.start(),
                    "end": match.end(),
                    "score": score,
                }
            )
    return _filter_entities(text, found)


def _noop_nlp_engine_class(nlp_engine_base: Any, nlp_artifacts_cls: Any) -> type:
    class NoOpNlpEngine(nlp_engine_base):
        def load(self) -> None:
            return None

        def is_loaded(self) -> bool:
            return True

        def process_text(self, text: str, language: str) -> Any:
            return nlp_artifacts_cls([], [], [], [], self, language)

        def process_batch(
            self,
            texts: Iterable[str],
            language: str,
            batch_size: int = 1,
            n_process: int = 1,
            **kwargs: Any,
        ) -> Iterator[Tuple[str, Any]]:
            for text in texts:
                yield text, self.process_text(text, language)

        def is_stopword(self, word: str, language: str) -> bool:
            return False

        def is_punct(self, word: str, language: str) -> bool:
            return False

        def get_supported_entities(self) -> list[str]:
            return []

        def get_supported_languages(self) -> list[str]:
            return [LANGUAGE]

    return NoOpNlpEngine


def _presidio_recognizers(pattern_cls: Any, recognizer_cls: Any) -> list[Any]:
    recognizers: list[Any] = []
    for entity_type, regex_text, _pattern, score in LOCAL_PATTERNS:
        recognizers.append(
            recognizer_cls(
                supported_entity=entity_type,
                name=f"Local{entity_type.title().replace('_', '')}Recognizer",
                supported_language=LANGUAGE,
                patterns=[
                    pattern_cls(
                        name=f"local_{entity_type.lower()}",
                        regex=regex_text,
                        score=score,
                    )
                ],
                global_regex_flags=re.MULTILINE | re.DOTALL,
            )
        )

    config = _load_recognizer_config()
    for item in config.get("ad_hoc_recognizers", []):
        entity_type = item.get("supported_entity")
        if not entity_type:
            continue
        patterns = []
        for pattern in item.get("patterns", []):
            try:
                score = float(pattern.get("score", 0.0))
                if score <= 0:
                    continue
                patterns.append(
                    pattern_cls(
                        name=str(pattern.get("name", entity_type)),
                        regex=str(pattern["regex"]),
                        score=score,
                    )
                )
            except (KeyError, TypeError, ValueError):
                continue
        if not patterns:
            continue
        recognizers.append(
            recognizer_cls(
                supported_entity=str(entity_type),
                name=str(item.get("name", f"{entity_type}Recognizer")),
                supported_language=str(item.get("supported_language", LANGUAGE)),
                patterns=patterns,
            )
        )
    return recognizers


def _build_token_maps(text: str, entities: list[Any]) -> tuple[dict[str, str], dict[str, str], dict[str, int]]:
    type_counters: dict[str, int] = {}
    token_map: dict[str, str] = {}
    reverse_map: dict[str, str] = {}
    for entity in sorted(entities, key=lambda e: _span(e)[0]):
        start, end = _span(entity)
        original = text[start:end]
        if original in token_map:
            continue
        entity_type = _entity_type(entity)
        type_counters[entity_type] = type_counters.get(entity_type, 0) + 1
        token = f"[{entity_type}_{type_counters[entity_type]}]"
        token_map[original] = token
        reverse_map[token] = original
    return token_map, reverse_map, type_counters


def _manual_anonymize(text: str, entities: list[Any]) -> dict[str, Any]:
    token_map, reverse_map, type_counters = _build_token_maps(text, entities)
    anonymized = text
    for entity in sorted(entities, key=lambda e: e["start"], reverse=True):
        start, end = _span(entity)
        original = text[start:end]
        token = token_map.get(original)
        if token:
            anonymized = anonymized[:start] + token + anonymized[end:]
    return {
        "text": anonymized,
        "reverse_map": reverse_map,
        "entity_count": len(entities),
        "entity_types": list(type_counters.keys()),
        "engine": "local-rules",
    }


def _presidio_anonymize(
    text: str,
    entities: list[Any],
    anonymizer_cls: Any,
    operator_config_cls: Any,
) -> dict[str, Any]:
    token_map, reverse_map, type_counters = _build_token_maps(text, entities)

    def replace_value(value: str) -> str:
        return token_map.get(value, value)

    anonymized = anonymizer_cls().anonymize(
        text=text,
        analyzer_results=entities,
        operators={
            "DEFAULT": operator_config_cls(
                "custom",
                {"lambda": replace_value},
            )
        },
    )
    return {
        "text": anonymized.text,
        "reverse_map": reverse_map,
        "entity_count": len(entities),
        "entity_types": list(type_counters.keys()),
        "engine": "presidio-python",
    }


def _find_with_presidio(text: str) -> tuple[dict[str, Any] | None, str | None]:
    if os.environ.get("PRESIDIO_PII_FORCE_LOCAL"):
        return None, "PRESIDIO_PII_FORCE_LOCAL is set"

    try:
        from presidio_analyzer import AnalyzerEngine, Pattern, PatternRecognizer, RecognizerRegistry
        from presidio_analyzer.nlp_engine import NlpArtifacts, NlpEngine
        from presidio_anonymizer import AnonymizerEngine
        from presidio_anonymizer.entities import OperatorConfig
    except Exception as exc:
        return None, f"presidio import failed: {type(exc).__name__}: {exc}"

    try:
        nlp_engine = _noop_nlp_engine_class(NlpEngine, NlpArtifacts)()
        registry = RecognizerRegistry(supported_languages=[LANGUAGE])
        registry.load_predefined_recognizers(
            languages=[LANGUAGE],
            nlp_engine=nlp_engine,
        )
        analyzer = AnalyzerEngine(
            registry=registry,
            nlp_engine=nlp_engine,
            supported_languages=[LANGUAGE],
        )
        entities = analyzer.analyze(
            text=text,
            language=LANGUAGE,
            score_threshold=PRESIDIO_SCORE_THRESHOLD,
            ad_hoc_recognizers=_presidio_recognizers(Pattern, PatternRecognizer),
        )
        entities = _filter_entities(text, entities)
        if not entities:
            return None, "presidio returned no supported entities"
        return _presidio_anonymize(text, entities, AnonymizerEngine, OperatorConfig), None
    except Exception as exc:
        return None, f"presidio execution failed: {type(exc).__name__}: {exc}"


def _emit_no_pii(session_id: str, text: str, engine: str, fallback_reason: str | None) -> None:
    payload: dict[str, Any] = {
        "text": text,
        "pii_found": 0,
        "mapping_file": None,
        "session_id": session_id,
        "engine": engine,
    }
    if fallback_reason:
        payload["fallback_reason"] = fallback_reason
    print(json.dumps(payload, indent=2))


def _emit_mapping(session_id: str, payload: dict[str, Any], fallback_reason: str | None) -> None:
    reverse_map = payload["reverse_map"]
    entity_types = payload["entity_types"]
    entity_count = int(payload["entity_count"])

    MAPPING_DIR.mkdir(parents=True, exist_ok=True)
    mapping_file = MAPPING_DIR / f"{session_id}.json"
    mapping_file.write_text(
        json.dumps(
            {
                "session_id": session_id,
                "created": int(time.time()),
                "reverse_map": reverse_map,
                "entity_count": entity_count,
                "entity_types": entity_types,
                "engine": payload["engine"],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    mapping_file.chmod(stat.S_IRUSR | stat.S_IWUSR)

    print(
        json.dumps(
            {
                "text": payload["text"],
                "pii_found": entity_count,
                "entity_types": entity_types,
                "mapping_file": str(mapping_file),
                "session_id": session_id,
                "engine": payload["engine"],
                **({"fallback_reason": fallback_reason} if fallback_reason else {}),
            },
            indent=2,
        )
    )


def main() -> None:
    session_id, text = _read_text(sys.argv)
    payload, fallback_reason = _find_with_presidio(text)
    if payload is None:
        local_entities = _find_local_entities(text)
        if not local_entities:
            _emit_no_pii(session_id, text, "local-rules", fallback_reason)
            return
        payload = _manual_anonymize(text, local_entities)

    if int(payload["entity_count"]) == 0:
        _emit_no_pii(session_id, text, str(payload["engine"]), fallback_reason)
        return
    _emit_mapping(session_id, payload, fallback_reason)


if __name__ == "__main__":
    main()
