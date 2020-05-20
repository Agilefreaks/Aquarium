require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils/camel_case'

describe  CamelCase, "#to_camel_case" do
  it "should return a camel-case string unchanged" do
    CamelCase.to_camel_case("CamelCaseString").should == "CamelCaseString"
  end

  it "should return a camel-case string from an input string with substrings separated by underscores" do
    CamelCase.to_camel_case("camel_case_string").should == "CamelCaseString"
  end

  it "should return a camel-case string with the first letters of each substring in uppercase and the rest of the letters in each substring unchanged" do
    CamelCase.to_camel_case("cAmEl_cASE_stRinG").should == "CAmElCASEStRinG"
  end

  it "should remove leading and trailing underscores" do
    CamelCase.to_camel_case("camel_case_string_").should    == "CamelCaseString"
    CamelCase.to_camel_case("_camel_case_string").should    == "CamelCaseString"
    CamelCase.to_camel_case("camel_case_string__").should   == "CamelCaseString"
    CamelCase.to_camel_case("__camel_case_string").should   == "CamelCaseString"
    CamelCase.to_camel_case("_camel_case_string_").should   == "CamelCaseString"
    CamelCase.to_camel_case("__camel_case_string__").should == "CamelCaseString"
  end
end

describe  CamelCase, "#to_snake_case" do
  it "should return a snake-case string unchanged" do
    CamelCase.to_snake_case("camel_case_string").should == "camel_case_string"
  end

  it "should return a snake-case string to an input string with substrings separated by underscores" do
    CamelCase.to_snake_case("CamelCaseString").should == "camel_case_string"
  end

  it "should return a snake-case string with all characters converted to lower case" do
    CamelCase.to_snake_case("CamelCaseString").should == "camel_case_string"
  end

  it "should partition the words by [A-Z]+[a-z0-9]*" do
    CamelCase.to_snake_case("CAmElCASEStRinG").should == "cam_el_casest_rin_g"
  end

  it "should preserve embedded underscores" do
    CamelCase.to_snake_case("C_Am_ElCA_SEStR_inG").should == "c_am_el_ca_sest_r_in_g"
  end

  it "should remove leading, trailing, and repeated underscores" do
    puts CamelCase.to_snake_case("_Camel__CaseString_")
    CamelCase.to_snake_case("_Camel__CaseString_").should    == "camel_case_string"
  end
end
