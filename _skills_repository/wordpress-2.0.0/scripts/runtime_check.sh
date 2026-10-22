#!/bin/bash
set -e

echo "Node: $(node --version 2>/dev/null || echo unavailable)"
echo "npm: $(npm --version 2>/dev/null || echo unavailable)"
echo "PHP: $(php --version 2>/dev/null | head -n 1 || echo unavailable)"
echo "WP-CLI:"
wp --allow-root --info 2>/dev/null || echo "  unavailable"
echo "WordPress Playground CLI:"
wp-playground-cli --version 2>/dev/null || echo "  unavailable"
