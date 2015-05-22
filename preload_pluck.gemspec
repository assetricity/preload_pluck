lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'preload_pluck/version'

Gem::Specification.new do |spec|
  spec.name        = 'preload_pluck'
  spec.version     = PreloadPluck::VERSION
  spec.authors     = ['Assetricity']
  spec.email       = ['info@assetricity.com']
  spec.homepage    = 'https://github.com/avinmathew/preload_pluck'
  spec.summary     = 'Efficiently load data into a 2-dimensional array without ActiveRecord model creation overhead.'
  spec.description = 'Adds a preload_pluck method to ActiveRecord that allows querying using Rails 4 preload-style eager loading, and return a 2-dimensional array without ActiveRecord model creation overhead.'

  spec.files       = Dir.glob('lib/**/*') + %w(LICENSE README.md)

  spec.add_dependency 'activerecord', '>= 3.2.1'

  spec.add_development_dependency 'activerecord-import', '~> 0.7.0'
  spec.add_development_dependency 'database_cleaner', '~> 1.4.0'
  spec.add_development_dependency 'factory_girl', '~> 4.5.0'
  spec.add_development_dependency 'rake', '~> 10.4.0'
  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3.10'
end
