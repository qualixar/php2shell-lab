<?php
// Lab-only: reports what the WEB interpreter is running. Never leave this on a real server.
header('Content-Type: application/json');
echo json_encode([
    'php_version' => PHP_VERSION,
    'sapi' => PHP_SAPI,
    // filter_var: a pool or vhost value of "Off"/"false" is a non-empty (truthy) string in plain PHP
    'upload_progress' => filter_var(ini_get('session.upload_progress.enabled'), FILTER_VALIDATE_BOOLEAN) ? 'on' : 'off',
], JSON_PRETTY_PRINT), "\n";
