require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)

require 'test/unit'
require 'rack/test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'vitrine'
