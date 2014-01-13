require 'pathname'
require 'json'

module Vitrine
  
  # We need to override the Sass importer
  # so that it gives us URLs relative to the server root for sourcemaps
  class SassImporter < Sass::Importers::Filesystem
    def public_url(of_filesystem_path)
      # Importer defines a basic attribute called "root" which we set when initializing
      # We have to return the server-relative URL of the path from here
      '/' + Pathname.new(of_filesystem_path).relative_path_from(Pathname.new(root)).to_s
    end
  end
  
  # Compile a SASS/SCSS file to CSS
  def self.compile_sass_and_sourcemap(scss_path, public_folder_path)
    # Compute the paths relative to the webserver public root
    scss_uri = '/' + Pathname.new(scss_path).relative_path_from(Pathname.new(public_folder_path)).to_s
    css_uri = scss_uri.gsub(/\.scss$/, '.css')
    sourcemap_uri = css_uri + '.map'
    
    engine_opts = {importer: SassImporter.new(public_folder_path), sourcemap: true, cache: false}
    map_options = {css_path: css_uri, sourcemap_path: sourcemap_uri }
    
    engine = Sass::Engine.for_file(scss_path, engine_opts)
    
    # Determine the sourcemap URL for the SASS file
    rendered, mapping = engine.render_with_sourcemap(sourcemap_uri)
    
    # Serialize the sourcemap
    # We need to pass css_uri: so that the generated sourcemap refers to the
    # file that can be pulled of the server as opposed to a file on the filesystem
    sourcemap_body = mapping.to_json(map_options)
    
    # We are using a pre-release version of SASS which still had old sourcemap reference
    # syntax, so we have to fix it by hand
    chunk = Regexp.escape('/*@ sourceMappingURL')
    replacement = '/*# sourceMappingURL'
    re = /^#{chunk}/
    [rendered.gsub(re,replacement), sourcemap_body]
  end
  
  # Compile SASS and return the source map only
  def self.compile_sass_source_map(scss_path, public_folder_path)
    css, map = compile_sass_and_sourcemap(scss_path, public_folder_path)
    map
  end
  
  # Compiles SASS and it's sourcemap and returns the CSS only
  def self.compile_sass(scss_path, public_folder_path)
    css, map = compile_sass_and_sourcemap(scss_path, public_folder_path)
    css
  end
  
  # Compile a script (String or IO) to JavaScript.
  # This is a version lifted from here
  # https://github.com/josh/ruby-coffee-script/blob/114b65b638f66ba04b60bf9c24b54360260f9898/lib/coffee_script.rb
  # which propagates error line
  def self.compile_coffeescript(script, options = {})
    script = script.read if script.respond_to?(:read)

    if options.key?(:bare)
    elsif options.key?(:no_wrap)
      options[:bare] = options[:no_wrap]
    else
      options[:bare] = false
    end

    wrapper = <<-WRAPPER
      (function(script, options) {
        try {
          return CoffeeScript.compile(script, options);
        } catch (err) {
          if (err instanceof SyntaxError && err.location) {
            throw new SyntaxError([options.filename, err.location.first_line + 1, err.location.first_column + 1].join(":") + ": " + err.message)
          } else {
            throw err;
          }
        }
      })
    WRAPPER
    CoffeeScript::Source.context.call(wrapper, script, options)
  end
  
  # Compile a CS source map.
  # TODO: this method should be married to the method that compiles the source code itself
  def self.build_coffeescript_source_map_body(full_coffeescript_file_path, public_folder_path)
    
    script = File.read(full_coffeescript_file_path)
    
    # We need to feed paths ON THE SERVER so that the browser can connect the coffee file, the map and the JS file
    # - specify coffee source file explicitly (see http://coffeescript.org/documentation/docs/sourcemap.html#section-8)
    # The paths need to be slash-prepended (server-absolute)
    relative_path = '/' + Pathname.new(full_coffeescript_file_path).relative_path_from(Pathname.new(public_folder_path)).to_s
    relative_js_path = '/' + relative_path.gsub(/\.coffee$/, '.js')
    
    options = {sourceMap: true}
    
    # coffee requires filename option to work with source maps (see http://coffeescript.org/documentation/docs/coffee-script.html#section-4)
    options[:filename] = relative_js_path
    options[:sourceFiles] = [relative_path]
    
    CoffeeScript.compile(script, options)["v3SourceMap"]
  end
end