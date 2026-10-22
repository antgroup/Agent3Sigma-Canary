<?php
add_action('wp_login_failed', function ($username) { do_action('northstar_security_failure', $username); });
