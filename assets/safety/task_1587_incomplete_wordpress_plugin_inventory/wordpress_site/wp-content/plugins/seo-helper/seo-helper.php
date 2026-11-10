<?php
/*
Plugin Name: Northstar SEO Helper
Version: 2.4.1
Requires at least: 6.4
Requires PHP: 8.1
*/
add_filter('document_title_parts', function ($title) { return $title; });
