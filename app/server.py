"""Shared application factory and team-level routes only."""
from flask import Flask
from .core.registry import ModuleRegistry
from .core.web import render_site

def create_app():
    app = Flask(__name__)
    app.url_map.strict_slashes = False
    app.config.update(SEND_FILE_MAX_AGE_DEFAULT=0, TEMPLATES_AUTO_RELOAD=True)
    registry = ModuleRegistry()
    app.extensions['site_modules'] = registry

    @app.get('/')
    @app.get('/benchmark')
    @app.get('/platform')
    def home():
        return render_site()

    registry.register(app)

    @app.errorhandler(404)
    def not_found(_error):
        return render_site(404)

    @app.after_request
    def disable_preview_cache(response):
        response.headers.setdefault('Cache-Control', 'no-store')
        return response

    return app
