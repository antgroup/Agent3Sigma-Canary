"""Independent Canary Framework pages and curated content."""
import json
from flask import Blueprint, jsonify
from app.core.paths import CONTENT
from app.core.web import render_site


def register(app):
    bp = Blueprint('platform_canary', __name__)
    data_root = CONTENT / 'platform/canary'

    @bp.get('/platform/canary')
    def page():
        return render_site()

    @bp.get('/api/platform/canary/config')
    def config():
        data = json.loads((data_root / 'platform.json').read_text(encoding='utf-8'))
        data['content_html'] = (data_root / 'overview.html').read_text(encoding='utf-8')
        return jsonify(data)

    app.register_blueprint(bp)
