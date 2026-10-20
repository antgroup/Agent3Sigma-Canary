"""NARA-Bench page routes, APIs and private indexes."""
import json
from hashlib import sha256
from flask import Blueprint, jsonify, request
from app.core.web import render_site
from .tasks import DATA, TaskIndex
from .results import ResultIndex
from .markdown_content import MarkdownContent
from .trajectories import TrajectoryIndex

SECTIONS = {'introduction', 'overview', 'leaderboard', 'benchmark'}

def register(app):
    bp = Blueprint('nara_bench', __name__)
    task_index = TaskIndex()
    result_index = ResultIndex()
    markdown_content = MarkdownContent()
    trajectory_index = TrajectoryIndex()
    app.extensions['benchmark/nara-bench'] = dict(tasks=task_index, results=result_index,
                                                 content=markdown_content, trajectories=trajectory_index)

    @bp.get('/benchmark/nara-bench')
    @bp.get('/benchmark/nara-bench/<section>')
    def benchmark_page(section=None):
        return render_site(200 if section is None or section in SECTIONS else 404)

    @bp.get('/api/benchmark/nara-bench/config')
    def config():
        return jsonify(json.loads((DATA / 'benchmark.json').read_text(encoding='utf-8')))

    @bp.get("/benchmark/nara-bench/benchmark/<task_name>")
    @bp.get("/benchmark/nara-bench/benchmark/<task_name>/<section>")
    def task_detail_page(task_name, section="content"):
        valid = "task_" + task_name in task_index.by_id and section in {"content", "results", "trajectory"}
        return render_site(200 if valid else 404)

    @bp.get("/api/nara-bench/tasks/<task_id>")
    def task_detail(task_id):
        task = task_index.by_id.get(task_id)
        if task is None:
            return jsonify(error="Task not found."), 404
        response = jsonify(task=task, content_html=markdown_content.render(task_index.sources[task_id]),
                           results=result_index.for_task(task_id))
        response.headers["Cache-Control"] = "private, no-cache"
        response.set_etag(sha256(response.get_data()).hexdigest())
        return response.make_conditional(request)

    @bp.get("/api/nara-bench/tasks/<task_id>/trajectory")
    def task_trajectory(task_id):
        if task_id not in task_index.by_id:
            return jsonify(error="Task not found."), 404
        try:
            offset = int(request.args.get("offset", "0"))
            limit = int(request.args.get("limit", "40"))
            if offset < 0 or not 1 <= limit <= 100:
                raise ValueError
        except ValueError:
            return jsonify(error="offset must be non-negative and limit must be between 1 and 100."), 400
        data = trajectory_index.for_task(task_id, offset, limit)
        if data is None:
            return jsonify(error="Trajectory not found."), 404
        data['llm'] = {'id':'claude-fable-5-1', **result_index.icons['models']['claude-fable-5-1']}
        data['harness'] = {'id':'ClaudeCode', **result_index.icons['harnesses']['ClaudeCode']}
        response = jsonify(data)
        response.headers['Cache-Control'] = 'private, no-cache'
        response.set_etag(sha256(response.get_data()).hexdigest())
        return response.make_conditional(request)

    @bp.get("/api/nara-bench/tasks")
    def task_collection():
        try:
            page = max(1, int(request.args.get("page", "1")))
            page_size = min(96, max(1, int(request.args.get("page_size", "24"))))
        except ValueError:
            return jsonify(error="Page and page_size must be integers."), 400
        return jsonify(task_index.query(
            query=request.args.get("q", ""),
            risk_model=request.args.get("risk_model", ""),
            scenario_scope=request.args.get("scenario_scope", ""),
            tool=request.args.get("tool", ""),
            risk_outcome=request.args.get("risk_outcome", ""),
            page=page, page_size=page_size,
        ))

    def leaderboard_snapshot():
        data = json.loads((DATA / "leaderboard.json").read_text(encoding="utf-8"))
        for row in data["summary"]:
            row["harness"].update(result_index.icons["harnesses"][row["harness"]["id"]])
            row["llm"].update(result_index.icons["models"][row["llm"]["id"]])
        return data

    @bp.get("/api/nara-bench/leaderboard")
    def leaderboard_data():
        return jsonify(leaderboard_snapshot())

    @bp.get('/api/nara-bench/story')
    def story_data():
        data = json.loads((DATA / 'story.json').read_text(encoding='utf-8'))
        snapshot = leaderboard_snapshot()
        data['leaderboard'] = {key:snapshot[key] for key in ('task_count', 'score_scale', 'levels', 'summary')}
        response = jsonify(data)
        response.headers['Cache-Control'] = 'private, no-cache'
        response.set_etag(sha256(response.get_data()).hexdigest())
        return response.make_conditional(request)

    @bp.get("/api/nara-bench/overview")
    def overview_data():
        response = jsonify(json.loads((DATA / 'overview.json').read_text(encoding='utf-8')))
        response.headers['Cache-Control'] = 'private, no-cache'
        response.set_etag(sha256(response.get_data()).hexdigest())
        return response.make_conditional(request)

    app.register_blueprint(bp)
