require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)

require 'test/unit'
require 'rack/test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'vitrine'

module VitrineTesting
  
  # Wrap the test run in mktimpdir where we will store our temp application
  def run(runner)
    Dir.mktmpdir("vitrine-tests") do | dir_path |
      @tempdir = dir_path
      super
    end
  ensure
    @tempdir = nil
  end
  
  def temporary_app_dir
    raise "Not within a tempdir block" unless @tempdir
    @tempdir
  end
  
  # Write a file out into 'public', creating the subdir tree
  def write_public(name)
    location = FileUtils.mkdir_p(File.dirname(File.join(@tempdir, 'public', name)))
    File.open(File.join(@tempdir, 'public', name), 'w') do | f |
      yield f
    end
  end
  
  # Return the vitrine default Vitrine app
  def app
    Vitrine::App.new.tap { |a| a.settings.set :root, @tempdir }
  end
end