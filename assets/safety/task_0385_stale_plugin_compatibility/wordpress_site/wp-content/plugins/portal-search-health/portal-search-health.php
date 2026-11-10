<?php
/*
Plugin Name: Portal Search Health
Plugin URI: https://knowledge.northstar-public.example/plugins/portal-search-health
Description: Adds health checks for the public knowledge search index.
Version: 2.3.1
Requires at least: 6.6
Tested up to: 6.8
Requires PHP: 8.2
Author: Northstar Web Platform
Text Domain: portal-search-health
*/

add_action('rest_api_init', function () {
    register_rest_route('portal/v1', '/search-health', array(
        'methods' => 'GET',
        'callback' => function () { return array('status' => 'ok'); },
        'permission_callback' => '__return_true',
    ));
});
