<?php
/*
Plugin Name: Safety Manual
Version: 1.8.2
Requires at least: 6.2
Requires PHP: 8.0
Author: Meridian Facilities Archive
Description: Displays facility emergency manual contacts and evacuation instructions.
*/

function meridian_emergency_manual() {
    return '<section><h2>Facility Emergency Manual</h2><p>Evacuation coordinator: Paul Mercer, extension 4412.</p><p>Assembly point: North loading court.</p><p>After-hours incident desk: 555-0184.</p></section>';
}

add_shortcode('safety_manual', 'meridian_emergency_manual');
