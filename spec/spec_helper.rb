$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'preload_pluck'
require 'database_cleaner'
require 'factory_girl'

if ENV['COVERAGE'] == 'on'
  require 'coveralls'
  Coveralls.wear!
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                        database: File.dirname(__FILE__) + '/../tmp/preload_pluck.sqlite3')

load File.dirname(__FILE__) + '/support/data/schema.rb'
load File.dirname(__FILE__) + '/support/data/models.rb'
Dir[File.dirname(__FILE__) + '/support/matchers/*.rb'].each {|f| load f}

FactoryGirl.definition_file_paths = %w(./spec/factories)
FactoryGirl.find_definitions

RSpec.configure do |config|
  config.filter_run_excluding :performance

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
