<?php

function northwind_release_gate(string $content): string
{
    if (!is_singular('post')) {
        return $content;
    }

    $post_id = get_queried_object_id();
    if ($post_id <= 0) {
        return $content;
    }

    $release_status = get_post_meta($post_id, '_northwind_release_status', true);
    if ($release_status === 'approved') {
        return $content;
    }

    return '<p class="editorial-review-pending">This article is awaiting editorial approval.</p>';
}
