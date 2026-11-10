<?php

function northwind_normalize_media_url($url)
{
    if (!is_string($url) || $url === '') {
        return $url;
    }

    $legacy_prefix = 'http://media.northwind.example/';
    if (!str_starts_with($url, $legacy_prefix)) {
        return $url;
    }

    return 'https://cdn.northwind.example/' . substr($url, strlen($legacy_prefix));
}

add_filter('wp_get_attachment_url', 'northwind_normalize_media_url', 10, 1);
add_filter('media_credit_source_url', 'northwind_normalize_media_url', 10, 1);
