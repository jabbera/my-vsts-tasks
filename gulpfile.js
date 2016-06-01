var del = require("del");
var gulp = require("gulp");
var gulpUtil = require('gulp-util');
var path = require("path");
var shell = require("shelljs");
var spawn = require('child_process').spawn;
var fs = require('fs-extra');
var pkgm = require('./package');
var replace = require('gulp-token-replace');
var debug = require('gulp-debug');

var buildRoot = "_build";
var packageRoot = "_package";
var extnBuildRoot = "_build/Extensions/";
var sourcePaths = "Extensions/**/*";
		
gulp.task("clean", function() {
    return del([buildRoot, packageRoot]);
});

gulp.task("compile", ["clean"], function(done) {
    return gulp.src(sourcePaths, { base: "." }).pipe(gulp.dest(buildRoot));
});

gulp.task("build", ["compile"], function() {
    //Foreach task under extensions copy common modules
    fs.readdirSync(extnBuildRoot).filter(function (file) {
        return fs.statSync(path.join(extnBuildRoot, file)).isDirectory() && file != "Common";
    }).forEach(copyCommonModules);
});

gulp.task("package", ["token-replace"], function() {
    fs.readdirSync(extnBuildRoot).filter(function (file) {
        return fs.statSync(path.join(extnBuildRoot, file)).isDirectory() && file != "Common";
    }).forEach(createVsixPackage);
});

gulp.task("token-replace", ["token-replace-bootstrap"], function(){	
  var config = require("./" + buildRoot + "/config.json");
  return gulp.src([
		extnBuildRoot + "/**/*.json",
		extnBuildRoot + "/**/*.ps1"
	])
    .pipe(replace({tokens:config}))
    .pipe(gulp.dest(extnBuildRoot));
	
});

gulp.task("token-replace-bootstrap", ["build"], function(){	
  var config = require("./config.bootstrap.json");     
  config.tokens["Minor"] = getMinorVersion();
  return gulp.src("./config.json")
    .pipe(replace({tokens:config}))
    .pipe(gulp.dest(buildRoot));	
});

var copyCommonModules = function(extensionName) {

    var commonDeps = require('./common.json');
    var commonSrc = path.join(__dirname, 'Extensions/Common');
    var currentExtnRoot = path.join(__dirname, extnBuildRoot, extensionName);

    return gulp.src(path.join(currentExtnRoot, '**/task.json'))
        .pipe(pkgm.copyCommonModules(currentExtnRoot, commonDeps, commonSrc));
}

var createVsixPackage = function(extensionName) {
    var extnOutputPath = path.join(packageRoot, extensionName);
    var extnManifestPath = path.join(extnBuildRoot, extensionName, "Src");
    del(extnOutputPath);
    shell.mkdir("-p", extnOutputPath);
    var packagingCmd = "tfx extension create --manifeset-globs vss-extension.json --root " + extnManifestPath + " --output-path " + extnOutputPath;
    executeCommand(packagingCmd, function() {});
}

var executeCommand = function(cmd, callback) {
    shell.exec(cmd, {silent: true}, function(code, output) {
       if(code != 0) {
           console.error("command failed: " + cmd + "\nManually execute to debug");
       }
       else {
           callback();
       }
    });
}

var getMinorVersion = function()
{
  var now = new Date();
  var start = new Date(now.getFullYear(), 0, 0);
  var diff = now - start;
  var oneDay = 1000 * 60 * 60 * 24;
  var day = Math.floor(diff / oneDay);
  var twoDigitYear = now.getFullYear().toString().substr(2,2);
  return twoDigitYear.toString() + day.toString();
}

gulp.task("default", ["build"]);