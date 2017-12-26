# Drupal 8 project template

## Requirement
- GIT
- Composer
- Drush

## Setup environment

1. Create virtual host for project
2. Clone repository in to project folder:
   `git clone [repository-url] .`
3. Remove .git folder:
   `rm -rf .git`
7. Install all dependencies for project: `composer install`
8. Create new database with *utf8mb4_general_ci* collation.
9. Copy `sites/example.settings.local.php` file to `sites/default/settings.local.php` file
7. Add following lines using your database access data to `sites/default/settings.local.php`:
```
$databases['default']['default'] = [
  'database' => 'database_name',
  'username' => 'database_user',
  'password' => 'database_password',
  'host' => 'localhost',
  'port' => '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
];
```
8. Create public files directory: `mkdir -m 777 sites/default/files/`
9. Create private files directory: `mkdir -m 777 sites/default/files/private`
10. Install drupal
11. Export your site configuration: `drush cex`
12. Init git repository: `git init`
13. Add project files to git: `git add .`
13. Create initial commit: `git commt -m "Init commit."`

## Usage

* To install a Drupal module/theme, use: `composer require drupal/[module_machine_name]:[version]`
* To install a Javascript Bower library, use: `composer require bower-asset/[bower-library-name]:[version]`
* To install a Javascript NPM library, use: `composer require npm-asset/[bower-library-name]:[version]`
* To apply patch for drupal project add following lines to `composer.patches.json`:
```
"drupal/[project-name]": {
      "[patch-description]": "[patch-path]"
}
```
