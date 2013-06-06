require File.expand_path("../spec_helper", __FILE__)
require File.expand_path("../test_addon", __FILE__)

describe "Gen" do
  let(:addon) { Hussar::Addon["Test"] }

  it "should have list of options" do
    addon.default_options[:opt1].must_equal "x"
    addon.default_options[:opt2].must_equal 123
  end

  it "should have correct software name" do
    addon.generate["softwareName"].must_equal "TestSoft"
  end

  it "should have default install command" do
    addon.generate["install"]["commands"].strip.must_equal "sofin get testsoft"
  end

  it "should handle :nolog option" do
    cmds = addon.generate["start"]["commands"]
    cmds.must_include "test-log 2>&1 >> SERVICE_PREFIX/service.log"
    cmds.must_include "test-nolog"
    cmds.wont_include "test-nolog 2>&1 >> SERVICE_PREFIX/service.log"
  end

  it "should handle touch" do
    cmds = addon.generate["validate"]["commands"]
    cmds.must_include "touch SERVICE_PREFIX/test-file"
  end

  it "should handle mkdir" do
    cmds = addon.generate["validate"]["commands"]
    cmds.must_include "test ! -d SERVICE_PREFIX/test-dir && mkdir -p SERVICE_PREFIX/test-dir"
  end
end
