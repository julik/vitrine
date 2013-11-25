require 'helper'

class TestVitrine < Test::Unit::TestCase
  include Rack::Test::Methods
  
  # Wrap the test run in mktimpdir where we will store our temp application
  def run(runner)
    Dir.mktmpdir("vitrine-tests") do | dir_path |
      @tempdir = dir_path
      super
    end
  end
  
  def write_public(name)
    FileUtils.mkdir_p @tempdir + '/public'
    File.open(File.join(@tempdir, 'public', name), 'w') do | f |
      yield f
    end
  end
  
  def app
    vitrine = Vitrine::App.new
    vitrine.settings.set :root, @tempdir
    vitrine
  end
  
  def test_fetch_index_without_index_should_404
    get '/'
    assert_equal 404, last_response.status, "Should have responded with 404 since there is no template"
  end
  
  def test_fetch_index_via_template_renders_index_template
    FileUtils.mkdir_p File.join(@tempdir, 'views')
    File.open(File.join(@tempdir, 'views', 'index.erb'), 'w') do | f |
      f.write '<%= RUBY_VERSION %>'
    end
    
    get '/'
    assert last_response.ok?, "Should have responded with 200 since it picks up a template"
    assert_equal RUBY_VERSION, last_response.body
  end
  
  def test_fetch_subdir_with_index_template_in_subfolder_picks_up_index_template
    FileUtils.mkdir_p File.join(@tempdir, 'views/things')
    File.open(File.join(@tempdir, 'views/things/index.erb'), 'w') do | f |
      f.write '<%= RUBY_VERSION %>'
    end
    
    get '/things'
    
    assert last_response.ok?, "Should have responded with 200 since it picks up a template"
    assert_equal RUBY_VERSION, last_response.body
  end
  
  def test_fetch_subdir_without_extension_can_address_template
    FileUtils.mkdir_p File.join(@tempdir, 'views')
    File.open(File.join(@tempdir, 'views', 'things.erb'), 'w') do | f |
      f.write '<%= RUBY_VERSION %>'
    end
    
    get '/things'
    assert_equal 200, last_response.status, "Should have responded with 200 since it picks up a template"
    assert_equal RUBY_VERSION, last_response.body
  end
  
  def test_fetches_index_in_root_if_present
    write_public 'index.html' do | f |
      f.write '<!DOCTYPE html><html></html>'
    end
    
    get '/'
    assert last_response.ok?, "Should have fetched the index.html"
  end
  
#  def test_fetches_index_in_subdirectory_if_present
#    write_public 'items/index.html' do | f |
#      f.write 'this just in'
#    end
#    
#    get '/items'
#    assert last_response.ok?, "Should have responded with 404 since there is no template"
#    assert_equal 'this just in', last_response.body
#  end

  def test_passes_coffeescript_as_raw_file
    write_public 'nice.coffee' do | f |
      f.write 'alert "rockage!"'
    end
    
    get '/nice.coffee'
    assert_equal 'application/octet-stream', last_response.content_type
    assert_equal 'alert "rockage!"', last_response.body
  end
  
  def test_compiles_coffeescript_to_js_when_addressed_by_js_extension
    write_public 'nice.coffee' do | f |
      f.puts 'alert "rockage!"'
    end
    
    get '/nice.js'
    
    assert_not_nil last_response.headers['ETag'], 'Should set ETag for the compiled version'
    assert_equal 200, last_response.status
    assert_equal 'text/javascript;charset=utf-8', last_response.content_type
    
    assert last_response.body.include?( 'alert("rockage!")'), 'Should include the compiled function'
    assert last_response.body.include?( '//# sourceMappingURL=/nice.js.map'),
      'Should include the reference to the source map'
  end
  
  def test_compiles_coffeescript_sourcemap
    
    FileUtils.mkdir_p File.join(@tempdir, 'public', 'js')
    
    write_public 'js/nice.coffee' do | f |
      f.puts 'alert "rockage!"'
    end
    
    # Sourcemap will only ever get requested AFTER the corresponding JS file
    get '/js/nice.js'
    assert last_response.ok?
    
    get '/js/nice.js.map'
    ref = {"version"=>3, "file"=>"", "sourceRoot"=>"", "sources"=>["/js/nice.coffee"], 
      "names"=>[], "mappings"=>"AAAA;CAAA,CAAA,GAAA,KAAA;CAAA"}
    assert_equal ref, JSON.parse(last_response.body)
  end
  
  def test_sends_vanilla_js_if_its_present
    write_public 'vanilla.js' do | f |
      f.puts 'vanilla();'
    end
    
    get '/vanilla.js'
    assert_equal 200, last_response.status
    assert_equal "vanilla();\n", last_response.body
  end
  
  def test_invalid_coffeescript_creates_decent_error_alerts
    write_public 'faulty.coffee' do | f |
      f.puts 'function() { junked up }'
    end
    
    get '/faulty.js'
    
    assert_equal 500, last_response.status
    assert_equal 'text/javascript;charset=utf-8', last_response.content_type
    err = 'console.error("ExecJS::RuntimeError\n--> SyntaxError: reserved word \"function\"")'
    assert_equal err, last_response.body
  end
  
  def test_caches_compiled_js_by_etag_and_responds_with_304_when_requested_again
    write_public 'nice.coffee' do | f |
      f.puts 'alert "rockage!"'
    end
    
    get '/nice.js'
    assert_equal 200, last_response.status
    assert_not_nil last_response.headers['ETag']
    
    etag = last_response.headers['ETag']
    get '/nice.js', {}, rack_env = {'HTTP_IF_NONE_MATCH' => etag}
    assert_equal 304, last_response.status
  end
  
  def test_sends_vanilla_css_if_present
    write_public 'vanilla.css' do | f |
      f.write '/* vanilla CSS kode */'
    end
    
    get '/vanilla.css'
    
    assert last_response.ok?
    assert_equal '/* vanilla CSS kode */', last_response.body
  end
  
  def test_compiles_scss_when_requested_as_css
    write_public 'styles.scss' do | f |
      f.puts '.foo {'
      f.puts '.bar { font-size: 10px; }'
      f.puts '}'
    end
    
    get '/styles.css'
    
    assert last_response.ok?
    assert_not_nil last_response.headers['ETag'], 'Should set ETag for the compiled version'
    assert last_response.body.include?('.foo .bar {'), 'Should have compiled the CSS rule'
  end
  
  def test_displays_decent_alerts_for_scss_errors
    write_public 'faulty.scss' do | f |
      f.puts '.foo {{ junkiness-factor: 24pem; }'
    end
    
    get '/faulty.css'
    
    assert_equal 500, last_response.status
    assert last_response.body.include?('body:before {'), 'Should include the generated element selector'
    assert last_response.body.include?('Sass::SyntaxError'), 'Should include the syntax error class'
  end
end
