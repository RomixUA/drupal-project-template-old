#!/bin/bash
echo "Welcome in the script for Bootstrap SASS subtheme creator."
echo

read -p "Please, enter the theme name: " theme_name
while [[ $theme_name == '' ]]
do
    echo "$(tput setaf 1)Enter a valid theme name$(tput sgr 0)"
    read -p "Please, enter the theme name: " theme_name
done
name=${theme_name,,}
name=${name//[^a-z0-9_]/_}
read -e -p "Please, enter the theme machine name: " -i "$name" machine_name
while [[ $machine_name == '' ]] || [[ $machine_name =~ [^a-z0-9_] ]]
do
    echo "$(tput setaf 1)Enter a valid machine name$(tput sgr 0)"
    read -p "Please, enter the theme machine name: " machine_name
done
read -p "Do you want to add css files to .gitignore ? (y/n): " ignore_styles
read -p "Do you want to add drush command for style compilation? (y/n): " drush_styles
mkdir -p ./tmp
wget --output-document=tmp/bootstrap.tar.gz -q http://ftp.drupal.org/files/projects/$(wget -q -O- http://drupal.org/project/bootstrap | egrep -o 'bootstrap-8.x-[0-9\.]+.tar.gz' | sort -V  | tail -1)
tar xf tmp/bootstrap.tar.gz -C tmp
mkdir -p ./themes/custom
cp -R ./tmp/bootstrap/starterkits/sass ./themes/custom/"$machine_name"
mv ./themes/custom/"$machine_name"/THEMENAME.starterkit.yml ./themes/custom/"$machine_name"/THEMENAME.info.yml
sed -i -- 's/bootstrap\/assets/\/libraries\/bootstrap-sass\/assets/g' ./themes/custom/"$machine_name"/THEMENAME.libraries.yml
sed -i -- 's/\.\/THEMENAME\/bootstrap\/assets/..\/..\/..\/..\/libraries\/bootstrap-sass\/assets/g' ./themes/custom/"$machine_name"/scss/*.*
sed -i -- 's/\.\.\/bootstrap\/assets/..\/..\/..\/..\/libraries\/bootstrap-sass\/assets/g' ./themes/custom/"$machine_name"/scss/*.*
find ./themes/custom/"$machine_name" -type f -exec sed -i "s/THEMENAME/$machine_name/g" {} +
find ./themes/custom/"$machine_name" -type f -exec sed -i "s/THEMETITLE/$theme_name/g" {} +
find ./themes/custom/"$machine_name" -type f -name "THEMENAME.*" -print0 | while read -r -d '' file; do
    mv "$file" "${file//THEMENAME/$machine_name}"
done
if [ $ignore_styles == "y" ]
then
    cat > ./themes/custom/"$machine_name"/.gitignore << EOF
# Ignore css files.
/css/*.css
/css/*.map

# Ignore node modules
/node_modules/

EOF
else
    cat > ./themes/custom/"$machine_name"/.gitignore << EOF
# Ignore node modules
/node_modules/

EOF
fi
if [ $drush_styles == "y" ]
then
    cat > ./themes/custom/"$machine_name"/"$machine_name".drush.inc << EOF
<?php
/**
 * @file
 * Drupal $theme_name Drush commands.
 */

use Drush\Log\LogLevel;
use Leafo\ScssPhp\Compiler;

/**
 * Implements hook_drush_command().
 */
function ${machine_name}_drush_command() {
  \$items['styles'] = [
    'description' => dt('Compile CSS stylesheets from SCSS.'),
  ];
  return \$items;
}

/**
 * Generates CSS stylesheets from SCSS.
 */
function drush_${machine_name}_styles() {
  \$compiler = new Compiler();
  \$compiler->setImportPaths(__DIR__ . '/scss');
  \$css = \$compiler->compile('@import "style.scss";');
  \$file = fopen(__DIR__ . '/css/style.css', 'w');
  if (fwrite(\$file, \$css)) {
    drush_log(dt('Styles was compiled successfully.'), LogLevel::SUCCESS);
  }
  else {
    drush_log(dt('Could not create a file with compiled styles.'), LogLevel::WARNING);
  }
  fclose(\$file);
}

EOF
    cat > ./themes/custom/"$machine_name"/composer.json << EOF
{
    "name": "drupal/$machine_name",
    "description": "$theme_name Bootstrap sub-theme.",
    "type": "drupal-custom-theme",
    "license": "GPL-2.0+",
    "require": {
        "bower-asset/bootstrap-sass": "^3.3",
        "drupal/bootstrap": "^3.6",
        "fxp/composer-asset-plugin": "^1.4",
        "leafo/scssphp": "^0.6.7"
    }
}

EOF
else
    cat > ./themes/custom/"$machine_name"/composer.json << EOF
{
    "name": "drupal/$machine_name",
    "description": "$theme_name Bootstrap sub-theme.",
    "type": "drupal-custom-theme",
    "license": "GPL-2.0+",
    "require": {
        "bower-asset/bootstrap-sass": "^3.3",
        "drupal/bootstrap": "^3.6",
        "fxp/composer-asset-plugin": "^1.4"
    }
}

EOF
fi
mkdir -p ./themes/custom/"$machine_name"/css
cat > ./themes/custom/"$machine_name"/css/.gitkeep << EOF

EOF
cat > ./themes/custom/"$machine_name"/package.json << EOF
{
  "name": "$machine_name",
  "version": "0.0.1",
  "devDependencies": {
    "breakpoint-sass": "^2.7.1",
    "browser-sync": "^2.18.8",
    "gulp": "^3.9.1",
    "gulp-autoprefixer": "^3.1.1",
    "gulp-clean-css": "^3.0.4",
    "gulp-combine-mq": "^0.4.0",
    "gulp-dest": "^0.2.3",
    "gulp-load-plugins": "^1.5.0",
    "gulp-notify": "^3.0.0",
    "gulp-rename": "^1.2.2",
    "gulp-sass": "^3.1.0",
    "gulp-sourcemaps": "^2.4.1",
    "gulp-util": "^3.0.8",
    "gulp-watch": "^4.3.11",
    "rimraf": "^2.6.1",
    "serve-static": "^1.12.1"
  },
  "scripts": {
    "start": "gulp",
    "build": "gulp sass",
    "postinstall": "node_modules/.bin/rimraf node_modules/**/*.info"
  },
  "private": true
}

EOF
cat > ./themes/custom/"$machine_name"/gulpfile.js << EOF
var gulp = require('gulp'),
  browsersync = require('browser-sync'),
  sass = require('gulp-sass'),
  sourcemaps = require('gulp-sourcemaps'),
  notify = require("gulp-notify"),
  watch = require('gulp-watch'),
  dest = require('gulp-dest'),
  combineMq = require('gulp-combine-mq'),
  cleanCSS = require('gulp-clean-css'),
  util = require('gulp-util'),
  rename = require('gulp-rename'),
  $ = require('gulp-load-plugins')();

var cssCleanLocation = ['./css/*.css', '!./css/*.min.css'];

/**
 * Start browsersync task and then watch files for changes
 */
gulp.task('browsersync', function () {
  browsersync.init({
    open: false,
    reloadDelay: 1,
    reloadOnRestart: true,
    files: cssCleanLocation,
    middleware: require("serve-static")("./")
  });
});

gulp.task('default', ['sass', 'browsersync'], function () {
  gulp.watch('./scss/**/*.scss', ['sass']);
  gulp.watch(cssCleanLocation,['clean-css']);
});

gulp.task('clean-css', function() {
  return gulp.src(cssCleanLocation)
    .pipe(cleanCSS({ compatibility: 'ie9' }, function(details) {
      console.log(details.name + ': ' + details.stats.originalSize);
      console.log(details.name + ': ' + details.stats.minifiedSize);
    }))
    .pipe(rename({ suffix: '.min' }))
    .pipe(gulp.dest('./css'));
});

gulp.task('sass', function () {
  return gulp.src('./scss/**/*.scss')
    .pipe(sourcemaps.init())
    .pipe(sass({
      outputStyle: 'nested',
      precision: 10,
      errLogToConsole: true
    }).on('error', sass.logError))
    .pipe(combineMq({ beautify: true }))
    .pipe($.autoprefixer({ browsers: ['last 2 versions', 'ie >= 9'] }))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('./css'))
    .pipe(browsersync.stream({ match: 'css/*.css' }))
});

EOF
echo "$theme_name" Bootstrap sub-theme was created successfully.
if [ -f "composer.lock" ]; then
    echo Run \'composer update drupal/"$machine_name"\' to install all theme dependencies.
fi
rm -rf ./tmp
