# Preload Pluck

[![Build Status](https://travis-ci.org/assetricity/preload_pluck.png)](https://travis-ci.org/assetricity/preload_pluck)
[![Coverage Status](https://coveralls.io/repos/assetricity/preload_pluck/badge.png?branch=master)](https://coveralls.io/r/assetricity/preload_pluck?branch=master)
[![Dependency Status](https://gemnasium.com/assetricity/preload_pluck.png)](https://gemnasium.com/assetricity/preload_pluck)

Adds a `preload_pluck` method to ActiveRecord that allows querying using Rails 4 eager loading-style for joined tables (`preload`), and returns a 2-dimensional array without ActiveRecord model creation overhead (`pluck`).

The typical use case is for querying and displaying tabular data, such as on an index page, without any further manipulation needed by the involved ActiveRecord models. Data may originate from immediate attributes on the current model or from attributes from other models associated via `belongs_to`. 

Note: Preload Pluck may not always increase query performance - always benchmark with your own queries and production data.

## Install

Add to the preload_pluck gem to your Gemfile:

```ruby
gem 'preload_pluck'
```

## Usage

Call `preload_pluck` on an ActiveRecord model:  

```ruby
Comment.order(:created_at).preload_pluck(:text, 'user.name')
```

This will return a 2-dimensional array where columns correspond to the passed arguments:

```ruby
[
  ['That was an interesting post', 'Alice']
  ['I thought so too', 'Bob']
]
```

Attributes on the current model can be supplied by name:

```ruby
Comment.preload_pluck(:title, :text)
```

Nested attributes should be separated by a period:

```ruby
Comment.preload_pluck('post.title', 'post.text')
```

Both immediate and nested attributes can be mixed:

```ruby
Comment.preload_pluck(:title, :text, 'post.title', 'post.text')
```

Any SQL conditions (e.g. where clauses, scopes, orders, limits) should be set before `preload_pluck` is called:

```ruby
Comment.order(:created_at)
       .joins(:user)
       .where(user: {name: 'Alice'))
       .preload_pluck(:title, :text, 'post.title', 'post.text')
```

See `spec/preload_pluck_spec.rb` for more examples.

## Running Tests

SQLite must be installed before running tests.

To run tests:

```
bundle
rspec
```

By default, performance tests are disabled as it takes several minutes to insert data. To run performance tests:

```
rspec --tag performance
```

## License

Copyright [Assetricity, LLC](http://assetricity.com)

Preload Pluck is released under the MIT License. See [LICENSE](https://github.com/assetricity/preload_pluck/blob/master/LICENSE) for details.
