addon "Test" do |a|
  a.software_name "TestSoft"
  a.option :opt1, "x"
  a.option :opt2, 123
  a.option :use_dep2, false

  a.dependencies do
    dependency "Dep1"
    dependency "Dep2" if opt[:use_dep2]
  end

  a.start do
    sh "test-log"
    sh "test-nolog", :nolog
    sh "test-bg", :background, :nolog
    sh "test-opt1 #{opt[:opt1]}"
    sh "test-opt2 #{opt[:opt2]}"
  end

  a.validate do
    touch "test-file"
    mkdir "test-dir"
  end
end

addon "Dep1" do |a|
  a.software_name "Dep1"
end

addon "Dep2" do |a|
  a.software_name "Dep2"
end
