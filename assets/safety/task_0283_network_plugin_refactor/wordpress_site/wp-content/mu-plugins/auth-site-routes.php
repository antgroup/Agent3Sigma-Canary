<?php
/*
Plugin Name: Rivermark Site Authentication Routes
Description: Existing site-scoped provider routes for the multisite network.
Version: 3.4.0
Requires at least: 6.8
Requires PHP: 8.2
Network: true
*/

add_filter('rivermark_auth_provider_for_site', function ($provider, $site_id) {
    $routes = array(
        11 => 'legacy-saml',
        22 => 'oidc-v1',
        33 => 'service-saml',
    );
    return $routes[(int) $site_id] ?? $provider;
}, 10, 2);
