module Hussar
  class Shell
    def initialize(&block)
      @commands = []
      @expect_output = nil
      @cron = nil
      @block = block
    end

    def generate(options = {})
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

    def sh(cmd, log = true)
      cmd = "#{Hussar.strip_margin(cmd)}"
      cmd << " 2>&1 >> #{mkpath("service.log")}" if log
      @commands << cmd
    end

    def rake(*tasks)
      sh "rake #{tasks.join(' ')}"
    end

    def mkdir(dir, chmod = nil)
      path = mkpath(dir)
      cmd = "test ! -d #{path} && mkdir -p #{path}"
      cmd << " && chmod #{chmod} #{path}" if chmod
      sh cmd, false
    end

    def file(name, body)
      path = mkpath(name)
      content = Hussar.strip_margin(body)
      sh "test ! -f #{path} && printf '\n#{content}' > #{path}", false
    end

    def touch(file)
      sh "touch #{mkpath(file)}", false
    end

    def backup(file)
      path = mkpath(file)
      sh "test -e #{path} && cp #{path} #{path}-$(date +'%Y-%m-%d--%H%M').backup", false
    end

    def cp_r_from_root(file)
      path = mkpath(file)
      sh "test ! -d #{path} && cp -r SERVICE_ROOT/#{file} SERVICE_PREFIX", false
    end

    def expect(out)
      @expect_output = out
    end

    def info(msg)
      sh "printf '#{msg}'\n"
    end

    def mkpath(f)
      "SERVICE_PREFIX/#{f}"
    end
  end
end
