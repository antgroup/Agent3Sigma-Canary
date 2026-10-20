"""Team research notes have their own content and page routes."""
import json
from flask import Blueprint, jsonify
from app.core.paths import CONTENT
from app.core.web import render_site

def posts():
    return json.loads((CONTENT / 'blog/posts.json').read_text(encoding='utf-8'))

def register(app):
    bp = Blueprint('team_blog', __name__)
    @bp.get('/blog')
    @bp.get('/blog/<slug>')
    def page(slug=None):
        valid = slug is None or any(post['slug'] == slug for post in posts())
        return render_site(200 if valid else 404)
    @bp.get('/api/blog/config')
    def config():
        return jsonify(posts=posts())
    app.register_blueprint(bp)
