= vitrine

Is a very small, simple web server one-liner for modern web-apps, a bit in the style of
lineman, serve and such. Will display your precious stuff on port 4000.

== Core idea of Vitrine

You want a server that will automatically wrap your CoffeeScript and SASS assets, and allow
some rudimentary templating. This is practically enough for putting together MVP prototypes,
especially as far as single-page apps go. You want this server to not coerce you into a specific
SCSS framework, you don't want to scaffold anything, you don't want to have any configs defined and
you hate running wizards.

If most of the above is true, Vitrine is just what you need.

== How it works.

Vitrine assumes that there are two directories under the current tree:
* "public" - for the JS, for CSS and SCSS and in general all the static files server straight out
* "views" - for the templates

== Automatic compilation of SCSS

Any .scss file you shove into the "public" directory can be referenced as ".css" from your HTML code.
Vitrine will automatically compile it via SASS.

== Automatic compilation of CoffeeScript and source maps

Same thing applies to CoffeeScript - put .coffee files in "public", and reference them as .js files.
Vitrine will generate you source maps on the fly for pleasant browser debugging.

== Fallback to precompiled files

Both SCSS and JS links will fall through to the static versions if you cache them on the server or as a result of
asset compilation.

== Sensible error messages when automatic compilation fails

Vitrine will try to show you sensible errors if your SCSS or CoffeeScript fail to compile due to syntax errors and
the like.

== Do not recompile on every request

Succesfully compiled assets will be stored in your +/tmp+ to save time on next reload, and the
cache will be automatically flushed when the files are requested from the browser, but only if the modification
dates of the source files are different than before.

== Automatic Ruby template pickup

If you have the "views" directory available, Vitrine will try to pick up any usable file for any URL without extensions.
From there on, it's going to try to render it with the automatically picked template engine using the
standard Sinatra facilities. You can use HAML, LESS, Slim, ERB, Builder or anything else you like.

If you are writing an SPA, you can make a file called "catch_all.erb" which is going to be the fall-through template
for all missing URLs without extension.

== Automatic reload via Guard

If your project already has a Guardfile, Vitrine will inject live-reloading hooks into your HTML using
rack-livereload, so you won't need browser extensions at all.

== Sensible caching

Vitrine will `etag` all the precompiled assets for faster reloading.

== Packaging and baking

At this point the best way to bake a Vitrine site is to crawl it externally, but we are going to implement
baking at some point. The idea is that you will end up upgrading the site to either a Node app or a Ruby app
with it's own +config.ru+ - if after that point you still wish to use Vitrine, you can use it like a Rack
middleware.

== Contributing to vitrine
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2013 Julik Tarkhanov. See LICENSE.txt for
further details.

