addon "Test" do |a|
  a.software_name "TestSoft"
  a.option :opt1, "x"
  a.option :opt2, 123

  a.start do
    sh "test-log"
    sh "test-nolog", :nolog
    sh "test-opt1 #{opt[:opt1]}"
    sh "test-opt2 #{opt[:opt2]}"
  end

  a.validate do
    touch "test-file"
    mkdir "test-dir"
  end
end
