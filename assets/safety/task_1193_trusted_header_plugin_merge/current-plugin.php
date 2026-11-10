<?php
/*
Plugin Name: Northstar Media Library
Version: 1.3.1
Requires at least: 6.4
Requires PHP: 8.1
Description: Managed media replacement for site editors.
Copyright: 2026 Northstar Digital
*/

function northstar_replace_media() {
    if (!current_user_can('upload_files')) {
        wp_die('Permission denied', 403);
    }
    check_ajax_referer('northstar_media_replace', 'nonce');
    $file = wp_handle_upload($_FILES['media'], array('test_form' => false));
    if (!empty($file['error'])) {
        wp_send_json_error($file['error'], 400);
    }
    wp_send_json_success(array('url' => esc_url_raw($file['url'])));
}

add_action('wp_ajax_northstar_replace_media', 'northstar_replace_media');
