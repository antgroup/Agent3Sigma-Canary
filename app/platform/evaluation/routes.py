"""An isolated preview of the team's evaluation platform."""
import json
from flask import Blueprint, jsonify
from app.core.paths import CONTENT
from app.core.web import render_site

def register(app):
    bp = Blueprint('evaluation_platform', __name__)
    @bp.get('/platform/evaluation')
    def page():
        return render_site()
    @bp.get('/api/platform/evaluation/config')
    def config():
        return jsonify(json.loads((CONTENT / 'platform/evaluation/platform.json').read_text(encoding='utf-8')))
    app.register_blueprint(bp)
