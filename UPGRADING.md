# Upgrading guide from v0.x to v1

The proxy specification has changed from v0.x to v1 and is not backward compatible.
The base class for proxies has changed from `Arproxy::Base` to `Arproxy::Proxy`.
Also, the arguments to `#execute` have changed from `sql, name=nil, **kwargs` to `sql, context`.

```ruby
# ~> v0.2.9
class MyProxy < Arproxy::Base
  def execute(sql, name=nil, **kwargs)
    super
  end
end

# >= v1.0.0
class MyProxy < Arproxy::Proxy
  def execute(sql, context)
    super
  end
end
```

There are no other backward incompatible changes besides the above changes in proxy base class and arguments.
