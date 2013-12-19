require 'pathname'
require 'json'

module Vitrine
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