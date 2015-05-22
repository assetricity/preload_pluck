# Preload Pluck

[![Build Status](https://travis-ci.org/assetricity/preload_pluck.png)](https://travis-ci.org/assetricity/preload_pluck)
[![Dependency Status](https://gemnasium.com/assetricity/preload_pluck.png)](https://gemnasium.com/assetricity/preload_pluck)

Adds a `preload_pluck` method to ActiveRecord that allows querying using Rails 4 eager loading-style for joined tables (`preload`), and returns a 2-dimensional array without ActiveRecord model creation overhead (`pluck`).

Note: Preload Pluck may not always increase query performance - always benchmark with your own queries and production data.

## Install

Add to the preload_pluck gem to your Gemfile:

```ruby
gem 'preload_pluck'
```

## Usage

Call `preload_pluck` after any SQL conditions (e.g. where clauses, scopes, orders, limits) have been applied and pass immediate attributes or traverse nested `belongs_to` associations.  

```ruby
Comment.order(:created_at).preload_pluck(:text, 'user.name')
```

See `spec/preload_pluck_spec.rb` for more examples.

## Running Tests

SQLite must be installed before running tests.

To run tests:

```
bundle install
rspec spec
```

By default, performance tests are disabled as it takes several minutes to insert data. To run performance tests:

```
rspec spec --tag performance
```

## License

Copyright [Assetricity, LLC](http://assetricity.com)

Preload Pluck is released under the MIT License. See [LICENSE](https://github.com/assetricity/preload_pluck/blob/master/LICENSE) for details.
