[![Build Status](https://github.com/cookpad/arproxy/actions/workflows/ruby.yml/badge.svg)](https://github.com/cookpad/arproxy/actions)

## Arproxy
Arproxy is a library that can intercept SQL queries executed by ActiveRecord to log them or modify the queries themselves.

## Getting Started
Create your custom proxy and add its configuration in your Rails' `config/initializers/` directory:

```ruby
class QueryTracer < Arproxy::Base
  def execute(sql, name=nil)
    Rails.logger.debug sql
    Rails.logger.debug caller(1).join("\n")
    super(sql, name)
  end
end

Arproxy.configure do |config|
  config.adapter = 'mysql2' # A DB Apdapter name which is used in your database.yml
  config.use QueryTracer
end
Arproxy.enable!
```

Then you can see the backtrace of SQLs in the Rails' log.

```ruby
# In your Rails code
MyTable.where(id: id).limit(1) # => The SQL and the backtrace appear in the log
```

### What the `name' argument is
In the Rails' log you may see queries like this:
```
User Load (22.6ms)  SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Issei Naruta'
```
Then `"User Load"` is the `name`.

## Architecture
Without Arproxy:

```
+-------------------------+        +------------------+
| ActiveRecord::Base#find |--SQL-->| Database Adapter |
+-------------------------+        +------------------+
```

With Arproxy:

```ruby
Arproxy.configure do |config|
  config.adapter = 'mysql2'
  config.use MyProxy1
  config.use MyProxy2
end
```

```
+-------------------------+        +----------+   +----------+   +------------------+
| ActiveRecord::Base#find |--SQL-->| MyProxy1 |-->| MyProxy2 |-->| Database Adapter |
+-------------------------+        +----------+   +----------+   +------------------+
```

## Supported Environments

Arproxy supports the following databases and adapters:

- MySQL
  - `mysql2`, `trilogy`
- PostgreSQL
  - `pg`
- SQLite
  - `sqlite3`
- SQLServer
  - `activerecord-sqlserver-adapter`

We have tested with the following versions of Ruby and ActiveRecord:

- Ruby
  - `2.7`, `3.0`, `3.1`, `3.2`, `3.3`
- ActiveRecord
  - `6.1`, `7.0`, `7.1`, `7.2`

## Examples
### Slow Query Logger
```ruby
class SlowQueryLogger < Arproxy::Base
  def initialize(slow_ms)
    @slow_ms = slow_ms
  end

  def execute(sql, name=nil)
    result = nil
    ms = Benchmark.ms { result = super(sql, name) }
    if ms >= @slow_ms
      Rails.logger.info "Slow(#{ms.to_i}ms): #{sql}"
    end
    result
  end
end

Arproxy.configure do |config|
  config.use SlowQueryLogger, 1000
end
```

### Adding Comments to SQLs
```ruby
class CommentAdder < Arproxy::Base
  def execute(sql, name=nil)
    sql += ' /*this_is_comment*/'
    super(sql, name)
  end
end
```

### Readonly Access
```ruby
class Readonly < Arproxy::Base
  def execute(sql, name=nil)
    if sql =~ /^(SELECT|SET|SHOW|DESCRIBE)\b/
      super sql, name
    else
      Rails.logger.warn "#{name} (BLOCKED) #{sql}"
      nil # return nil to block the query
    end
  end
end
```

## Use plug-in

```ruby
# any_gem/lib/arproxy/plugin/my_plugin
module Arproxy::Plugin
  class MyPlugin < Arproxy::Base
    Arproxy::Plugin.register(:my_plugin, self)

    def execute(sql, name=nil)
      # Any processing
    end
  end
end
```

```ruby
Arproxy.configure do |config|
  config.plugin :my_plugin
end
```

## Development

### Setup

```
$ git clone https://github.com/cookpad/arproxy.git
$ cd arproxy
$ bundle install
$ bundle exec appraisal install
```

### Run test

To run all tests with all supported versions of ActiveRecord:

```
$ docker compose up -d
$ bundle exec appraisal rspec
```

To run tests for a specific version of ActiveRecord:

```
$ bundle exec appraisal ar_7.1 rspec
or
$ BUNDLE_GEMFILE=gemfiles/ar_7.1.gemfile bundle exec rspec
```

## License
Arproxy is released under the MIT license:
* www.opensource.org/licenses/MIT
