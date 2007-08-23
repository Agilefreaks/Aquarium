require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/extensions/regexp'

describe Regexp, "#empty?" do
  
  it "should return true for an empty regular expression" do
    //.empty?.should be_true
    Regexp.new("").empty?.should be_true
  end
  
  it "should return true for an empty regular expression with whitespace" do
    /   /.empty?.should be_true
    Regexp.new("   ").empty?.should be_true
  end
  
  it "should return false for a non-empty regular expression" do
    /x/.empty?.should be_false
    Regexp.new("x").empty?.should be_false
  end
end

describe Regexp, "#strip" do
  it "should return equivalent Regexp if there is no leading or trailing whitespace." do
    re = /^.{3}.*[a-z]$/
    re.strip.should == re
  end

  it "should return new Regexp with removed leading and/or trailing whitespace, when present." do
    re_string = "^.{3}.*[a-z]$"
    re = Regexp.new "  #{re_string}  "
    re.strip.source.should == re_string
  end
end

describe Regexp, "#<=>" do
  it "should sort by the output of #to_s" do
    ary = [/^x/, /x/, /x$/]
    ary.sort.should == [/^x/, /x$/, /x/]
  end
end
