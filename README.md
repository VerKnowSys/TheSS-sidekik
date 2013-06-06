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
