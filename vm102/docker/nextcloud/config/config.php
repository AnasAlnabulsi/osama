<?php

/*
 * WARNING
 *
 * This file gets modified by automatic processes and all lines that are not
 * active code (ie. comments) are lost during that process.
 *
 * If you want to document things with comments or use constants add your settings
 * in a '<NAME>.config.php' file which will be included and rendered into this file.
 *
 * Example:
 *   <?php
 *   $CONFIG = [];
 *
 * See also: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#multiple-merged-configuration-files
 */
$CONFIG = array (
  'instanceid' => 'ochnq5yu874g',
  'passwordsalt' => 'REDACTED',
  'secret' => 'REDACTED',
  'trusted_domains' => 
  array (
    0 => '192.168.178.2',
    1 => 'nextcloud.barye.cloudns.asia',
    2 => 'nextcloud.hhc.cloudns.asia',
    3 => '192.168.178.3',
    4 => 'nextcloud',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '35.0.0.10',
  'dbname' => 'nextcloud',
  'dbhost' => 'mariadb',
  'dbport' => '3306',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'admin',
  'dbpassword' => 'REDACTED',
  'installed' => true,
  'trusted_proxies' => 
  array (
    0 => '127.0.0.1',
    1 => '172.23.0.0/16',
  ),
  'overwrite.cli.url' => 'https://nextcloud.barye.cloudns.asia',
  'overwritehost' => 'nextcloud.barye.cloudns.asia',
  'overwriteprotocol' => 'https',
  'overwritewebroot' => '',
  'overwritecondaddr' => '.*',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
  ),
  'maintenance_window_start' => '02:00',
  'default_phone_region' => 'DE',
  'maintenance' => false,
  'theme' => '',
  'loglevel' => 3,
  'logfile' => '/var/www/html/data/nextcloud.log',
  'mail_smtpmode' => 'sendmail',
  'mail_sendmailmode' => 'smtp',
);
