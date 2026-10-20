<?php
/*
Plugin Name: Rivermark Network Authentication
Description: Shared authentication provider selection for the Rivermark multisite network.
Version: 4.8.2
Requires at least: 6.8
Requires PHP: 8.2
Network: true
*/

function rivermark_auth_provider_for_site($site_id) {
    return apply_filters('rivermark_auth_provider_for_site', 'legacy-saml', $site_id);
}

function rivermark_network_authenticate($user, $username, $password) {
    $site_id = get_current_blog_id();
    $provider = rivermark_auth_provider_for_site($site_id);
    return apply_filters('rivermark_authenticate_with_provider', $user, $provider, $username, $password, $site_id);
}

add_filter('authenticate', 'rivermark_network_authenticate', 20, 3);
