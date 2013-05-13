gem-insturl
===========

This is a [rubygems](http://rubygems.org/) plugin that installs a gem from a URL.

It add a *insturl* command to *gem*.

Installation
-------------

`gem install gem-insturl`

Usage
------

Examples:

* gem **insturl** http://.../foo.git
* gem **insturl** http://.../foo.gem
* gem **insturl** http://.../foo.tar.gz

If --git is specified or the URL ends with .git, it is treated as a git repository and cloned with `git`;
otherwise it is treated as a package file and downloaded with `wget`. You must have git or wget installed in PATH.

If --git is omitted and the URL ends with .gem, it is installed with `gem install` directly after download.

If the URL is a repository or a .zip/.tar.gz package, it must have a valid *gemspec* file in top level directory.
A gem is built from the gemspec file and then installed.

Requirements
-------------

Ruby *>= 1.8.7* is tested. Rubygems *>= 1.3.7* is tested.
