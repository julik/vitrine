require_relative 'vitrine'
require 'rack-livereload'

module Vitrine::Server
  DEFAULTS = { root: Dir.getwd, port: 9292, :address => '127.0.0.1' }
  
  def self.check_dirs_present!(options)
    views = options[:root] + '/views'
    unless File.exist?(views) and File.directory?(views)
      $stderr.puts "WARNING: `views' directory not found under the current tree, you might want to create it"
    end
    
    public_folder = options[:root] + '/public'
    unless File.exist?(public_folder) and File.directory?(public_folder)
      $stderr.puts "ERROR: `public' directory not found under the current tree, you should create it. Vitrine won't run without it"
      exit 1
    end
  end
  
  # Builds the Rack application with all the wrappers
  def self.build_app(options)
    Rack::Builder.new do
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
  end
  
  # Pick a server handler engine and run the passed
  # app on it, honoring the passed options
  def self.start_server(app, options)
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
  
  # Run the server, largely stolen from Serve
  def self.start(passed_options = {})
    options = DEFAULTS.merge(passed_options)
    check_dirs_present!(options)
    
    $stderr.puts "Vitrine v.#{Vitrine::VERSION} booting in dev mode"
    app = build_app(options)
    start_server(app, options)
  end
end