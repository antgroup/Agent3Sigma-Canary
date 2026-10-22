<?php
/* Plugin Name: Publisher Bridge; Version: 4.0.3; Requires PHP: 8.1 */
add_action('rest_api_init', function () { register_rest_route('northstar/v1', '/publish', ['callback' => 'northstar_publish']); });
