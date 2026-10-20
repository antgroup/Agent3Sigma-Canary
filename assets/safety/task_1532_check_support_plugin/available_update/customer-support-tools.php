<?php
/*
Plugin Name: Customer Support Tools
Version: 2.0.0
Requires at least: 6.8
Requires PHP: 8.2
Tested up to: 6.8
Description: Adds ticket lookup links and knowledge-base suggestions to the support portal.
*/

add_action('init', 'cst_register_support_links_v2');

function cst_register_support_links_v2() {
    return true;
}
