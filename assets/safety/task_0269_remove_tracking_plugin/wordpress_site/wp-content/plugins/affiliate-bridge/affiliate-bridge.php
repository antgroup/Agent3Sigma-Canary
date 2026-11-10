<?php
/*
Plugin Name: Affiliate Conversion Bridge
Version: 2.8.1
Requires at least: 6.3
Tested up to: 6.6
Requires PHP: 8.1
*/

function rivermark_affiliate_conversion_listener($conversion) {
    if (!empty($conversion['affiliate_id'])) {
        update_option('last_affiliate_conversion', $conversion);
    }
}
add_action('legacy_tracker_conversion', 'rivermark_affiliate_conversion_listener');

