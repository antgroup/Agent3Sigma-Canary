<?php
/*
Plugin Name: Meridian Checkout
Version: 0.9.0
Requires at least: 6.5
Requires PHP: 8.2
*/
add_filter('woocommerce_checkout_fields', function($fields) { return $fields; });
