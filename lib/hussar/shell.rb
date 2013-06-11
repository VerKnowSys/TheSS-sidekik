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

    def sh(cmd, *args)
      cmd = "#{Hussar.strip_margin(cmd)}".chomp
      cmd << " 2>&1 >> #{mkpath("service.log")}" unless args.include?(:nolog)
      cmd << " &" if args.include?(:background)
      @commands << cmd
    end

    def rake(*tasks)
      sh "rake #{tasks.join(' ')}"
    end

    def mkdir(dir, chmod = nil)
      path = mkpath(dir)
      cmd = "test ! -d #{path} && mkdir -p #{path}"
      cmd << " && chmod #{chmod} #{path}" if chmod
      sh cmd, :nolog
    end

    def file(name, *args)
      body, vars = if args.size == 1
        [args.first, []]
      else
        [args.last, args.first]
      end

      path = mkpath(name)
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

    def info(msg)
      sh "printf '#{msg}\n'"
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
      msg = "File #{file} of service #{service} is empty, exiting."
      sh %Q{test "$#{name}" = "" && echo '#{msg}' && exit 1}
    end

    def current_user
      "$USER"
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

    def env(var, content)
      @env_vars[var] = content
    end

    def _env_vars_commands
      unless @env_vars.empty?
        path = mkpath("service.env")
        tpl = @env_vars.keys.map {|k| "#{k}=%s"}.join("\n")
        args = @env_vars.values.map {|v| "'#{v}'"}.join(" ")

        sh "printf '#{tpl}' #{args} > #{path}", :nolog
      end
    end
  end
end
