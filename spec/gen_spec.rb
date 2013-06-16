require File.expand_path("../spec_helper", __FILE__)
require File.expand_path("../test_addon", __FILE__)

describe "Gen" do
  let(:addon) { Hussar::Addon["Test"] }

  def gen(opts = {})
    addon.generate!(opts)[:services]["Test"]
  end

  it "should have list of options" do
    addon.default_options[:opt1].must_equal "x"
    addon.default_options[:opt2].must_equal 123
  end

  it "should have correct software name" do
    gen["softwareName"].must_equal "TestSoft"
  end

  it "should have default install command" do
    gen["install"]["commands"].strip.must_equal "sofin get testsoft"
  end

  it "should handle :background option" do
    gen["start"]["commands"].tap do |i|
      i.must_include "test-bg &"
    end
  end

  it "should handle touch" do
    gen["validate"]["commands"].tap do |i|
      i.must_include "touch SERVICE_PREFIX/test-file"
    end
  end

  it "should handle mkdir" do
    gen["validate"]["commands"].tap do |i|
      i.must_include "mkdir -p SERVICE_PREFIX/test-dir"
    end
  end

  it "should handle options" do
    gen["start"]["commands"].tap do |i|
      i.must_include "test-opt1 x"
      i.must_include "test-opt2 123"
    end
    gen(:opt1 => "y")["start"]["commands"].tap do |i|
      i.must_include "test-opt1 y"
      i.must_include "test-opt2 123"
    end
    gen(:opt1 => "z", :opt2 => 0)["start"]["commands"].tap do |i|
      i.must_include "test-opt1 z"
      i.must_include "test-opt2 0"
    end
  end

  it "should generate exactly the same config when invoked twice" do
    a,b = gen,gen

    # Except for the last line with expect random checksum
    asc = a["start"]["commands"].split("\n")[0..-2]
    bsc = b["start"]["commands"].split("\n")[0..-2]
    avc = a["validate"]["commands"].split("\n")[0..-2]
    bvc = b["validate"]["commands"].split("\n")[0..-2]

    asc.must_equal bsc
    avc.must_equal bvc
  end

  it "should handle dependencies with correct prefix" do
    gen["dependencies"].tap do |i|
      i.must_equal ["Dep1"]
    end

    gen(:use_dep2 => true)["dependencies"].tap do |i|
      i.must_equal ["Dep1", "Dep2"]
    end

    addon.generate!(:service_prefix => "TestApp")[:services]["TestApp-Test"]["dependencies"].tap do |i|
      i.must_equal ["TestApp-Dep1"]
    end
  end

  it "should handle port requirements based on options" do
    gen(:opt1 => false, :opt2 => false)["portsPool"].must_equal 0
    gen(:opt1 => true,  :opt2 => false)["portsPool"].must_equal 1
    gen(:opt1 => false, :opt2 => true)["portsPool"].must_equal 5
    gen(:opt1 => true,  :opt2 => true)["portsPool"].must_equal 6
  end
end
