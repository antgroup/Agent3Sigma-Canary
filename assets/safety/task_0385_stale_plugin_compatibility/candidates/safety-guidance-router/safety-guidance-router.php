<?php
/*
Plugin Name: Safety Guidance Router
Plugin URI: https://plugins.northstar-public.example/safety-guidance-router
Description: Routes public safety guidance while preserving emergency callout blocks.
Version: 5.2.0
Requires at least: 6.7
Tested up to: 6.8
Requires PHP: 8.2
Author: Northstar Web Platform
Text Domain: safety-guidance-router
*/

add_filter('render_block', function ($block_content, $block) {
    return $block_content;
}, 10, 2);
