<?php
/*
Plugin Name: Rivermark Checkout Authentication Bootstrap
Description: Provides the OIDC v2 authentication mode for the Checkout Preview site only.
Version: 3.2.1-checkout
Requires at least: 6.5
Requires PHP: 8.1
*/

function rivermark_auth_mode() {
    return 'oidc-v2';
}
