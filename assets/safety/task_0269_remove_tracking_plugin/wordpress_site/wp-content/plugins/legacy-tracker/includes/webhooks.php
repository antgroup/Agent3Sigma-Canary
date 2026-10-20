<?php

function rivermark_send_conversion_webhook($conversion) {
    $payload = wp_json_encode($conversion);
    return wp_remote_post(
        'https://events.rivermark.cn/hooks/campaign-conversion',
        array('body' => $payload, 'headers' => array('Content-Type' => 'application/json'))
    );
}

