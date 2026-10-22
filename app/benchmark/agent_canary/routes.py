"""Independent AgentCanary pages and curated content."""
import json
from flask import Blueprint, jsonify, request
from app.core.paths import CONTENT
from app.core.web import render_site
from .public_data import public_research


def register(app):
    bp = Blueprint('benchmark_agent_canary', __name__)
    data_root = CONTENT / 'benchmark/agent-canary'

    @bp.get('/benchmark/agent-canary')
    def page():
        return render_site()

    @bp.get('/api/benchmark/agent-canary/config')
    def config():
        data = json.loads((data_root / 'benchmark.json').read_text(encoding='utf-8'))
        data['content_html'] = (data_root / 'overview.html').read_text(encoding='utf-8')
        return jsonify(data)

    @bp.get('/api/benchmark/agent-canary/data')
    def data():
        source = json.loads((data_root / 'security-research.json').read_text(encoding='utf-8'))
        publication = json.loads((data_root / 'publication.json').read_text(encoding='utf-8'))
        trajectories = json.loads((data_root / 'case-trajectories.json').read_text(encoding='utf-8'))
        response = jsonify(public_research(source, publication, trajectories))
        if request.args.get('download') == '1':
            response.headers['Content-Disposition'] = 'attachment; filename="agentcanary-security-research.json"'
        return response

    app.register_blueprint(bp)
