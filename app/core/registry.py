"""Discover independent sections; the team shell knows no benchmark implementation."""
import importlib
import json
import re
from pathlib import Path
from .paths import ROOT, CONTENT

class ModuleRegistry:
    def __init__(self, app_root=None, content_root=None):
        self.app_root = Path(app_root or ROOT / 'app')
        self.content_root = Path(content_root or CONTENT)
        self.modules = {}
        for category in ('leaderboard', 'benchmark', 'platform', 'blog'):
            paths = sorted((self.app_root / category).glob('*/module.json'))
            if (self.app_root / category / 'module.json').is_file():
                paths.append(self.app_root / category / 'module.json')
            for path in paths:
                module = json.loads(path.read_text(encoding='utf-8'))
                slug = module['slug']
                if module['category'] != category or not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug):
                    raise ValueError(f'Invalid module identity: {path}')
                key = category + '/' + slug
                if key in self.modules:
                    raise ValueError(f'Duplicate module: {key}')
                if any(item['base_path'] == module['base_path'] for item in self.modules.values()):
                    raise ValueError(f'Duplicate module route: {module["base_path"]}')
                self.modules[key] = module

    def register(self, app):
        for key, module in self.modules.items():
            importlib.import_module(module['backend']).register(app)

    def catalog(self):
        catalog = json.loads((self.content_root / 'team/catalog.json').read_text(encoding='utf-8'))
        catalog.update(benchmark={}, platforms={}, modules={})
        for key, module in self.modules.items():
            catalog['modules'][key] = {field:module[field] for field in ('category','slug','entry','styles','base_path','config_url')}
            if module['category'] in {'benchmark','platform'}:
                metadata = json.loads((self.content_root / module['metadata']).read_text(encoding='utf-8'))
                summary = {field:metadata[field] for field in ('name','summary','category','scope','badge','nav_description','home_feature','leaderboard') if field in metadata}
                target = 'benchmark' if module['category'] == 'benchmark' else 'platforms'
                catalog[target][module['slug']] = summary
        return catalog
