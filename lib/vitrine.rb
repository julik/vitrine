require 'sinatra/base'
require 'coffee-script'
#require 'coffee-script-source'
require 'sass'
require 'pathname'

require_relative 'version'
require_relative 'atomic_write'
require_relative 'sourcemaps'

module Vitrine
  DEFAULTS = { root: Dir.getwd, port: 4000, host: '127.0.0.1' }
  
  def self.check_dirs_present!
    views = DEFAULTS[:root] + '/views'
    unless File.exist?(views) and File.directory?(views)
      $stderr.puts "WARNING: `views' directory not found under the current tree, you might want to create it"
    end
    
    public_dir = DEFAULTS[:root] + '/public'
    unless File.exist?(public_dir) and File.directory?(public_dir)
      $stderr.puts "ERROR: `public' directory not found under the current tree, you should create it. Vitrine won't run without it"
      exit 1
    end
  end
  
  # Run the server, largely stolen from Serve
  def self.run(options = DEFAULTS)
    check_dirs_present!
    
    app = Rack::Builder.new do
      use Rack::ShowStatus
      use Rack::ShowExceptions
      
      guardfile_path = options[:root] + '/Guardfile'
      if File.exist?(guardfile_path)
        $stderr.puts "Attaching LiveReload via Guardfile at #{guardfile_path.inspect}"
        # Assume livereload is engaged
        use Rack::LiveReload
      else
        $stderr.puts "No Guardfile found, so there won't be any livereload injection"
      end
      
      vitrine = Vitrine::App.new
      vitrine.settings.set :root, options[:root]
      run vitrine
    end
    
    begin
      # Try Thin
      thin = Rack::Handler.get('thin')
      thin.run app, :Port => options[:port], :Host => options[:address] do |server|
        puts "Thin #{Thin::VERSION::STRING} available at http://#{options[:address]}:#{options[:port]}"
      end
    rescue LoadError
      begin
        # Then Mongrel
        mongrel = Rack::Handler.get('mongrel')
        mongrel.run app, :Port => options[:port], :Host => options[:address] do |server|
          puts "Mongrel #{Mongrel::Const::MONGREL_VERSION} available at http://#{options[:address]}:#{options[:port]}"
        end
      rescue LoadError
        # Then WEBrick
        puts "Install Mongrel or Thin for better performance."
        webrick = Rack::Handler.get('webrick')
        webrick.run app, :Port => options[:port], :Host => options[:address] do |server|
          trap("INT") { server.shutdown }
        end
      end
    end
  end
end

require 'rack-livereload'

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
  
 
  
  # For extensionless things try to pick out the related templates
  # from the views directory, and render them with a default layout
  get /^([^\.]+)$/ do | extensionless_path |
    render_template(extensionless_path)
  end
  
  
  # Allow "fake" form submits
  post /^([^\.]+)$/ do | extensionless_path |
    render_template(extensionless_path)
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
      e =~ /\.DS_Store/ # except DS_Store
    end.reject do | e |
      e =~ /(\.+)$/ # and except directory self-links
    end
    
    # Try the first template that has been found
    template_path = possibilites.shift
    
    # If nothing is found just bail
    unless template_path
      err = possible_globs.map{|e| e.inspect }.join(', ')
      raise "No template found - tried #{err}"
    end
    
    relative_path = Pathname.new(template_path).relative_path_from(Pathname.new(settings.views))
    
    $stderr.puts "-> #{extensionless_path.inspect} : Rendering via template #{relative_path.to_s.inspect}"
    
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
      mtime_cache(scss_source_path) { Sass.compile_file(scss_source_path) }
    rescue Errno::ENOENT # Missing SCSS
      halt 404, "No such CSS or SCSS file found"
    rescue Exception => e # CSS syntax error or something alike
      # use smart CSS to inject an error message into the document
      'body:before { color: red; font-size: 2em; content: %s }' % [e.class, 
          "\n", "--> ", e.message].join.inspect
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
      # inject it into the document
      'console.error(%s)' % [e.class, "\n", "--> ", e.message].join.inspect
    end
  end
  
  # Try to find CoffeeScript replacement for missing JS
  get /(.+)\.js$/ do | basename |
    # If this file is not found resort back to a coffeescript
    begin
      coffee_source = File.join(settings.root, 'public', "#{basename}.coffee")
      content_type 'text/javascript', :charset => 'utf-8'
      mtime_cache(coffee_source) do
        ["//# sourceMappingURL=#{basename}.js.map", CoffeeScript.compile(File.read(coffee_source))].join("\n")
      end
    rescue Errno::ENOENT # Missing CoffeeScript
      halt 404, "No such JS file and could not find a .coffee replacement"
    rescue Exception => e # CS syntax error or something alike
      # inject it into the document
      'console.error(%s)' % [e.class, "\n", "--> ", e.message].join.inspect
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
    begin
      File.read(p)
    rescue Errno::ENOENT => e
      Vitrine.atomic_write(p) do |f|
        $stderr.puts "---> Recompiling #{path} for #{request.path_info}"
        f.write(yield)
      end
      retry
    end
  end
  
  def get_layout
    layouts = Dir.glob(File.join(settings.views, 'layout.*'))
    layouts.any? ? :layout : false
  end
  
end