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
    addon.generate["start"]["commands"].tap do |i|
      i.must_include "test-log 2>&1 >> SERVICE_PREFIX/service.log"
      i.must_include "test-nolog"
      i.wont_include "test-nolog 2>&1 >> SERVICE_PREFIX/service.log"
    end
  end

  it "should handle :background option" do
    addon.generate["start"]["commands"].tap do |i|
      i.must_include "test-bg &"
    end
  end

  it "should handle touch" do
    addon.generate["validate"]["commands"].tap do |i|
      i.must_include "touch SERVICE_PREFIX/test-file"
    end
  end

  it "should handle mkdir" do
    addon.generate["validate"]["commands"].tap do |i|
      i.must_include "test ! -d SERVICE_PREFIX/test-dir && mkdir -p SERVICE_PREFIX/test-dir"
    end
  end

  it "should handle options" do
    addon.generate["start"]["commands"].tap do |i|
      i.must_include "test-opt1 x"
      i.must_include "test-opt2 123"
    end
    addon.generate(:opt1 => "y")["start"]["commands"].tap do |i|
      i.must_include "test-opt1 y"
      i.must_include "test-opt2 123"
    end
    addon.generate(:opt1 => "z", :opt2 => 0)["start"]["commands"].tap do |i|
      i.must_include "test-opt1 z"
      i.must_include "test-opt2 0"
    end
  end

  it "should generate exactly the same config when invoked twice" do
    addon.generate.must_equal addon.generate
  end
end
