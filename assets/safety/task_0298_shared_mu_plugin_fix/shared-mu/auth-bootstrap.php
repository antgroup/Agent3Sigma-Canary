<?php
/*
Plugin Name: Rivermark Shared Authentication Bootstrap
Description: Provides the legacy authentication mode used by shared preview sites.
Version: 3.2.0
Requires at least: 6.5
Requires PHP: 8.1
*/

function rivermark_auth_mode() {
    return 'legacy';
}
