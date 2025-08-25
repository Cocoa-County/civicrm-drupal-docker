<?php
/**
 * Minimal docker settings helpers.
 *
 * This file reads three environment-driven settings and sets them if provided:
 * - DRUPAL_TRUSTED_HOSTS (comma-separated, supports * wildcards)
 * - DRUPAL_HASH_SALT (falls back to /run/secrets/* common names)
 * - DRUPAL_CONFIG_SYNC_DIR
 */

// Helper: get trimmed env var or null
function _env_trim(string $name, $default = null) {
    $v = getenv($name);
    if ($v === false) {
        return $default;
    }
    $v = trim($v);
    return $v === '' ? $default : $v;
}

// 1) trusted_host_patterns from DRUPAL_TRUSTED_HOSTS (comma-separated)
if ($trusted = _env_trim('DRUPAL_TRUSTED_HOSTS')) {
    $items = array_filter(array_map('trim', preg_split('/\s*,\s*/', $trusted)));
    $patterns = [];
    foreach ($items as $item) {
        // escape, then restore wildcard '*' -> '.*'
        $escaped = preg_quote($item, '/');
        $escaped = str_replace('\\*', '.*', $escaped);
        $patterns[] = '^' . $escaped . '$';
    }
    if (!empty($patterns)) {
        $settings['trusted_host_patterns'] = $patterns;
    }
}

// 2) hash_salt: prefer env, then Docker secrets
$hash = _env_trim('DRUPAL_HASH_SALT');
if ($hash === null) {
    foreach (['/run/secrets/drupal_hash_salt', '/run/secrets/hash_salt'] as $p) {
        if (is_readable($p)) {
            $content = trim(file_get_contents($p));
            if ($content !== '') {
                $hash = $content;
                break;
            }
        }
    }
}
if ($hash !== null) {
    $settings['hash_salt'] = $hash;
}

// 3) config_sync_directory from env (trim trailing slashes)
if ($dir = _env_trim('DRUPAL_CONFIG_SYNC_DIR')) {
    $settings['config_sync_directory'] = rtrim($dir, "/\\");
}
