# The part of Vitrine responsible for SASS and CoffeeScript
# compilation and caching. By default it will assume your
# public directory is set on the inner app in the Rack stack,
# and can be retreived using the standard Sinatra settings
# protocol, like so:
#
#   @app.settings.public_folder
#
# However, you can also set this setting on the app object using the
# AssetCompiler#public_dir accessor.
#   
#  use Vitrine::AssetCompiler do | compiler |
#    compiler.public_dir = File.dirname(__FILE__) + '/public'
#  end
#
# This allows you to use the asset compiler when the inner app 
# is not a Sinatra application.
#
# Obviously, the usual limitation apply for this kind of workflow -
# you pretty much have to have an ExecJS env on yourserver, or else...
class Vitrine::AssetCompiler < Sinatra::Base
  set :show_exceptions, false
  set :raise_errors, true
  
  # Try to find SCSS replacement for missing CSS
  get /(.+)\.css/ do | basename |
    begin
      content_type 'text/css', :charset => 'utf-8'
      # TODO: has no handling for .sass
      scss_source_path = File.join(get_public, "#{basename}.scss")
      mtime_cache(scss_source_path) do
        # TODO: Examine http://sass-lang.com/documentation/file.SASS_REFERENCE.html
        # It already has provisions for error display, among other things
        Sass.compile_file(scss_source_path, cache_location: '/tmp/vitrine/sass-cache')
      end
    rescue Errno::ENOENT # Missing SCSS
      forward_or_halt "No such CSS or SCSS file found"
    rescue Exception => e # CSS syntax error or something alike
      # Add a generated DOM element before <body/> to inject
      # a visible error message
      error_tpl = 'body:before {
        background: white; padding: 3px; font-family: monospaced; color: red; 
        font-size: 14px; content: %s }'
      css_message = error_tpl % [e.class, "\n", "--> ", e.message].join.inspect
      # If we halt with 500 this will not be shown as CSS
      halt 200, css_message
    end
  end
  
  # Generate a sourcemap for CoffeeScript files
  get /(.+)\.js\.map$/ do | basename |
    begin
      coffee_source = File.join(get_public, "#{basename}.coffee")
      content_type 'application/json', :charset => 'utf-8'
      mtime_cache(coffee_source) do
        Vitrine.build_coffeescript_source_map_body(coffee_source, get_public)
      end
    rescue Errno::ENOENT # Missing CoffeeScript
      forward_or_halt "No coffeescript file found to generate the map for"
    rescue Exception => e # CS syntax error or something alike
      halt 400, 'Compliation of the related CoffeeScript file failed'
    end
  end
  
  # Try to find CoffeeScript replacement for missing JS
  get /(.+)\.js$/ do | basename |
    # If this file is not found resort back to a coffeescript
    begin
      coffee_source = File.join(get_public, "#{basename}.coffee")
      content_type 'text/javascript'
      mtime_cache(coffee_source) do
        source_body = File.read(coffee_source)
        [
          "//# sourceMappingURL=#{basename}.js.map", 
          CoffeeScript.compile(source_body)
        ].join("\n")
      end
    rescue Errno::ENOENT # Missing CoffeeScript
      forward_or_halt "No such JS file and could not find a .coffee replacement"
    rescue Exception => e # CS syntax error or something alike
      # Inject the syntax error into the browser console
      console_message = 'console.error(%s)' % [e.class, "\n", "--> ", e.message].join.inspect
      halt 500, console_message
    end
  end
  
  def mtime_cache(path, &blk)
    # Mix in the request URL into the cache key so that we can hash
    # .map sourcemaps and .js compiles based off of the same file path
    # and mtime
    key = [File.expand_path(path), File.mtime(path), request.path_info, get_public]
    cache_sha = Digest::SHA1.hexdigest(Marshal.dump(key))
    
    # Store in a temp dir
    FileUtils.mkdir_p '/tmp/vitrine'
    p = '/tmp/vitrine/%s' % cache_sha
    
    # Only write it out unless a file with the same SHA does not exist
    unless File.exist?(p)
      Vitrine.atomic_write(p) do |f|
        log "---> Recompiling #{path} for #{request.path_info}"
        f.write(yield)
      end
    end
    
    # And send out the file that's been written
    last_modified(File.mtime(p))
    etag File.mtime(p).to_i.to_s
    File.read(p)
  end
  
  attr_accessor :public_dir
  
  # Get path to the public directory, trying (in order:)
  # self.public_dir reader
  # the inner app's public_folder setting
  # my own public_folder setting
  def get_public
    inner_public = if @app && @app.respond_to?(:settings)
      @app.settings.public_folder
    else
      nil
    end
    choices = [@public_dir, inner_public, settings.public_dir]
    choices.compact.shift
  end
  
  def forward_or_halt msg
    if @app
      log "Forwarding, #{msg} -> pub #{get_public.inspect}"
      forward 
    else
      halt 404, msg
    end
  end
  
  def log(mgs)
    env['captivity.logger'].debug(msg) if env['captivity.logger']
  end
end

