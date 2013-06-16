addon "Test" do
  option :opt1, "x"
  option :opt2, 123
  option :use_dep2, false

  generate do
    service do

      software_name "TestSoft"

      dependencies do
        dependency "Dep1"
        dependency "Dep2" if opts[:use_dep2]
      end

      ports_pool do
        no_ports

        port    if opts[:opt1]
        ports 5 if opts[:opt2]
      end

      start do
        sh "test-log"
        sh "test-nolog"
        sh "test-bg", :background
        sh "test-opt1 #{opts[:opt1]}"
        sh "test-opt2 #{opts[:opt2]}"
      end

      validate do
        service_touch "test-file"
        service_mkdir "test-dir"
      end
    end
  end
end

addon "Dep1" do
  generate do
    service do
      software_name "Dep1"
    end
  end
end

addon "Dep2" do |a|
  generate do
    service do
      software_name "Dep2"
    end
  end
end
