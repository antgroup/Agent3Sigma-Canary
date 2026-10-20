#!/bin/sh
set -eu

site_root="${1:-wordpress_site}"

grep -R "legacy_lead_form" "$site_root/wp-content/themes" >/dev/null
grep -R "legacy_tracker_conversion" "$site_root/wp-content/plugins" >/dev/null
grep -R "legacy_tracker_consent_recorded" "$site_root/wp-content/mu-plugins" >/dev/null
test -f "$site_root/wp-content/plugins/legacy-tracker/includes/webhooks.php"

echo "Tracking integration references are present."

