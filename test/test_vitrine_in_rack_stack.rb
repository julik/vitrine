require 'helper'
require 'rack/lobster'

class TestVitrineInRackStack < Test::Unit::TestCase
  include Rack::Test::Methods, VitrineTesting
  
  def app
    td = temporary_app_dir
    outer = Rack::Builder.new do
      use Vitrine::App do | v | 
        v.settings.set root: td 
      end
      map "/lobster" do
        run Rack::Lobster.new
      end
    end
    outer.to_app
  end
  
  def test_lobster
    get '/lobster'
    assert last_response.ok?
    assert_match /Lobstericious/, last_response.body, "Should have forwarded to downstream Lobster"
  end
  
  def test_fetch_js
    write_public('hello.coffee') do | f |
      f << 'window.alert("Hello Coffee")'
    end
    
    get '/hello.js'
    assert last_response.ok?
    assert_include last_response.body, 'window.alert("Hello Coffee")', "Should include the JS fragment"
  end
end