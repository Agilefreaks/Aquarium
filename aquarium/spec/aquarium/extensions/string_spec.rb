require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/extensions/string'

describe  String, "#to_camel_case" do
  it "should return a camel-case string unchanged" do
    "CamelCaseString".to_camel_case.should == "CamelCaseString"
  end

  it "should return a camel-case string from an input string with substrings separated by underscores" do
    "camel_case_string".to_camel_case.should == "CamelCaseString"
  end

  it "should return a camel-case string with the first letters of each substring in uppercase and the rest of the letters in each substring unchanged" do
    "cAmEl_cASE_stRinG".to_camel_case.should == "CAmElCASEStRinG"
  end

  it "should remove leading and trailing underscores" do
    "camel_case_string_".to_camel_case.should    == "CamelCaseString"
    "_camel_case_string".to_camel_case.should    == "CamelCaseString"
    "camel_case_string__".to_camel_case.should   == "CamelCaseString"
    "__camel_case_string".to_camel_case.should   == "CamelCaseString"
    "_camel_case_string_".to_camel_case.should   == "CamelCaseString"
    "__camel_case_string__".to_camel_case.should == "CamelCaseString"
  end
end