lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'golumn/version'

Gem::Specification.new do |spec|
  spec.name          = 'golumn'
  spec.version       = Golumn::VERSION
  spec.authors       = ['Maddie Schipper']
  spec.email         = ['maddie@schipper.dev']

  spec.summary       = 'Logging Gem'
  spec.homepage      = 'https://github.com/maddiesch/golumn'

  spec.metadata['allowed_push_host'] = ''

  spec.files         = Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-cloudwatchlogs', '>= 1.24.0', '< 2.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
end
