<?php
/*
Plugin Name: Checkout Bridge
Description: Connects the Rivermark checkout workflow to WordPress orders.
Version: 3.4.0
Requires at least: 6.1
Requires PHP: 8.1
Tested up to: 6.6
*/

function rivermark_checkout_bridge_register() {
    if (!function_exists('wp_register_block_metadata_collection')) {
        return;
    }
    wp_register_block_metadata_collection(__DIR__ . '/build', __DIR__ . '/build/blocks-manifest.php');
}

add_action('init', 'rivermark_checkout_bridge_register');
