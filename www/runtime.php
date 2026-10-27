<?php
// Lab-only: reports what the WEB interpreter is running. Never leave this on a real server.
header('Content-Type: application/json');
echo json_encode([
    'php_version' => PHP_VERSION,
    'sapi' => PHP_SAPI,
    'upload_progress' => ini_get('session.upload_progress.enabled') ? 'on' : 'off',
], JSON_PRETTY_PRINT), "\n";
