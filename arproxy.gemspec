Gem::Specification.new do |spec|
  spec.name              = 'arproxy'
  spec.version           = '0.1.1'
  spec.summary           = 'Proxy between ActiveRecord and DB adapter'
  spec.description       = 'Arproxy is a proxy between ActiveRecord and database adapter'
  spec.files             = Dir.glob("lib/**/*.rb")
  spec.author            = 'Issei Naruta'
  spec.email             = 'naruta@cookpad.com'
  spec.homepage          = 'https://github.com/cookpad/arproxy'
  spec.has_rdoc          = false
  spec.add_dependency 'activerecord', '~> 3.0'
end
