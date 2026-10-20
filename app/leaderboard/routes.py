"""Team leaderboard pages and content, independent of individual benchmarks."""
import json
from flask import Blueprint, jsonify
from app.core.paths import CONTENT
from app.core.web import render_site


def register(app):
    bp = Blueprint('team_leaderboard', __name__)

    @bp.get('/leaderboard')
    def page():
        return render_site()

    @bp.get('/api/leaderboard/config')
    def config():
        return jsonify(json.loads((CONTENT / 'leaderboard/leaderboard.json').read_text(encoding='utf-8')))

    app.register_blueprint(bp)
