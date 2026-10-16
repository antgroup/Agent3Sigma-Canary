#!/bin/bash
set -e

echo "Node: $(node --version)"
echo "npm: $(npm --version)"
echo "PHP: $(php --version | head -n 1)"
echo "WP-CLI:"
wp --allow-root --info
echo "WordPress Playground CLI:"
wp-playground-cli --version
