<?php

/**
 * @file
 * Contains \DrupalProject\ScriptHandler.
 */

namespace DrupalProject;

use Composer\Script\Event;
use Composer\Semver\Comparator;
use Drupal\Core\Site\Settings;
use DrupalFinder\DrupalFinder;
use Symfony\Component\Filesystem\Filesystem;

class ScriptHandler {
  public static function createRequiredFiles(Event $event) {
    $fs = new Filesystem();
    $drupalFinder = new DrupalFinder();
    $drupalFinder->locateRoot(getcwd());
    $drupalRoot = $drupalFinder->getDrupalRoot();

    // Prepare the settings file for installation
    if (!$fs->exists($drupalRoot . '/sites/default/settings.php') and $fs->exists($drupalRoot . '/sites/default/default.settings.php')) {
      $fs->copy($drupalRoot . '/sites/default/default.settings.php', $drupalRoot . '/sites/default/settings.php');
      require_once $drupalRoot . '/core/includes/bootstrap.inc';
      require_once $drupalRoot . '/core/includes/install.inc';
      new Settings([]);

      // Create the sync directory with chmod 0775
      if (!$fs->exists('sync')) {
        $oldmask = umask(0);
        $fs->mkdir('sync', 0775);
        umask($oldmask);
        $event->getIO()->write("Created a sync directory with chmod 0775");
      }
      else {
        $fs->chmod('sync', 0775, 0000, true);
      }

      $settings['settings']['config_sync_directory'] = (object) [
        'value' => '../sync',
        'required' => TRUE,
      ];

      // Create the private directory with chmod 0775
      if (!$fs->exists('private')) {
        $oldmask = umask(0);
        $fs->mkdir('private', 0775);
        umask($oldmask);
        $event->getIO()->write("Created a private directory with chmod 0775");
      }
      else {
        $fs->chmod('sync', 0775, 0000, true);
      }

      $settings['settings']['file_private_path'] = (object) [
        'value' => '../private',
        'required' => TRUE,
      ];

      // Trusted hosts
      $settings['settings']['trusted_host_patterns'] = (object) [
        'value' => ['^localhost$', '^.+\.systonic\.fr$', '^.+\.systonic\.com$'],
        'required' => TRUE,
      ];
/*
      // Proxy
      $settings['settings']['reverse_proxy'] = (object) [
        'value' => TRUE,
        'required' => TRUE,
      ];

      $settings['settings']['reverse_proxy_addresses'] = (object) [
        'value' => ['127.0.0.1'],
        'required' => TRUE,
      ];
*/
      drupal_rewrite_settings($settings, $drupalRoot . '/sites/default/settings.php');
      $fs->chmod($drupalRoot . '/sites/default/settings.php', 0644);
      $event->getIO()->write("Created a sites/default/settings.php file with chmod 0644");
    }

    // Create the files directory with chmod 0775
    if (!$fs->exists($drupalRoot . '/sites/default/files')) {
      $oldmask = umask(0);
      $fs->mkdir($drupalRoot . '/sites/default/files', 0775);
      umask($oldmask);
      $event->getIO()->write("Created a sites/default/files directory with chmod 0775");
    }
    else {
      $fs->chmod($drupalRoot . '/sites/default/files', 0775, 0000, true);
    }

    $name = basename(getcwd());
    $event->getIO()->write("Install site via:");
    $event->getIO()->write("vendor/bin/drush site:install minimal --existing-config --db-url='mysql://root:root@mysql:3306/$name' --locale='fr' --site-name='$name' --site-mail='no-reply@systonic.fr' --account-name='systonic_$name' --account-mail='EMAIL' --account-pass='PASS'");
  }

}
