module Hussar
  class Shell
    def initialize(&block)
      @block = block
      reset!
    end

    def reset!
      @commands = []
      @expect_output = nil
      @cron = nil
      @var_count = 0
    end

    def generate(options = {})
      reset!
      @options = options
      instance_exec(&@block)
      h = {}
      h[:commands] = ([""] + @commands + [""]).join("\n")
      h[:expectOutput] = @expect_output if @expect_output
      h[:cronEntry] = @cron if @cron
      h
    end

    def opt
      @options
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
      sh "test ! -f #{path} && printf '\n#{content}\n' #{vars_sh} > #{path}", :nolog
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

    def expect(out)
      @expect_output = out
    end

    def info(msg)
      sh "printf '#{msg}\n'"
    end

    def read_var(file, service = nil)
      name = "HSR_VAR_#{@var_count}"
      path = mkpath(file, service)
      sh "#{name}=`cat #{path}`", :nolog
      @var_count += 1
      "$#{name}"
    end

    def current_user
      "$USER"
    end

    def service_port(service = nil)
      service ? read_var(".ports", service) : "SERVICE_PORT"
    end

    def service_domain(service = nil)
      service ? read_var(".domain", service) : "SERVICE_DOMAIN"
    end

    def mkpath(f, service = nil)
      if service
        "SERVICE_PREFIX/../#{service}/#{f}"
      else
        "SERVICE_PREFIX/#{f}"
      end
    end
  end
end
