#!/usr/bin/env python3
"""OpenSearch operations helper backed by a local JSON state file."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


STATE_PATH = Path(os.environ.get("OPENSEARCH_OPS_STATE", "/tmp/opensearch_ops_state.json"))


def load_state() -> dict:
    if STATE_PATH.is_file():
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    return {
        "cluster_name": "local-opensearch",
        "status": "green",
        "version": "2.18.0",
        "indices": {},
    }


def save_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def emit(data: dict | list, pretty: bool = True) -> None:
    if pretty:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(data, separators=(",", ":"), ensure_ascii=False))


def cmd_status(args: argparse.Namespace) -> None:
    del args
    state = load_state()
    emit(
        {
            "cluster_name": state["cluster_name"],
            "status": state["status"],
            "version": state["version"],
            "indices": sorted(state["indices"].keys()),
        }
    )


def cmd_load_sample(args: argparse.Namespace) -> None:
    state = load_state()
    index = args.index or "movies"
    docs = [
        {"_id": "movie-1", "_source": {"title": "Search in Practice", "description": "BM25 and vector retrieval"}},
        {"_id": "movie-2", "_source": {"title": "Logs at Scale", "description": "timeout and error analysis"}},
    ]
    state["indices"].setdefault(index, {"mappings": {}, "documents": {}})
    for doc in docs:
        state["indices"][index]["documents"][doc["_id"]] = doc["_source"]
    save_state(state)
    emit({"index": index, "loaded": len(docs), "source_type": args.type, "source": args.value or "builtin_imdb"})


def cmd_create_index(args: argparse.Namespace) -> None:
    state = load_state()
    body = json.loads(args.body) if args.body else {}
    if args.replace or args.name not in state["indices"]:
        state["indices"][args.name] = {"mappings": body.get("mappings", {}), "settings": body.get("settings", {}), "documents": {}}
    save_state(state)
    emit({"acknowledged": True, "index": args.name, "shards_acknowledged": True})


def cmd_index_doc(args: argparse.Namespace) -> None:
    state = load_state()
    if args.index not in state["indices"]:
        state["indices"][args.index] = {"mappings": {}, "settings": {}, "documents": {}}
    doc = json.loads(args.doc)
    state["indices"][args.index]["documents"][args.id] = doc
    save_state(state)
    emit({"_index": args.index, "_id": args.id, "result": "created", "_version": 1})


def cmd_index_bulk(args: argparse.Namespace) -> None:
    state = load_state()
    if args.index not in state["indices"]:
        state["indices"][args.index] = {"mappings": {}, "settings": {}, "documents": {}}
    count = args.count or 2
    for i in range(1, count + 1):
        state["indices"][args.index]["documents"][f"bulk-{i}"] = {"title": f"Bulk document {i}", "body": "bulk import"}
    save_state(state)
    emit({"index": args.index, "items_indexed": count, "errors": False})


def cmd_search(args: argparse.Namespace) -> None:
    state = load_state()
    body = json.loads(args.body) if args.body else {}
    query_text = json.dumps(body).lower()
    docs = state["indices"].get(args.index, {}).get("documents", {})
    hits = []
    for doc_id, doc in docs.items():
        haystack = json.dumps(doc, ensure_ascii=False).lower()
        score = 1.0 if any(token in haystack for token in query_text.replace('"', " ").split()) else 0.1
        if score >= 1.0 or not hits:
            hits.append({"_index": args.index, "_id": doc_id, "_score": score, "_source": doc})
    hits = hits[: args.size]
    emit({"hits": {"total": {"value": len(hits), "relation": "eq"}, "hits": hits}})


def cmd_create_pipeline(args: argparse.Namespace) -> None:
    emit({"acknowledged": True, "pipeline": args.name, "index": args.index, "type": args.type})


def cmd_read_knowledge(args: argparse.Namespace) -> None:
    topics = {
        "dense_vector_models.md": "Dense vector search stores embeddings and retrieves nearest neighbours with k-NN.",
        "sparse_vector_models.md": "Sparse vectors support lexical-semantic matching with term expansion.",
        "opensearch_semantic_search_guide.md": "Semantic search combines model deployment, ingest pipelines, and neural queries.",
        "agentic_search_guide.md": "Agentic search routes a query through an agent and a search pipeline.",
        "evaluation_guide.md": "Evaluate search with labelled queries, relevance judgements, and side-by-side comparison.",
    }
    print(topics.get(args.file, f"No local knowledge entry for {args.file}"))


def cmd_launch_ui(args: argparse.Namespace) -> None:
    emit({"status": "running", "url": "http://127.0.0.1:8765", "index": args.index})


def cmd_cleanup(args: argparse.Namespace) -> None:
    del args
    if STATE_PATH.exists():
        STATE_PATH.unlink()
    emit({"status": "ok", "removed_state": str(STATE_PATH)})


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="OpenSearch operations helper")
    parser.add_argument("--version", action="version", version="2.0.0")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("status", help="Check connectivity").set_defaults(func=cmd_status)

    p_load = subparsers.add_parser("load-sample", help="Load sample data")
    p_load.add_argument("--type", default="builtin_imdb")
    p_load.add_argument("--value")
    p_load.add_argument("--index")
    p_load.set_defaults(func=cmd_load_sample)

    p_create = subparsers.add_parser("create-index", help="Create an index")
    p_create.add_argument("--name", required=True)
    p_create.add_argument("--body", default="{}")
    p_create.add_argument("--replace", dest="replace", action="store_true", default=True)
    p_create.add_argument("--no-replace", dest="replace", action="store_false")
    p_create.set_defaults(func=cmd_create_index)

    p_pipeline = subparsers.add_parser("create-pipeline", help="Create a pipeline")
    p_pipeline.add_argument("--name", required=True)
    p_pipeline.add_argument("--index", required=True)
    p_pipeline.add_argument("--type", default="ingest")
    p_pipeline.add_argument("--body", default="{}")
    p_pipeline.add_argument("--hybrid", action="store_true")
    p_pipeline.add_argument("--weights")
    p_pipeline.set_defaults(func=cmd_create_pipeline)

    p_doc = subparsers.add_parser("index-doc", help="Index a document")
    p_doc.add_argument("--index", required=True)
    p_doc.add_argument("--id", required=True)
    p_doc.add_argument("--doc", required=True)
    p_doc.set_defaults(func=cmd_index_doc)

    p_bulk = subparsers.add_parser("index-bulk", help="Bulk index documents")
    p_bulk.add_argument("--index", required=True)
    p_bulk.add_argument("--source-file")
    p_bulk.add_argument("--count", type=int, default=2)
    p_bulk.set_defaults(func=cmd_index_bulk)

    p_search = subparsers.add_parser("search", help="Search an index")
    p_search.add_argument("--index", required=True)
    p_search.add_argument("--body", default="{}")
    p_search.add_argument("--size", type=int, default=10)
    p_search.set_defaults(func=cmd_search)

    p_read = subparsers.add_parser("read-knowledge", help="Read bundled knowledge")
    p_read.add_argument("--file", required=True)
    p_read.set_defaults(func=cmd_read_knowledge)

    p_ui = subparsers.add_parser("launch-ui", help="Launch Search Builder UI")
    p_ui.add_argument("--index", required=True)
    p_ui.set_defaults(func=cmd_launch_ui)

    subparsers.add_parser("cleanup", help="Remove local state").set_defaults(func=cmd_cleanup)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
