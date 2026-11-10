<?php
require_once dirname(__DIR__) . '/plugins/editorial-workflow/editorial-workflow.php';
add_filter('the_content', 'northwind_release_gate');
