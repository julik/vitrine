require 'sinatra/base'
require 'coffee-script'
require 'rack/contrib/try_static'
require 'sass'
require 'pathname'

require_relative 'version'
require_relative 'atomic_write'
require_relative 'sourcemaps'

# A little idiosyncrastic asset server.
# Does very simple things:
# * sensible detector for default pages (they render from Sinatra view templates)
# * automatic compilation of CoffeeScript and SASS assets - just request them with .js and .css
#  and Vitrine will find them and compile them for you on the spot
class Vitrine::App < Sinatra::Base
  set :static, true
  set :show_exceptions, false
  set :raise_errors, true
  set :root, File.expand_path(File.dirname(__FILE__))
  set :views, lambda { File.join(settings.root, "views") }
  
  # Returns the path to the public directory
  set :public_dir, lambda { File.join(settings.root, "public") }
  
  # Sets whether Vitrine will output messages about dynamic assets
  set :silent, true
  
  # For extensionless things try to pick out the related templates
  # from the views directory, and render them with a default layout.
  # If no template is found fallback to halting on 404
  # so that Vitrine can be cascaded from.
  get /^([^\.]+)$/ do | extensionless_path |
    render_template_or_static(extensionless_path)
  end
  
  # Allow "fake" form submits
  post /^([^\.]+)$/ do | extensionless_path |
    render_template_or_static(extensionless_path)
  end
  
  def render_template_or_static(extensionless_path)
    probable_html = extensionless_path + "/index.html"
    html_path = File.join(settings.public_dir, probable_html)
    if File.exist? html_path
      send_file html_path
    else
      render_template(extensionless_path)
    end
  end
  
  def render_template(extensionless_path)
    # Find the related view
    specific_view = extensionless_path + ".*"
    view_index = extensionless_path + "/index.*"
    
    # Catch-all template for HTML5 apps using pushState
    catch_all = "/catch_all.*"
    
    possible_globs = [specific_view, view_index, catch_all]
    
    # Glob for all the possibilites
    possibilites = possible_globs.map do | pattern |
      Dir.glob(File.join(settings.views, pattern))
    end.flatten.reject do | e |
      File.basename(e) =~ /^\./ # except invisibles and self-links
    end
    
    # Try the first template that has been found
    template_path = possibilites.shift
    
    # If nothing is found just bail
    unless template_path
      err = possible_globs.map{|e| e.inspect }.join(', ')
      halt 404, "No template found - tried #{err}"
    end
    
    relative_path = Pathname.new(template_path).relative_path_from(Pathname.new(settings.views))
    
    log "-> #{extensionless_path.inspect} : Rendering via template #{relative_path.to_s.inspect}"
    
    locals = {}
    # Auto-pick the template engine out of the extension
    template_engine = File.extname(template_path).gsub(/^\./, '')
    render(template_engine, File.read(template_path), :layout => get_layout, :locals => locals)
  end

  
  # Try to find SCSS replacement for missing CSS
  get /(.+)\.css/ do | basename |
    begin
      content_type 'text/css', :charset => 'utf-8'
      # TODO: has no handling for .sass
      scss_source_path = File.join(settings.root, 'public', "#{basename}.scss")
      mtime_cache(scss_source_path) do
        # TODO: Examine http://sass-lang.com/documentation/file.SASS_REFERENCE.html
        Sass.compile_file(scss_source_path, cache_location: '/tmp/vitrine/sass-cache')
      end
    rescue Errno::ENOENT # Missing SCSS
      halt 404, "No such CSS or SCSS file found"
    rescue Exception => e # CSS syntax error or something alike
      # Add a generated DOM element before <body/> to inject
      # a visible error message
      error_tpl = 'body:before { background: white; font-family: sans-serif; color: red; font-size: 14px; content: %s }'
      css_message = error_tpl % [e.class, "\n", "--> ", e.message].join.inspect
      
      halt 500, css_message
    end
  end
  
  # Generate a sourcemap for CoffeeScript files
  get /(.+)\.js\.map$/ do | basename |
    begin
      coffee_source = File.join(settings.root, 'public', "#{basename}.coffee")
      content_type 'application/json', :charset => 'utf-8'
      mtime_cache(coffee_source) do
        Vitrine.build_coffeescript_source_map_body(coffee_source, File.join(settings.root, 'public'))
      end
    rescue Errno::ENOENT # Missing CoffeeScript
      halt 404, "No coffeescript file found to generate the map for"
    rescue Exception => e # CS syntax error or something alike
      halt 400, 'Compliation of the related CoffeeScript file failed'
    end
  end
  
  # Try to find CoffeeScript replacement for missing JS
  get /(.+)\.js$/ do | basename |
    # If this file is not found resort back to a coffeescript
    begin
      coffee_source = File.join(settings.root, 'public', "#{basename}.coffee")
      content_type 'text/javascript'
      mtime_cache(coffee_source) do
        ["//# sourceMappingURL=#{basename}.js.map", CoffeeScript.compile(File.read(coffee_source))].join("\n")
      end
    rescue Errno::ENOENT # Missing CoffeeScript
      halt 404, "No such JS file and could not find a .coffee replacement"
    rescue Exception => e # CS syntax error or something alike
      # Inject the syntax error into the browser console
      console_message = 'console.error(%s)' % [e.class, "\n", "--> ", e.message].join.inspect
      halt 500, console_message
    end
  end
  
  require 'fileutils'
  
  def mtime_cache(path, &blk)
    # Mix in the request URL into the cache key so that we can hash
    # .map sourcemaps and .js compiles based off of the same file path
    # and mtime
    key = [File.expand_path(path), File.mtime(path), request.path_info, settings.root]
    cache_sha = Digest::SHA1.hexdigest(Marshal.dump(key))
    
    # Store in a temp dir
    FileUtils.mkdir_p '/tmp/vitrine'
    p = '/tmp/vitrine/%s' % cache_sha
    if File.exist?(p)
      etag File.mtime(p)
      File.read(p)
    else
      yield.tap do | body |
        Vitrine.atomic_write(p) do |f|
          log "---> Recompiling #{path} for #{request.path_info}"
          f.write body
        end
        etag File.mtime(p)
      end
    end
  end
  
  def get_layout
    layouts = Dir.glob(File.join(settings.views, 'layout.*'))
    layouts.any? ? :layout : false
  end
  
  def log(msg)
    $stderr.puts(msg) unless settings.silent?
  end
end