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
$ bin/hsr app.json
```


## Addon DSL

### Basics
```ruby
addon "AddonName" do |a|
  a.software_name "MySoft"

  a.start do
    sh "run-something"
  end

  a.validate do
    mkdir "database"
  end
end
```

### Options
```ruby
addon "AddonName" do |a|
  a.option :max_hussars, 300  # define option with default value

  a.start do
    sh "run --max-hussars=#{opt[:max_hussars]}" # use opt[:option_name]
  end
end
```

### Shell block commands

All file paths will be relative to `SERVICE_PREFIX`

- `sh(cmd, log = true)` - Execute command with output redirected to `service.log`
  - Use `sh "cmd", :nolog` to disable output redirection
- `rake(*tasks)` - Run rake task `rake "task1", "task2"`
- `mkdir(dir, chmod = nil)` - Create new directory + optional chmod
- `file(name, body)` - Create a file if not exists
- `touch(file)` - Touch a file
- `backup(file)` - Copy file to `FILE-CURRENT_TIME.backup`
- `expect(out)` - Define excepted output for validation
- `info(msg)` - Just a print
- `daemonize(cmd)` - Put `cmd` in background using double bg (&) trick - it will save process pid file to SERVICE_PREFIX/service.pid


### VAR abstraction

In case of dynamicly generated config files where you need to read .ports file there is a helper for that:

```ruby
  a.validate do
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
HSR_VAR_0=`cat SERVICE_PREFIX/.ports`
HSR_VAR_1=`cat SERVICE_PREFIX/../Redis/.ports`
HSR_VAR_2=`cat SERVICE_PREFIX/../Nginx/.domain`
HSR_VAR_3=`cat SERVICE_PREFIX/.foo`
HSR_VAR_4=`cat SERVICE_PREFIX/../Mysql/.bar`
test ! -f SERVICE_PREFIX/service.conf && printf '
[some]
config.port = %s
config.redis.port = %s
config.nginx.domain = %s
config.foo = %s
config.bar = %s
config.user = %s' $HSR_VAR_0 $HSR_VAR_1 $HSR_VAR_2 $HSR_VAR_3 $HSR_VAR_4 $USER > SERVICE_PREFIX/service.conf
"
  }
```

### Scheduler actions

Multiple `cron` blocks allowed

```ruby
  a.scheduler_actions do
    cron "*/5 * * * * ?" do
      backup "database/database.rdf"
    end

    cron "*/2 * * * * ?" do
      touch "database/database.test"
    end
  end
```


## Testing

```
$ rake test
```
