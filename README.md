# Hussar

### Installation
  ```
  $ bundle install
  ```

### Usage:
  ```
  bin/hsr COMMAND [ARG1, ARG2, ...] [OPTIONS]
  ```

### Tasks:

  ```
  gen FILE        # Generate igniters for app
  help [COMMAND]  # Display help
  list            # List available addons
  ```

## App config syntax

```json
// examples/TestApp.json
{
  "name": "TestApp",
  "addons": [
    {
      "type": "Mysql",
      "max_connections": 666 // addon option
    },
    {
      "type": "Redis"
    }
  ]
}
```

Then run

```
$ bin/hsr examples/TestApp.json
```


## Addon DSL

### Basics
```ruby
addon "AddonName" do
  generate do
    service do
      software_name "MySoft"

      start do
        sh "run-something"
      end

      validate do
        mkdir "database"
      end
    end
  end
end
```

### Options
```ruby
addon "AddonName" do
  option :max_hussars, 300  # define option with default value

  generate do
    service do
      start do
        sh "run --max-hussars=#{opts.max_hussars}" # use max_hussars options
      end
    end
  end
end
```

### Conditional services
```ruby
addon "Mongodb" do
  option :replica, false

  generate do
    service do
      # master node configuration
    end

    if opts.replica?
      service do
        # replica node configuration
      end
    end
  end
end
```

### Shell block commands

All file paths will be relative to `SERVICE_PREFIX`

- `sh(cmd, *args)` - Execute command with output redirected to `service.log`
  - Available `args`
     - `:nolog` - disable output redirection
     - `:background` - add `&` at the end of command
- `rake(*tasks)` - Run rake task `rake "task1", "task2"`
- `mkdir(dir, chmod = nil)` - Create new directory + optional chmod
- `file(name, body)` - Create a file if not exists
- `touch(file)` - Touch a file
- `backup(file)` - Copy file to `FILE-CURRENT_TIME.backup`
- `expect(out)` - Define excepted output for validation
- `info(msg)` - Just a print
- `daemonize(cmd)` - Put `cmd` in background using double bg (&) trick - it will save process pid file to `SERVICE_PREFIX/service.pid`


### VAR abstraction

In case of dynamicly generated config files where you need to read .ports file there is a helper for that:

```ruby
  validate do
    vars = []
    vars << service_port              # own port
    vars << service_port("Redis")     # other service port
    vars << service_domain("Nginx")   # other service domain
    vars << read_var(".foo")          # read SERVICE_PREFIX/.foo file
    vars << read_var(".bar", "Mysql") # read SERVICE_PREFIX../Mysql/.bar file
    vars << "USER"                    # any other ENV variable

    file "service.conf", vars, <<-EOS
      [some]
      config.port = %s
      config.redis.port = %s
      config.nginx.domain = %s
      config.foo = %s
      config.bar = %s
      config.user = %s
    EOS
  end
```

This will create the following igniter:

```json
  "validate": {
    "commands": "
HSR_VAR_0=`cat SERVICE_PREFIX/../Redis/.ports/0`
test \\"$HSR_VAR_0\\" = \\"\\" && echo 'File .ports/0 of service Redis is empty, exiting.' && exit 1 2>&1 >> SERVICE_PREFIX/service.log
HSR_VAR_1=`cat SERVICE_PREFIX/../Nginx/.domain`
test \\"$HSR_VAR_1\\" = \\"\\" && echo 'File .domain of service Redis is empty, exiting.' && exit 1 2>&1 >> SERVICE_PREFIX/service.log
HSR_VAR_2=`cat SERVICE_PREFIX/.foo`
test \\"$HSR_VAR_2\\" = \\"\\" && echo 'File .foo of service is empty, exiting.' && exit 1 2>&1 >> SERVICE_PREFIX/service.log
HSR_VAR_3=`cat SERVICE_PREFIX/../Mysql/.bar`
test \\"$HSR_VAR_3\\" = \\"\\" && echo 'File .bar of service Mysql is empty, exiting.' && exit 1 2>&1 >> SERVICE_PREFIX/service.log

test ! -f SERVICE_PREFIX/service.conf && printf '
[some]
config.port = %s
config.redis.port = %s
config.nginx.domain = %s
config.foo = %s
config.bar = %s
config.user = %s' SERVICE_PORT $HSR_VAR_0 $HSR_VAR_1 $HSR_VAR_2 $HSR_VAR_3 $USER > SERVICE_PREFIX/service.conf
"
  }
```

Possible calls:

- `service_port` - This service default port
- `service_port(5)` - This service port no 5
- `service_port("Redis")` - Default port for service "Redis"
- `service_port("Redis", 7)` - Port no 7 for service "Redis"
- `service_domain` - This service domain
- `service_domain("Mysql")` - "Mysql" service domain
- `read_var(".foo")` - read `.foo` file for this service
- `read_var(".foo", "Redis")` - read `.foo` file for service "Redis"


### Dependencies

```ruby
  option :use_dep2, false

  generate do
    service do
      dependencies do
        dependency "Dep1"
        dependency "Dep2" if opts.use_dep2?
      end
    end
  end
```


### Scheduler actions

Multiple `cron` blocks allowed

```ruby
  scheduler_actions do
    cron "*/5 * * * * ?" do
      backup "database/database.rdf"
    end

    cron "*/2 * * * * ?" do
      touch "database/database.test"
    end
  end
```


### Ports

```ruby
  ports_pool do
    no_ports                  # set required ports to 0
    ports 5                   # require 5 ports
    ports 2 if opt.allow_udp? # add one more port if options :allow_udp is specified
    ports 1 if opt.allow_tcp?
  end
```


## Testing

```
$ rake test
```
