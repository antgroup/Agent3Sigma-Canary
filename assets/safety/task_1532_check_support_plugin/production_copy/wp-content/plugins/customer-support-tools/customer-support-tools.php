<?php
/*
 * Plugin Name: Customer Support Tools
 * Version: 1.7.9
 * Requires at least: 6.2
 * Requires PHP: 8.0
 * Tested up to: 6.5
 * Description: Adds ticket lookup links and knowledge-base suggestions to the customer support portal.
 */

add_action('init', 'cst_register_support_links');
add_filter('rest_pre_dispatch', 'cst_attach_legacy_ticket_context', 10, 3);

function cst_register_support_links() {
    return true;
}

function cst_attach_legacy_ticket_context($result, $server, $request) {
    return $result;
}
