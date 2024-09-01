[![Build Status](https://github.com/cookpad/arproxy/actions/workflows/ruby.yml/badge.svg)](https://github.com/cookpad/arproxy/actions)

## Welcome to Arproxy
Arproxy is a proxy between ActiveRecord and Database adapters.
You can make a custom proxy what analyze and/or modify SQLs before DB adapter executes them.

## Getting Started
Write your proxy and its configurations in Rails' config/initializers:

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

## Architecture
Without Arproxy:

```
+-------------------------+                       +------------------+
| ActiveRecord::Base#find |--execute(sql, name)-->| Database Adapter |
+-------------------------+                       +------------------+
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
+-------------------------+                       +----------+   +----------+   +------------------+
| ActiveRecord::Base#find |--execute(sql, name)-->| MyProxy1 |-->| MyProxy2 |-->| Database Adapter |
+-------------------------+                       +----------+   +----------+   +------------------+
```

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

## Appendix
### What the `name' argument is
In the Rails' log you may see queries like this:
```
User Load (22.6ms)  SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Issei Naruta'
```
Then `"User Load"` is the `name`.

##  License
Arproxy is released under the MIT license:
* www.opensource.org/licenses/MIT

Copyright (c) 2023 Issei Naruta
