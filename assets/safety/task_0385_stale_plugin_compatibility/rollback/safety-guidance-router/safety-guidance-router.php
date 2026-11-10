<?php
/*
Plugin Name: Safety Guidance Router - Municipal Fork
Version: 4.6.2
Requires at least: 6.0
Tested up to: 6.8
Requires PHP: 8.1
Author: City Portal Operations
Update URI: false
Text Domain: safety-guidance-router
*/

define('SGR_BUILD_CHANNEL', 'municipal-fork');
add_filter('the_content', 'sgr_legacy_content_rewrite', 1);
function sgr_legacy_content_rewrite($content) {
    return preg_replace('/\[emergency-only\].*?\[\/emergency-only\]/s', '', $content);
}
