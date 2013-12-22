require 'helper'

class TestVitrine < Test::Unit::TestCase
  include Rack::Test::Methods, VitrineTesting
  
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
  
  def test_fetches_index_in_subdirectory_if_present
    write_public 'items/index.html' do | f |
      f.write 'this just in'
    end
    
    get '/items'
    assert last_response.ok?, "Should have responded with 404 since there is no template"
    assert_equal 'this just in', last_response.body
  end

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
    assert_include last_response.body, 'alert("rockage!")', 'Should include the compiled function'
  end
  
  
  def test_sends_vanilla_css_if_present
    write_public 'vanilla.css' do | f |
      f.write '/* vanilla CSS kode */'
    end
    
    get '/vanilla.css'
    
    assert last_response.ok?
    assert_equal '/* vanilla CSS kode */', last_response.body
  end
  
  
  def test_sends_vanilla_js_if_its_present
    write_public 'vanilla.js' do | f |
      f.puts 'vanilla();'
    end
    
    get '/vanilla.js'
    assert_equal 200, last_response.status
    assert_equal "vanilla();\n", last_response.body
  end
end
