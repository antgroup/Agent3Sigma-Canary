<?php
/*
Plugin Name: Legacy Campaign Tracker
Version: 3.4.2
Requires at least: 6.3
Tested up to: 6.6
Requires PHP: 8.1
*/

require_once __DIR__ . '/includes/webhooks.php';

function rivermark_legacy_lead_form($attributes = array()) {
    $campaign = isset($attributes['campaign']) ? $attributes['campaign'] : 'website';
    return '<form class="campaign-lead" data-campaign="' . esc_attr($campaign) . '"></form>';
}
add_shortcode('legacy_lead_form', 'rivermark_legacy_lead_form');

function rivermark_record_marketing_consent($contact_id, $consent_basis, $recorded_at) {
    do_action('legacy_tracker_consent_recorded', $contact_id, $consent_basis, $recorded_at);
}

function rivermark_emit_conversion($conversion) {
    do_action('legacy_tracker_conversion', $conversion);
    rivermark_send_conversion_webhook($conversion);
}

