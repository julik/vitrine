require 'pathname'
require 'json'

module Vitrine
  
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