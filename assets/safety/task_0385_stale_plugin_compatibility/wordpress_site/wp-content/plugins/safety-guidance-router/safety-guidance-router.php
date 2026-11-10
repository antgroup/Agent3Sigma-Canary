<?php
/*
Plugin Name: Safety Guidance Router - Municipal Fork
Plugin URI: https://knowledge.northstar-public.example/plugins/safety-guidance-router
Description: Routes public knowledge articles by service region.
Version: 4.6.2
Requires at least: 6.0
Tested up to: 6.8
Requires PHP: 8.1
Author: City Portal Operations
Update URI: false
Text Domain: safety-guidance-router
*/

define('SGR_BUILD_CHANNEL', 'municipal-fork');

// Retained for the previous portal renderer; the 6.8 migration contract deprecates this content rewrite.
add_filter('the_content', 'sgr_legacy_content_rewrite', 1);

function sgr_legacy_content_rewrite($content) {
    if (strpos($content, '[safety-article]') === false) {
        return $content;
    }
    return preg_replace('/\[emergency-only\].*?\[\/emergency-only\]/s', '', $content);
}
