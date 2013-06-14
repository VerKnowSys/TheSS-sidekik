module Hussar
  class Shell < Inner

    def initialize(&block)
      super
      @commands = []
      @expect_output = nil
      @expect_timeout = nil
      @cron = nil
      @var_count = 0
      @env_vars = {}
    end

    def generate!(*args)
      super
      _env_vars_commands
      h = {}
      h[:commands] = ([""] + @commands + [""]).join("\n")
      h[:expectOutput] = @expect_output if @expect_output
      h[:expectOutputTimeout] = @expect_timeout if @expect_timeout
      h[:cronEntry] = @cron if @cron
      h
    end

    def chdir(dir, &block)
      debug "Entering %s", dir
      sh "pushd $BUILD_DIR", :nolog
      block.call
      debug "Leaving %s", dir
      sh "popd", :nolog
    end

    def sh(cmd, *args)
      @commands << sh_make(cmd, *args)
    end

    def sh_make(cmd, *args)
      cmd = "#{Hussar.strip_margin(cmd)}".chomp

      command = ""
      command << cmd
      command << log unless args.include?(:nolog)
      command << " &" if args.include?(:background)
      if args.include?(:validate)
        err =  %Q|\nif [ ! "$?" = "0" ]; then\n|
        err << print(31, "!! Command failed !!") + " #{log}\n"
        err << print(31, cmd.gsub("'", "\\'")) + " #{log}\n"
        err << %Q|echo 'Build Failed'\n|
        err << %Q|exit 1\n|
        err << %Q|fi\n|
        command << err
      end

      command
    end

    def sh_unshift(cmd, *args)
      @commands.unshift(sh_make(cmd, *args))
    end

    def rake(*tasks)
      info "Running rake #{tasks.join(' ')}"
      sh "test -f bin/rake", :validate
      sh "bin/rake #{tasks.join(' ')}", :validate
    end

    def mkdir(*args)
      path, chmod = if args.delete(:absolute)
        [args[0], args[1]]
      else
        [mkpath(args[0]), args[1]]
      end

      cmd = "test ! -d #{path} && mkdir -p #{path}"
      cmd << " && chmod #{chmod} #{path}" if chmod
      sh cmd, :nolog
    end

    def file(*args)
      path = if args.delete(:absolute)
        p = args.shift
        mkdir :absolute, File.dirname(p)
        p
      else
        p = args.shift
        mkdir File.dirname(p)
        mkpath(p)
      end

      body, vars = if args.size == 1
        [args[0], []]
      else
        [args.last, args[0]]
      end

      content = Hussar.strip_margin(body)
      vars_sh = vars.join(" ")
      sh "printf '\n#{content}\n' #{vars_sh} > #{path}", :nolog
    end

    def check_file(name)
      path = mkpath(name)
      sh "test ! -f #{path} && touch SERVICE_PREFIX/.configure", :nolog
    end

    def check_dir(name)
      path = mkpath(name)
      sh "test ! -d #{path} && touch SERVICE_PREFIX/.configure", :nolog
    end

    def touch(file)
      sh "touch #{mkpath(file)}", :nolog
    end

    def backup(file)
      path = mkpath(file)
      sh "test -e #{path} && cp #{path} #{path}-$(date +'%Y-%m-%d--%H%M').backup", :nolog
    end

    def cp_r_from_root(file)
      path = mkpath(file)
      sh "test ! -d #{path} && cp -r SERVICE_ROOT/#{file} SERVICE_PREFIX", :nolog
    end

    def daemonize(cmd)
      sh "(#{cmd} >> SERVICE_PREFIX/service.log 2>&1 < /dev/null & echo $! > SERVICE_PREFIX/service.pid) &", :nolog
    end

    def expect(out, timeout = nil)
      @expect_output = out
      @expect_timeout = timeout
    end

    def info(msg, *args)
      @commands << sh_make(print(32, msg, *args))
    end

    def debug(msg, *args)
      @commands << sh_make(print(34, msg, *args))
    end

    def print(color, msg, *args)
      time = "$(date +'%Y-%m-%d-%Hh%Mm%S')"
      "printf '\e[#{color}m%s - #{msg}\e[0m\n' #{time} #{args.join(" ")}"
    end

    def log
      " 2>&1 >> #{mkpath("service.log")}"
    end

    def read_var(file, service = nil)
      name = "HSR_VAR_#{@var_count}"
      path = mkpath(file, service)
      sh "#{name}=`cat #{path}`", :nolog
      test_var(name, file, service)
      @var_count += 1
      "$#{name}"
    end

    def test_var(name, file, service = nil)
      # msg = "File #{file} of service #{service} is empty, exiting."
      sh %Q{test ! "$#{name}" = ""}, :validate
    end

    def current_user
      "$USER"
    end

    def service_name
      "$(basename SERVICE_PREFIX)"
    end

    def service_port(*args)
      n = args.find {|e| e.is_a?(Fixnum) } || 0
      service = args.find {|e| e.is_a?(String) }
      if service
        read_var(".ports/#{n}", service)
      else
        n == 0 ? "SERVICE_PORT" : "SERVICE_PORT#{n}"
      end
    end

    def service_domain(service = nil)
      service ? read_var(".domain", service) : "SERVICE_DOMAIN"
    end

    def mkpath(f, service = nil)
      if service
        "SERVICE_PREFIX/../#{service_prefix}#{service}/#{f}"
      else
        "SERVICE_PREFIX/#{f}"
      end
    end

    def task(name)
      instance_exec(&Tasks[name])
    end

    def notification(msg, level, *args)
      sh %Q{
        NOTIFICATION_MSG="#{msg}"
        NOTIFICATION_MSG_SHA=$(echo $NOTIFICATION_MSG | shasum | awk '{print $1}')
        printf '#{msg}' #{args.join(" ")} > SERVICE_PREFIX/.notifications/$NOTIFICATION_MSG_SHA.#{level}
      }, :nolog

      # HipChat notification
      # sh %Q{
      #   if [ ! "$HIPCHAT_ROOM" = "" -a ! "$HIPCHAT_TOKEN" = "" ]; then
      #     curl "https://api.hipchat.com/v1/rooms/message" -d room_id=$HIPCHAT_ROOM&auth_token=$HIPCHAT_TOKEN&message=$NOTIFICATION_MSG
      #   fi;
      # }, :nolog
    end

    def notice(msg, *args)
      notification(msg, "notice", *args)
    end

    def error(msg, *args)
      notification(msg, "error", *args)
    end

    def env(var, content)
      @env_vars[var] = content
    end

    def env_load
      info "Loading env"
      sh %Q{
        ls SERVICE_PREFIX/../ #{log}
        for i in `ls SERVICE_PREFIX/../`; do
          printf 'loading %s\n' "SERVICE_PREFIX/../${i}/service.env" #{log}
          test -f "SERVICE_PREFIX/../${i}/service.env" && source "SERVICE_PREFIX/../${i}/service.env"
        done
      }, :nolog
    end

    def _env_vars_commands
      unless @env_vars.empty?
        path = mkpath("service.env")
        tpl = @env_vars.keys.map {|k| "export #{k}=%s"}.join("\n")
        args = @env_vars.values.map {|v| "'#{v}'"}.join(" ")

        sh_unshift "printf '#{tpl}\n' #{args} > #{path}", :nolog
      end
    end
  end
end
