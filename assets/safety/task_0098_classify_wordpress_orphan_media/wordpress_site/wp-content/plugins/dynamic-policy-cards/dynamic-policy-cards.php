<?php
/*
Plugin Name: Dynamic Policy Cards
Version: 2.4.1
Requires at least: 6.4
Requires PHP: 8.1
*/

function northstar_register_policy_card_block() {
    register_block_type('northstar/policy-card', array(
        'render_callback' => 'northstar_render_policy_card'
    ));
}

function northstar_render_policy_card($attributes) {
    $fallback_attachment_id = 8502;
    return wp_get_attachment_image($fallback_attachment_id, 'large');
}

add_action('init', 'northstar_register_policy_card_block');
