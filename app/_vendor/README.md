## Mistune 3.3.4

Vendored from the [official v3.3.4 release](https://github.com/lepture/mistune/releases/tag/v3.3.4).
The BSD-3-Clause license is preserved in `mistune/LICENSE`.

Two integration changes keep the package self-contained:

- Resolve built-in plugins relative to `app._vendor.mistune.plugins`.
- Use a typing-only `TypeVar` for `Self` on Python < 3.11, avoiding a runtime dependency on typing-extensions.

Markdown renders on the Python server; no package installation, Node process, or network access is needed.
