require 'sinatra/base'
require 'coffee-script'
require 'rack/contrib/try_static'
require 'sass'
require 'pathname'
require 'fileutils'

require_relative 'version'
require_relative 'atomic_write'
require_relative 'sourcemaps'
require_relative 'asset_compiler'

# A little idiosyncrastic asset server.
# Does very simple things:
# * sensible detector for default pages (they render from Sinatra view templates)
# * automatic compilation of CoffeeScript and SASS assets - just request them with .js and .css
#  and Vitrine will find them and compile them for you on the spot
class Vitrine::App < Sinatra::Base
  
  set :show_exceptions, false
  set :raise_errors, true
  
  # Sets whether Vitrine will output messages about dynamic assets
  set :silent, true
  set :public_folder, ->{ File.join(settings.root, 'public') } 
  
  use Vitrine::AssetCompiler
  
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
    
    html_path = File.join(settings.public_folder, probable_html)
    if File.exist? html_path
      # Might want to investigate...
      # https://github.com/elitheeli/sinatra-index/blob/master/lib/sinatra-index.rb
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
    
    # If nothing is found try downstream or bail
    unless template_path
      err = possible_globs.map{|e| e.inspect }.join(', ')
      if @app
        return forward
      else
        halt 404, "No template found - tried #{err}, and no downstream Rack handler present"
      end
    end
    
    relative_path = Pathname.new(template_path).relative_path_from(Pathname.new(settings.views))
    
    log "-> #{extensionless_path.inspect} : Rendering via template #{relative_path.to_s.inspect}"
    
    locals = {}
    # Auto-pick the template engine out of the extension
    template_engine = File.extname(template_path).gsub(/^\./, '')
    render(template_engine, File.read(template_path), :layout => get_layout, :locals => locals)
  end
  
  
  
  def get_layout
    layouts = Dir.glob(File.join(settings.views, 'layout.*'))
    layouts.any? ? :layout : false
  end
  
  def log(msg)
    $stderr.puts(msg) unless settings.silent?
  end
end