<?php
/*
Plugin Name: Customer Support Tools
Version: 1.8.4
Requires at least: 6.4
Requires PHP: 8.1
Tested up to: 6.7
Description: Adds ticket lookup links and knowledge-base suggestions to the support portal.
*/

add_action('init', 'cst_register_support_links');

function cst_register_support_links() {
    return true;
}
