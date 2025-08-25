<?php
// Load trusted host patterns from the environment variable DRUPAL_TRUSTED_HOSTS
// Value should be a comma-separated list of hostnames or patterns.
// Examples:
//   DRUPAL_TRUSTED_HOSTS=example.com,sub.example.com
//   DRUPAL_TRUSTED_HOSTS=*.example.com,127.0.0.1
//
// Each item is converted into a Drupal trusted_host_patterns regex.
// Wildcards (*) are supported (converted to .*) and other regex chars are escaped.

$env = getenv('DRUPAL_TRUSTED_HOSTS');

if ($env !== false && trim($env) !== '') {
    $items = preg_split('/\s*,\s*/', trim($env));
    $patterns = [];

    foreach ($items as $item) {
        $item = trim($item);
        if ($item === '') {
            continue;
        }

        // Escape regex metacharacters, then restore wildcard behavior for '*'
        $escaped = preg_quote($item, '/');
        $escaped = str_replace('\*', '.*', $escaped);

        // Anchor the pattern
        $patterns[] = '^' . $escaped . '$';
    }

    if (!empty($patterns)) {
        // Set or override Drupal's trusted host patterns
        $settings['trusted_host_patterns'] = $patterns;
    }

    // Hash salt: prefer env var, then Docker secret files (common names), then nothing.
    $hash_salt = getenv('DRUPAL_HASH_SALT');
    if (($hash_salt === false || trim($hash_salt) === '') && is_readable('/run/secrets/drupal_hash_salt')) {
        $hash_salt = trim(file_get_contents('/run/secrets/drupal_hash_salt'));
    }
    if (($hash_salt === false || trim($hash_salt) === '') && is_readable('/run/secrets/hash_salt')) {
        $hash_salt = trim(file_get_contents('/run/secrets/hash_salt'));
    }
    if ($hash_salt !== false && trim($hash_salt) !== '') {
        $settings['hash_salt'] = $hash_salt;
    }

    // Config sync directory: set from DRUPAL_CONFIG_SYNC_DIR if provided (absolute or container path)
    $config_sync = getenv('DRUPAL_CONFIG_SYNC_DIR');
    if ($config_sync !== false && trim($config_sync) !== '') {
        // Normalize trailing slash and set
        $settings['config_sync_directory'] = rtrim($config_sync, "/\\");
    }
}