[![Integration tests](https://github.com/cookpad/arproxy/actions/workflows/integration_tests.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/integration_tests.yml)
[![Unit tests](https://github.com/cookpad/arproxy/actions/workflows/unit_tests.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/unit_tests.yml)
[![Rubocop](https://github.com/cookpad/arproxy/actions/workflows/rubocop.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/rubocop.yml)

# Arproxy
Arproxy is a library that can intercept SQL queries executed by ActiveRecord to log them or modify the queries themselves.

# Getting Started
Create your custom proxy and add its configuration in your Rails' `config/initializers/` directory:

```ruby
class QueryTracer < Arproxy::Proxy
  def execute(sql, context)
    Rails.logger.debug sql
    Rails.logger.debug caller(1).join("\n")
    super(sql, context)
  end
end

Arproxy.configure do |config|
  config.adapter = 'mysql2' # A DB Adapter name which is used in your database.yml
  config.use QueryTracer
end
Arproxy.enable!
```

Then you can see the backtrace of SQLs in the Rails' log.

```ruby
# In your Rails code
MyTable.where(id: id).limit(1) # => The SQL and the backtrace appear in the log
```

## What the `context` argument is

`context` is an instance of `Arproxy::QueryContext` and contains values that are passed from Arproxy to the Database Adapter.
`context` is a set of values used when calling Database Adapter methods, and you don't need to use the `context` values directly.
However, you must always pass `context` to `super` like `super(sql, context)`.

For example, let's look at the Mysql2Adapter implementation. When executing a query in Mysql2Adapter, the `Mysql2Adapter#internal_exec_query` method is called internally.

```
# https://github.com/rails/rails/blob/v7.1.0/activerecord/lib/active_record/connection_adapters/mysql2/database_statements.rb#L21
def internal_exec_query(sql, name = "SQL", binds = [], prepare: false, async: false) # :nodoc:
  # ...
end
```

In Arproxy, this method is called at the end of the `Arproxy::Proxy#execute` method chain, and at this time `context` contains the arguments to be passed to `#internal_exec_query`:

| member           | example value                      |
|------------------|------------------------------------|
| `context.name`   | `"SQL"`                            |
| `context.binds`  | `[]`                               |
| `context.kwargs` | `{ prepare: false, async: false }` |

You can modify the values of `context` in the proxy, but do so after understanding the implementation of the Database Adapter.

### `context.name`

In the Rails' log you may see queries like this:

```
User Load (22.6ms)  SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Issei Naruta'
```

Then `"User Load"` is the `context.name`.

# Architecture
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

# Supported Environments

Arproxy supports the following databases and adapters:

- MySQL
  - `mysql2`, `trilogy`
- PostgreSQL
  - `pg`
- SQLite
  - `sqlite3`
- SQLServer
  - `activerecord-sqlserver-adapter`

We have tested with the following versions of Ruby, ActiveRecord, and databases:

- Ruby
  - `3.0`, `3.1`, `3.2`, `3.3`
- ActiveRecord
  - `6.1`, `7.0`, `7.1`, `7.2`, `8.0`
- MySQL
  - `9.0`
- PostgreSQL
  - `17`
- SQLite
  - `3.x` (not specified)
- SQLServer
  - `2022`

# Examples

## Adding Comments to SQLs

```ruby
class CommentAdder < Arproxy::Proxy
  def execute(sql, context)
    sql += ' /*this_is_comment*/'
    super(sql, context)
  end
end
```

## Slow Query Logger

```ruby
class SlowQueryLogger < Arproxy::Proxy
  def initialize(slow_ms)
    @slow_ms = slow_ms
  end

  def execute(sql, context)
    result = nil
    ms = Benchmark.ms { result = super(sql, context) }
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

## Readonly Access

If you don't call `super` in the proxy, you can block the query execution.

```ruby
class Readonly < Arproxy::Proxy
  def execute(sql, context)
    if sql =~ /^(SELECT|SET|SHOW|DESCRIBE)\b/
      super(sql, context)
    else
      Rails.logger.warn "#{context.name} (BLOCKED) #{sql}"
      nil
    end
  end
end
```

# Use plug-in

```ruby
# any_gem/lib/arproxy/plugin/my_plugin
module Arproxy::Plugin
  class MyPlugin < Arproxy::Proxy
    Arproxy::Plugin.register(:my_plugin, self)

    def execute(sql, context)
      # Any processing
      # ...
      super(sql, context)
    end
  end
end
```

```ruby
Arproxy.configure do |config|
  config.plugin :my_plugin
end
```

# Upgrading guide from v0.x to v1

See [UPGRADING.md](UPGRADING.md)

# Development

## Setup

```
$ git clone https://github.com/cookpad/arproxy.git
$ cd arproxy
$ bundle install
$ bundle exec appraisal install
```

## Run test

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

# License
Arproxy is released under the MIT license:
* www.opensource.org/licenses/MIT
