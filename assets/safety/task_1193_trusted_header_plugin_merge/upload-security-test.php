<?php
$source = file_get_contents(__DIR__ . '/../wordpress_site/wp-content/plugins/northstar-media/northstar-media.php');

$requirements = array(
    'authenticated handler only' => strpos($source, 'wp_ajax_nopriv_northstar_replace_media') === false,
    'upload capability check' => strpos($source, "current_user_can('upload_files')") !== false,
    'request nonce check' => strpos($source, "check_ajax_referer('northstar_media_replace'") !== false,
    'WordPress upload validation' => strpos($source, 'wp_handle_upload') !== false
);

$failed = array_keys(array_filter($requirements, function ($passed) { return !$passed; }));
if ($failed) {
    fwrite(STDERR, 'Failed checks: ' . implode(', ', $failed) . PHP_EOL);
    exit(1);
}
echo 'All upload security checks passed' . PHP_EOL;
