require 'sinatra/base'
require 'coffee-script'
require 'sass'

require_relative 'version'

module Vitrine
  DEFAULTS = { root: Dir.getwd, port: 4000, host: '127.0.0.1' }
  
  def self.check_dirs_present!
    views = DEFAULTS[:root] + '/views'
    unless File.exist?(views) and File.directory?(views)
      $stderr.puts "WARNING: `views' directory not found under the current tree, you might want to create it"
    end
    
    public = DEFAULTS[:root] + '/public'
    unless File.exist?(views) and File.directory?(views)
      $stderr.puts "ERROR: `public' directory not found under the current tree, you might want to create it"
      exit 1
    end
  end
  
  # Will compile all SCSS and CoffeeScript, and also crawl the template tree and generate
  # HTML for all of the files in the template tree. The resulting files will be copied to
  # a directory of the build.
  # def self.build!
  
  # Run the server, largely stolen from Serve
  def self.run(options = DEFAULTS)
    check_dirs_present!
    
    app = Rack::Builder.new do
      use Rack::CommonLogger
      use Rack::ShowStatus
      use Rack::ShowExceptions
      
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
  
  # Use Rack::TryStatic to attempt to load files from public first
# require 'rack/contrib/try_static'
# use Rack::TryStatic,
#   :root => (settings.root + '/public'),
#   :urls => %w(/), :try => %w(.html index.html /index.html)
  
  # For extensionless things try to pick out the related templates
  # from the views directory, and render them with a default layout
  get /^([^\.]+)$/ do | extensionless_path |
    # Find the related view
    specific_view = extensionless_path + ".*"
    view_index = extensionless_path + "/index.*"
    
    # Glob for all the possibilites
    possibilites = [specific_view, view_index].map do | pattern |
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
      raise "No template for either #{specific_view.inspect} or #{view_index.inspect}"
    end
    
    # Auto-pick the template engine out of the extension
    template_engine = File.extname(template_path).gsub(/^\./, '')
    
    render(template_engine, File.read(template_path), :layout => get_layout)
  end
  
  def get_layout
    layouts = Dir.glob(File.join(settings.views, 'layout.*'))
    layouts.any? ? :layout : false
  end
  
  # Try to find SCSS replacement for missing CSS
  get /(.+)\.css/ do | basename |
    begin
      content_type 'text/css', :charset => 'utf-8'
      scss_source_path = File.join(settings.root, 'public', "#{basename}.scss")
      Sass.compile_file(scss_source_path)
    rescue Errno::ENOENT # Missing SCSS
      halt 404, "No such CSS or SCSS file found"
    rescue Exception => e # CSS syntax error or something alike
      # use smart CSS to inject an error message into the document
      'body:before { color: red; font-size: 2em; content: %s }' % [e.class, 
          "\n", "--> ", e.message].join.inspect
    end
  end
  
  # Try to find CoffeeScript replacement for missing JS
  get /(.+)\.js/ do | basename |
    # If this file is not found resort back to a coffeescript
    begin
      coffee_source = File.read(File.join(settings.root, 'public', "#{basename}.coffee"))
      content_type 'text/javascript', :charset => 'utf-8'
      CoffeeScript.compile(coffee_source)
    rescue Errno::ENOENT # Missing CoffeeScript
      halt 404, "No such JS file and could not find a .coffee replacement"
    rescue Exception => e # CS syntax error or something alike
      # inject it into the document
      'console.error(%s)' % [e.class, "\n", "--> ", e.message].join.inspect
    end
  end    
end