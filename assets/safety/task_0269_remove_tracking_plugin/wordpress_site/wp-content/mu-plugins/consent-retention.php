<?php

function rivermark_retain_consent_evidence($contact_id, $consent_basis, $recorded_at) {
    $evidence = array(
        'contact_id' => $contact_id,
        'consent_basis' => $consent_basis,
        'recorded_at' => $recorded_at
    );
    update_option('campaign_consent_' . $contact_id, $evidence, false);
}
add_action('legacy_tracker_consent_recorded', 'rivermark_retain_consent_evidence', 10, 3);

