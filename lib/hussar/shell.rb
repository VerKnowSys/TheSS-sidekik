require "digest/sha1"

module Hussar
  class Shell < Inner

    def initialize(app, phase, &block)
      super(app, &block)
      @phase = phase
      @sh_commands = []
      @expect_output = nil
      @expect_timeout = nil
      @vars_count = 0
      @vars_commands = []
      @env_vars = {}
    end

    def generate!(*args)
      super

      unless @expect_output
        msg = "#{@phase} - done - #{Digest::SHA1.hexdigest(Time.now.to_s + rand.to_s)}"
        @expect_output = msg
        @sh_commands << "echo '#{msg}'"
      end

      commands = []
      commands += @vars_commands
      commands += env_setup_commands
      commands += @sh_commands
      commands = [""] + commands + [""] if commands.size > 1

      {
        :commands       => commands.join("\n"),
        :expectOutput   => @expect_output,
        :expectTimeout  => @expect_timeout
      }.reject {|k,v| !v }
    end


    # Service properties

    def current_user
      "$USER"
    end

    def service_name
      "$(basename SERVICE_PREFIX)"
    end

    def service_port(*args)
      n = args.find {|e| e.is_a?(Fixnum) } || 0
      service = args.find {|e| e.is_a?(String) }
      read_var(".ports/#{n}", service)
    end

    def service_domain(service = nil)
      service ? read_var(".domain", service) : "SERVICE_DOMAIN"
    end

    def app_codename
      app.name.downcase
    end

    def app_name
      app.template
    end

    def app_port(*args)
      service_port(app_name, *args)
    end

    def app_domain
      service_domain(app_name)
    end

    def app_public
      make_path("current/public", app_name)
    end

    def make_path(f, service = nil)
      if service
        "SERVICE_PREFIX/../#{service_prefix}#{service}/#{f}"
      else
        "SERVICE_PREFIX/#{f}"
      end
    end

    def service_path(path)
      File.join("SERVICE_PREFIX", path)
    end

    def read_var(file, service = nil)
      name = "HSR_VAR_#{@vars_count}"
      path = make_path(file, service)
      @vars_commands << make_sh(%Q|#{name}=`cat #{path}`|, :novalidate)
      @vars_commands << make_sh(%Q|test ! "$#{name}" = ""|)
      @vars_count += 1
      "$#{name}"
    end


    # File & directory operations

    def chdir(dir, &block)
      debug "Entering %s", dir
      sh "pushd #{dir}"
      block.call
      debug "Leaving %s", dir
      sh "popd"
    end

    def service_mkdir(path, mod = nil)
      mkdir(service_path(path), mod)
    end

    def mkdir(path, mod = nil)
      sh "mkdir -p #{path}"
      chmod(mod, path) if mod
    end

    def service_chmod(mod, path)
      chmod(mod, service_path(path))
    end

    def chmod(mod, path)
      sh "chmod #{mod} #{path}"
    end

    def service_file(path, *args, &block)
      file(service_path(path), *args, &block)
    end

    def file(path, *args, &block)
      content = Hussar.strip_margin(block.call)
      @sh_commands << make_printf(content, args, :output => path)
    end


    # File & directory test operations

    def check_service_file(path)
      check_file(service_path(path))
    end

    def check_file(path)
      sh "test -f #{path}"
    end

    def check_service_dir(path)
      check_dir(service_path(path))
    end

    def check_dir(path)
      sh "test -d #{path}"
    end

    def service_touch(path)
      touch(service_path(path))
    end

    def touch(path)
      sh "touch #{path}"
    end

    def backup_service_file(path)
      backup_file(service_path(path))
    end

    def backup_file(path)
      sh "test -e #{path} && cp #{path} #{path}-$(date +'%Y-%m-%d--%H%M').backup"
    end

    def copy_from_software_root(path)
      sh "test ! -d #{path} && cp -r SERVICE_ROOT/#{path} SERVICE_PREFIX"
    end


    # Shell commands execution

    def sh(cmd, *args)
      @sh_commands << make_sh(cmd, *args)
    end

    def daemonize(cmd)
      sh "(#{cmd} >> SERVICE_PREFIX/service.log 2>&1 < /dev/null & echo $! > SERVICE_PREFIX/service.pid) &", :novalidate
    end

    def make_sh(cmd, *args)
      cmd = Hussar.strip_margin(cmd).chomp

      if args.include?(:background)
        # Since this will go to background we can't test the exit code
        cmd + " &"
      else
        unless args.include?(:novalidate)
          if opts.debug?
            err = []
            err << ""
            err << %Q|LAST_EXIT_CODE="$?"|
            err << %Q|if [ ! "$LAST_EXIT_CODE" = "0" ]; then|
            err << make_printf("!! Command failed !! exit code: %s", ["$LAST_EXIT_CODE"], :time => true, :color => 31)
            err << make_printf(cmd.gsub("'", "\\'"))
            err << %Q|exit 1|
            err << %Q|fi|
            err << ""
            cmd << err.join("\n")
          else
            cmd << " || exit 1"
          end
        end

        cmd
      end
    end

    def set(name, value)
      sh "#{name}=#{value}", :novalidate
    end


    # Logging

    def info(msg, *args)
      @sh_commands << make_printf(msg, args, :color => 32, :time => true)
    end

    def debug(msg, *args)
      @sh_commands << make_printf(msg, args, :color => 34, :time => true)
    end

    def notice(msg, *args)
      notification(msg, "notice", *args)
    end

    def error(msg, *args)
      notification(msg, "error", *args)
    end

    def notification(msg, level, *args)
      set "NOTIFICATION_MSG", %Q|"#{msg}"|
      set "NOTIFICATION_MSG_SHA", "$(echo $NOTIFICATION_MSG | shasum | awk '{print $1}')"
      @sh_commands << make_printf(msg, args, :output => "SERVICE_PREFIX/.notifications/$NOTIFICATION_MSG_SHA.#{level}")

      # HipChat notificationNOTIFICATION_MSG
      # sh %Q{
      #   if [ ! "$HIPCHAT_ROOM" = "" -a ! "$HIPCHAT_TOKEN" = "" ]; then
      #     curl "https://api.hipchat.com/v1/rooms/message" -d room_id=$HIPCHAT_ROOM&auth_token=$HIPCHAT_TOKEN&message=$
      #   fi;
      # }, :nolog
    end


    # Expectations

    def expect(out, timeout = nil)
      @expect_output = out
      @expect_timeout = timeout
    end

    def expect_timeout(timeout)
      @expect_timeout = timeout
    end


    # ENV operations

    def set_env(var, content)
      @env_vars[var] = content
    end

    def env_load
      info "Loading env"
      sh %Q{
        for i in `ls SERVICE_PREFIX/../`; do
          printf 'loading %s\n' "SERVICE_PREFIX/../${i}/service.env"
          test -f "SERVICE_PREFIX/../${i}/service.env" && source "SERVICE_PREFIX/../${i}/service.env"
        done
      }, :novalidate
    end

    def env_setup_commands
      if @env_vars.empty?
        []
      else
        path = service_path("service.env")
        tpl = @env_vars.keys.map {|k| "export #{k}=%s"}.join("\n")
        args = @env_vars.values.map {|v| %Q|"#{v}"|}

        [make_printf(tpl, args, :output => path)]
      end
    end


    # Utility methods

    def make_printf(msg, args = [], options = {})
      if args.is_a?(Hash)
        options = args
        args = []
      end

      if options[:time]
        msg = "%s - #{msg}"
        args.unshift "$(date +'%Y-%m-%d-%Hh%Mm%S')"
      end

      if c = options[:color]
        msg = "\e[#{c}m#{msg}\e[0m"
      end

      cmd = %Q|printf '#{msg}\n' #{args.join(' ')}|

      if o = options[:output]
        cmd << " > #{o}"
      end

      cmd
    end

    # Wrapper for instance exec
    def run(block, *args)
      instance_exec(*args, &block)
    end

    def rake(*tasks)
      info "Running rake #{tasks.join(' ')}"
      sh "test -f bin/rake"
      sh "bin/rake #{tasks.join(' ')}"
    end

    def check_pids(pidfiles)
      pidfiles.each do |pidfile|
        sh "kill -0 `cat #{pidfile}`"
      end
    end

    def task(name)
      instance_exec(&Tasks[name])
    end
  end
end
