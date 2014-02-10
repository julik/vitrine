source "http://rubygems.org"

gem 'sinatra', '~> 1.4', require: 'sinatra/base'
gem 'coffee-script', '~> 2.2'

=begin

Now here we get into an issue. I am using Guard BIG TIME.
That means that Sass above this version will puke out because
the Sass authors wisely decided to burden me with having a version
of 'listen' even though I never use their watching features.

According to this:
https://rubygems.org/api/v1/dependencies?gems=sass
the last version of SASS which does not have a "listen" dependency
is '3.3.0.alpha.136', so this is what we are going to depend on
until at least this issue is resolved

https://github.com/nex3/sass/pull/982

Better still, SASS authors should remove filesystem watching or implement
it in a portable/vendored manner.
=end
gem 'sass', '3.3.0.rc.3'
gem 'rack-contrib'
gem 'rack-livereload'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'guard', '~> 2.2'
  gem 'guard-livereload'
  gem 'guard-test'
  
  gem "rdoc", "~> 3.12"
  gem "jeweler", "~> 1.8.7"
  gem 'rack-test'
  gem 'minitest'
  gem 'pry'
end
