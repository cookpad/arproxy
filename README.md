[![Integration tests](https://github.com/cookpad/arproxy/actions/workflows/integration_tests.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/integration_tests.yml)
[![Unit tests](https://github.com/cookpad/arproxy/actions/workflows/unit_tests.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/unit_tests.yml)
[![Rubocop](https://github.com/cookpad/arproxy/actions/workflows/rubocop.yml/badge.svg)](https://github.com/cookpad/arproxy/actions/workflows/rubocop.yml)

# Arproxy
Arproxy is a library that can intercept SQL queries executed by ActiveRecord to log them or modify the queries themselves.

# Getting Started
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

## What the `name' argument is
In the Rails' log you may see queries like this:
```
User Load (22.6ms)  SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Issei Naruta'
```
Then `"User Load"` is the `name`.

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
class CommentAdder < Arproxy::Base
  def execute(sql, name=nil)
    sql += ' /*this_is_comment*/'
    super(sql, name)
  end
end
```

# Use plug-in

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

# Upgrading guide from v0.x to v1

There are several incompatible changes from Arproxy v0.x to v1.
In most cases, existing configurations can be used as-is in v1, but there are some exceptions.
The specification of custom proxies (classes inheriting from Arproxy::Base) has changed as follows:

## 1. Removal of keyword arguments (kwargs)

In v0.2.9, `**kwargs` was added to the arguments of the `#execute` method ([#21](https://github.com/cookpad/arproxy/pull/21)), but this argument has been removed in v1.

These `kwargs` were removed in v1 because their specifications differed depending on the Connection Adapter of each database.

```ruby
# ~> v0.2.9
class MyProxy < Arproxy::Base
  def execute(sql, name=nil, **kwargs)
    super
  end
end

# >= v1.0.0
class MyProxy < Arproxy::Base
  def execute(sql, name=nil)
    super
  end
end
```

## 2. `Arproxy::Base#execute` (`super`) no longer executes queries

In v0.x, the `Arproxy::Base#execute` method was a method to execute a query on the Database Adapter.
That is, when `super` is called in the `#execute` method of a custom proxy, a query is executed on the Database Adapter at the end of the proxy chain.

In v1, the `Arproxy::Base#execute` method does not execute a query. The query is executed outside the `#execute` method after the proxy chain of `#execute` is complete.

This change was necessary to support various Database Adapters while maintaining backward compatibility with custom proxies as much as possible.

However, this change has the following incompatibilities:

- The return value of `super` cannot be used.
- The query execution time cannot be measured.

### 2.1. The return value of `super` cannot be used

In v0.x, the return value of `super` was the result of actually executing a query on the Database Adapter.
For example, if you are using the `mysql2` Adapter, the return value of `super` was a `Mysql2::Result` object.

In v1, the return value of `super` is a value used internally by Arproxy's proxy chain instead of the result of actually executing a query on the Database Adapter.
You still need to return the return value of `super` in the `#execute` method of your custom proxy.
However, the `Arproxy::Base` in v1 does not expect to use this return value in the custom proxy.

If your custom proxy expects the return value of `super` to be an object representing the query result, you need to be careful because it is not available in v1.

```ruby
class MyProxy < Arproxy::Base
  def execute(sql, name=nil)
    result = super(sql, name)
    # ...
    # In v0.x, the return value of the Database Adapter such as Mysql2::Result was stored,
    # but in v1, the value used internally by Arproxy's proxy chain is stored.
    result
  end
end
```

### 2.2. The query execution time cannot be measured

For example, even if you write code to measure the execution time of `super`, it no longer means the query execution time.

```ruby
class MyProxy < Arproxy::Base
  def execute(sql, name=nil)
    t = Time.now
    result = super(sql, name)
    # This code no longer means the query execution time
    Rails.logger.info "Slow(#{Time.now - t}ms): #{sql}"
    result
  end
end
```

# Discussion

The specification changes in v1 have allowed more Database Adapters to be supported and made Arproxy more resistant to changes in ActiveRecord's internal structure.
However, as described in the previous section, there are cases where the custom proxies written in v0.x will no longer work.

We do not know the use cases of Arproxy users other than ourselves very well, so we are soliciting opinions on the changes in this time.
If there are many requests, we will prepare a new base class for custom proxies with a different interface from `Arproxy::Base`, so that custom proxy writing similar to that in v0.x can be done.

For this issue, we are collecting opinions on the following discussion:

[Calling for opinions: incompatibility between v0.x and v1 · cookpad/arproxy · Discussion #33](https://github.com/cookpad/arproxy/discussions/33)

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
