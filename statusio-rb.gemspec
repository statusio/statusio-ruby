# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statusio/rb/version'

Gem::Specification.new do |spec|
  spec.name = 'statusio'
  spec.version = StatusioClient::VERSION
  spec.authors = ['Status.io']
  spec.email = ['hello@status.io']

  spec.summary = 'Ruby library wrapper for Status.io'
  spec.description = 'Ruby library wrapper for Status.io - A Complete Status Platform - Status pages, incident tracking, subscriber notifications and more'
  spec.homepage = 'https://status.io'

=begin
	# Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
	# delete this section to allow pushing this gem to any host.
	if spec.respond_to?(:metadata)
		spec.metadata['allowed_push_host'] = 'TODO: Set to \'http://mygemserver.com\''
	else
		raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
	end
=end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
