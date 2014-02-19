require_relative 'helper'

class TestVitrineAssetCompiler < Test::Unit::TestCase
  include Rack::Test::Methods, VitrineTesting
  
  def app # overridden
    Vitrine::AssetCompiler.new.tap { |a| a.settings.set :root, @tempdir }
  end
  
  def test_compiles_coffeescript_to_js_when_addressed_by_js_extension
    write_public 'nice.coffee' do | f |
      f.puts 'alert "rockage!"'
    end
    
    get '/nice.js'
    
    assert_equal 200, last_response.status
    assert_equal 'text/javascript;charset=utf-8', last_response.content_type
    assert_not_nil last_response.headers['ETag'], 'Should set ETag for the compiled version'
    assert_equal 'public, must-revalidate', last_response['Cache-Control'], 'Should set cache-control'
    
    assert_include last_response.body, 'alert("rockage!")', 'Should include the compiled function'
    assert_include last_response.body, '//# sourceMappingURL=/nice.js.map', 'Should include the reference to the source map'
    
    last_line = last_response.body.split("\n").pop
    assert_include last_line, 'sourceMappingURL'
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
      "names"=>[], "mappings"=>"AAAA;AAAA,EAAA,KAAA,CAAM,UAAN,CAAA,CAAA;AAAA"}
    assert_equal ref, JSON.parse(last_response.body)
  end
  
  def test_invalid_coffeescript_creates_decent_error_alerts
    write_public 'faulty.coffee' do | f |
      f.puts 'function() { junked up }'
    end
    
    get '/faulty.js'
    
    assert_equal 'private', last_response.headers['Cache-Control'], "Should be cache busting"
    assert_equal 'no-cache', last_response.headers['Pragma'], "Should be cache busting with Pragma: no-cache"
    assert_nil last_response.headers['ETag'], 'Should send no etag across'
    
    assert_equal 200, last_response.status
    assert_equal 'text/javascript;charset=utf-8', last_response.content_type, "Should set JS content type"
    
    err = 'console.error("ExecJS::RuntimeError\n--> SyntaxError: :1:1: reserved word \"function\"")'
    assert_equal err, last_response.body
  end
  
  def test_caches_compiled_js_by_etag_and_responds_with_304_when_requested_again
    write_public 'nice.coffee' do | f |
      f.puts 'alert "rockage!"'
    end
    
    get '/nice.js'
    assert_equal 200, last_response.status
    assert_not_nil last_response['ETag']
    assert_equal 'public, must-revalidate', last_response['Cache-Control']
    
    etag = last_response.headers['ETag']
    get '/nice.js', {}, rack_env = {'HTTP_IF_NONE_MATCH' => etag}
    assert_equal 304, last_response.status
  end
  
  def test_compiles_scss_when_requested_as_css
    write_public '/les-styles-rococo/styles.scss' do | f |
      f.puts '.foo {'
      f.puts '.bar { font-size: 10px; }'
      f.puts '}'
    end
    
    get '/les-styles-rococo/styles.css'
    
    assert last_response.ok?
    assert_not_nil last_response.headers['ETag'], 'Should set ETag for the compiled version'
    assert_equal 'public, must-revalidate', last_response['Cache-Control'], 'Should set cache-control'
    
    assert_include last_response.body, '.foo .bar {'
    assert_include last_response.body, '*# sourceMappingURL=/les-styles-rococo/styles.css.map */'
    
    get '/les-styles-rococo/styles.css.map'
    
    assert last_response.ok?
    assert_equal "application/json;charset=utf-8", last_response.content_type
    resp = {"file"=>"styles.css",
       "mappings"=>"AACA,SAAK;EAAE,SAAS,EAAE,IAAI",
       "names"=>[],
       "sources"=>["/les-styles-rococo/styles.scss"],
       "version"=>3
    }
    assert_equal resp, JSON.parse(last_response.body)
  end
  
  def test_displays_decent_alerts_for_scss_errors
    write_public 'faulty.scss' do | f |
      f.puts '.foo {{ junkiness-factor: 24pem; }'
    end
    
    get '/faulty.css'
    
    assert_equal 200, last_response.status
    
    assert_equal 'private', last_response.headers['Cache-Control'], "Should be cache busting"
    assert_equal 'no-cache', last_response.headers['Pragma'], "Should be cache busting with Pragma: no-cache"
    assert_nil last_response.headers['ETag'], 'Should send no etag across'
    
    assert last_response.body.include?('body:before {'), 'Should include the generated element selector'
    assert last_response.body.include?('Sass::SyntaxError'), 'Should include the syntax error class'
  end
end
