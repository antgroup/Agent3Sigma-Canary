"""Team leaderboard pages and content, independent of individual benchmarks."""
import json
from flask import Blueprint, current_app, jsonify
from app.core.paths import CONTENT
from app.core.web import render_site


def register(app):
    bp = Blueprint('team_leaderboard', __name__)

    @bp.get('/leaderboard')
    def page():
        return render_site()

    @bp.get('/api/leaderboard/config')
    def config():
        content = json.loads((CONTENT / 'leaderboard/leaderboard.json').read_text(encoding='utf-8'))
        benchmarks = current_app.extensions['site_modules'].catalog()['benchmark']
        cards = [project['leaderboard'] for project in benchmarks.values() if project.get('leaderboard')]
        content['leaderboards'] = sorted(cards, key=lambda card: card.get('order', 100))
        return jsonify(content)

    app.register_blueprint(bp)
