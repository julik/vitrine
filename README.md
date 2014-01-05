A nimble web server one-liner for modern web-apps, a bit in the style of
[lineman](https://github.com/testdouble/lineman), [serve](https://github.com/visionmedia/serve),
another [serve](https://github.com/jlong/serve) and such. Will display your precious stuff on port 9292.

## Core idea of Vitrine

You want a server that will automatically wrap your CoffeeScript and SASS assets, and allow
some rudimentary templating. This is practically enough for putting together MVP prototypes,
especially as far as single-page apps go. You want this server to not coerce you into a specific
SCSS framework, you don't want to scaffold anything, you don't want to have any configs defined and
you hate running wizards. You also don't feel like buying any Mac applications which call out
to command-line compilers anyway.

If most of the above is true, Vitrine is just what you need.

## All you need is some `public`

Vitrine assumes that there are two directories under the current tree:
* `public` - for the JS, for CSS and SCSS and in general all the static files served straight out
* `views` - for the templates, in any Ruby templating format you have

## Automatic compilation

Vitrine is for **development**. It takes runtime compilation to 11 and beyound. Running tasks
is all fine and good when you build out the app for production, but when iterating on UI it's essential
to be able to just yank the file in there and carry on. THe compilation perks include:

* Any `.scss` file you shove into the `public` directory can be referenced as `.css` from your HTML.
  Ask for `foo.css` and `foo.scss` will be compiled on the fly.
* Any `.coffee` file you shove into the `public` directory can be references as `.js` from your HTML.
  Ask for `bar.js` and `bar.coffee` will be compiled on the fly.
* CoffeeScript files will have source-maps out of the box for pleasant browser debugging.
* Decent error messages will be shown for both invalid SCSS and invalid CoffeeScript.

## Asset caching

Succesfully compiled assets will be cached to save time on next reload, and ETagged based on their
mtime.

## Automatic Ruby template pickup

If you have the "views" directory available, Vitrine will try to pick up any usable file for any URL without extensions.
From there on, it's going to try to render it with the automatically picked template engine using the
standard Sinatra facilities. You can use HAML, LESS, Slim, ERB, Builder or anything else you like.

If you are writing an SPA, you can make a file called "catch_all.erb" which is going to be 
the fall-through template for all missing URLs without extension.

## Automatic reload via Guard

If your project already has a Guardfile, Vitrine will inject live-reloading hooks into your HTML using
[rack-livereload](https://github.com/johnbintz/rack-livereload), so you won't need browser extensions at all.

## Sensible caching

Vitrine will `etag` all the precompiled assets for faster reloading.

## Packaging and baking

At this point the best way to bake a Vitrine site is to crawl it externally, but we are going to implement
baking at some point. The idea is that you will end up upgrading the site to either a Node app or a Ruby app
with it's own `config.ru` - if after that point you still wish to use Vitrine, you can use it like a Rack
middleware.

## Using as a middleware

Most actions in Vitrine will fall through to 404, so `Vitrine::App` can be used as a middleware handler.
Put Vitrine into your application stack and it will complement your main application very nicely. But don't
forget to set `:root` - like so:

    use Vitrine::App.new do | vitrine |
      vitrine.settings.set :root => File.dirname(__FILE__)
    end

You can also only opt-in to the asset compilation system of Vitrine only once you have migrated your app from
the prototype stage into, say, a Sinatra application.

Note that you _need_ to have an `ExecJS` environment on your server for this:

    use Vitrine::AssetCompiler.new do | ac |
      vitrine.settings.set :root => File.dirname(__FILE__)
    end

## Contributing to vitrine
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Julik Tarkhanov. See LICENSE.txt for
further details.

