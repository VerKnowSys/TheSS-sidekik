# Hussar


## Command line interface

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
    --debug           # Generate igniter with more verbose error output
    --output-dir=dir  # Save files to other dir (default: current dir)
    --prefix=prefix   # Add prefix to every igniter
  help [COMMAND]  # Display help
  list            # List available addons
  ```

## Architecture

Every app is defined as json file that specifies name, template, env variables and list of addons. For such configuration hussar generates TheSS igniters for deploying and runnng application with all dependencies.

### Template

App templates contain predefined structure and commands for running applications. Currently there are templates only for `Rack` and `Rails3` applications that uses git for version control but there are no limitations to add any other app type.

### Addon

Usually addon is a dependency service like Redis or Mysql that the main app needs. Besides generating TheSS igniter addon also specifies hooks for generating app-level configuration and performing tasks during deploy.


## App config syntax

```json
// examples/TestApp.json
{
  "name": "TestApp",
  "template": "Rack",
  "git_url": "git@github.com:user/repo.git",
  "git_branch": "master",
  "env": {
    "RACK_ENV": "production",
    "SOME_API_KEY": "imsorandomyoucantguessmenever"
  },
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
$ bin/hsr gen examples/TestApp.json
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

### Hooks
```ruby
generate do
  hooks do
    before :build do
      info "Generating Addon configuration for App"
      file "$BUILD_DIR/database.yml" do
         # ...
      end
    end

    after :build do
      rake "migrate"
    end
  end
end
```

### Shell block commands


#### Service properties

- `current_user` - name of current user (`$USER`)
- `service_name` - name of current service
- `service_port(*args)` - port number for service
- `service_domain(*args)` - domain name for service
- `read_var(*args)` - read content of service file

  Possible calls of above methods:
  - `service_port` - This service default port
  - `service_port(5)` - This service port no 5
  - `service_port("Redis")` - Default port for service "Redis"
  - `service_port("Redis", 7)` - Port no 7 for service "Redis"
  - `service_domain` - This service domain
  - `service_domain("Mysql")` - "Mysql" service domain
  - `read_var(".foo")` - read `.foo` file for this service
  - `read_var(".foo", "Redis")` - read `.foo` file for service "Redis"


- `service_path(path)` - Returns absolute file path for path relative to `SERVICE_PREFIX`


#### File operations

In this section each method with `service` in name takes a relative path to `SERVICE_REFIX` directory.

- `mkdir(path, mod = nil)`, `service_mkdir(path, mod = nil)` - Create new directory

- `file(path, *args, &block)`, `service_file(path, *args, &block)` - Create new file. Content provided as result of block will be used as `printf` template
  Example:
    ```ruby
    service_file "service.conf", service_domain, service_port do
      <<-EOS
      this.app.url=http://%s:%s
      EOS
    end
    ```

- `chmod(mod, path)`, `service_chmod(mod, path)` - Well, chmod!
- `touch(path)`, `service_touch(path)` - I think you already know
- `check_file(path)`, `check_service_file(path)` - Check if file exists and is a regular file
- `check_dir(path)`, `check_service_dir(path)` - Check if directory exists and is a directory
- `backup_file(path)`, `backup_service_file(path)` - Copy file as `FILE-CURRENT_TIME.backup
- `chdir(dir, &block)` - Change current directory
  Example:
    ```ruby
    chdir "some/path" do
      sh "some command"
    end
    ```
- `copy_from_software_root(path)` - Copy something from software directory `~/Apps/SOFTWARE_NAME`


#### Shell commands

- `sh(cmd, *args)` - Log level command for executing shell stuff
  Possible options:
    - `:background` - run this command in background
    - `:novalidate` - skip validation of exit code

  Example:
    ```ruby
    sh "some-blocking-command", :background
    sh "i-will-fail-but-we-dont-care", :novalidate
    ```
- `daemonize(cmd)` - Execute command and make it a daemon saving pid to `service.pid` file
- `set(name, value)` - Set local variable to some expression.
  Example:
    ```ruby
    set "STAMP", "$(date +'%Y-%m-%d-%Hh%Mm%S')-$[${RANDOM}%10000]"
    # This is the same as
    sh "STAMP=$(date +'%Y-%m-%d-%Hh%Mm%S')-$[${RANDOM}%10000]", :novalidate
    ```

#### Logging

Command below use `printf` syntax.

- `info(msg, *args)` - Print info message
- `debug(msg, *args)` - Print debug message
- `notice(msg, *args)` - Create notice notification
- `error(msg, *args)` - Create error notification

Example:
  ```ruby
  info "Some msg %s", "$SOME_VAR"
  ```

#### Other

- `expect(out, timeout = nil)` - Set shell block output expectation
- `set_env(var, content)` - Export ENV variable, it will be stored in `service.env` file
  Example:
    ```ruby
    set_env "ELASTICSEARCH_URL", "http://SERVCE_ADDRESS:#{service_port}"
    ```

- `env_load` - Read all `~/SoftwareData/*/service.env` files

- `rake(*tasks)` - Execute rake task
- `task(name)` - Execute predefined task (see `tasks.rb` for list of tasks)



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

