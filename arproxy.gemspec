$:.push File.expand_path('../lib', __FILE__)
require 'arproxy/version'

Gem::Specification.new do |spec|
  spec.name              = 'arproxy'
  spec.version           = Arproxy::VERSION
  spec.summary           = 'A proxy layer between ActiveRecord and database adapters'
  spec.description       = 'Arproxy is a proxy layer that allows hooking into ActiveRecord query execution and injecting custom processing'
  spec.files             = Dir.glob('lib/**/*.rb')
  spec.author            = 'Issei Naruta'
  spec.email             = 'mimitako@gmail.com'
  spec.homepage          = 'https://github.com/cookpad/arproxy'
  spec.license           = 'MIT'
  spec.require_paths     = ['lib']

  spec.add_dependency 'activerecord', '>= 6.1'
end
