require 'rbconfig'

source 'https://rubygems.org'

gem 'rest-client', '=1.8.0'

group :test do
	gem 'rspec'
	gem 'rake'
	gem 'win32console' if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
	gem 'httparty'
end

# Specify your gem's dependencies in statusio.gemspec
gemspec
