require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/name_utils'

describe Aquarium::Utils::NameUtils, ".make_valid_attr_name_from_method_name" do
  it "should convert an equal sign into _equalsign_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo=bar=baz").should eql(:foo_equalsign_bar_equalsign_baz)
  end

  it "should convert a question mark into _questionmark_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo?bar?baz").should eql(:foo_questionmark_bar_questionmark_baz)
  end

  it "should convert an exclamation mark into _exclamationmark_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo!bar!baz").should eql(:foo_exclamationmark_bar_exclamationmark_baz)
  end

  it "should convert a tilde into _tilde_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo~bar~baz").should eql(:foo_tilde_bar_tilde_baz)
  end

  it "should convert a minus sign into _minus_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo-bar-baz").should eql(:foo_minus_bar_minus_baz)
  end

  it "should convert a plus sign into _plus_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo+bar+baz").should eql(:foo_plus_bar_plus_baz)
  end

  it "should convert a slash into _slash_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo/bar/baz").should eql(:foo_slash_bar_slash_baz)
  end

  it "should convert a star into _star_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo*bar*baz").should eql(:foo_star_bar_star_baz)
  end

  it "should convert a less than sign into _lessthan_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo<bar<baz").should eql(:foo_lessthan_bar_lessthan_baz)
  end

  it "should convert a greater than sign into _greaterthan_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo>bar>baz").should eql(:foo_greaterthan_bar_greaterthan_baz)
  end

  it "should convert a left shift into _leftshift_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo<<bar<<baz").should eql(:foo_leftshift_bar_leftshift_baz)
  end

  it "should convert a right shift into _rightshift_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo>>bar>>baz").should eql(:foo_rightshift_bar_rightshift_baz)
  end

  it "should convert an '=~' into _matches_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo=~bar=~baz").should eql(:foo_matches_bar_matches_baz)
  end

  it "should convert an '==' sign into _equivalent_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo==bar==baz").should eql(:foo_equivalent_bar_equivalent_baz)
  end
  
  it "should convert a percent sign into _percent_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo%bar%baz").should eql(:foo_percent_bar_percent_baz)
  end

  it "should convert a caret into _caret_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo^bar^baz").should eql(:foo_caret_bar_caret_baz)
  end

  it "should convert a [] into _brackets_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo[]bar[]baz").should eql(:foo_brackets_bar_brackets_baz)
  end

  it "should convert a & into _ampersand_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo&bar&baz").should eql(:foo_ampersand_bar_ampersand_baz)
  end

  it "should convert a | into _pipe_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo|bar|baz").should eql(:foo_pipe_bar_pipe_baz)
  end

  it "should convert a back tick into _backtick_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo`bar`baz").should eql(:foo_backtick_bar_backtick_baz)
  end

  it "should convert all of the above in the same symbol" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo=bar?baz!boz~bat-bot+bit").should eql(
      :foo_equalsign_bar_questionmark_baz_exclamationmark_boz_tilde_bat_minus_bot_plus_bit)
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name('x/a*b<c>d<<e>>f=~g==h%i^j[]k&l|m`n'.intern).should eql(
      :x_slash_a_star_b_lessthan_c_greaterthan_d_leftshift_e_rightshift_f_matches_g_equivalent_h_percent_i_caret_j_brackets_k_ampersand_l_pipe_m_backtick_n)
  end
end

describe Aquarium::Utils::NameUtils, ".make_valid_object_id_name" do
  it "should return the same id string with a _neg_ prefix if the id is negative" do
    Aquarium::Utils::NameUtils.make_valid_object_id_name("-123").should eql("_neg_123")
  end

  it "should return the same id string if the id is positive" do
    Aquarium::Utils::NameUtils.make_valid_object_id_name("123").should eql("123")
  end
end

describe Aquarium::Utils::NameUtils, ".make_valid_type_name" do
  it "should return the same name with colons ':' converted to underscores '_'" do
    Aquarium::Utils::NameUtils.make_valid_type_name(Aquarium::Utils::NameUtils).should eql("Aquarium__Utils__NameUtils")
  end

  it "should return the same name if there are no colons" do
    Aquarium::Utils::NameUtils.make_valid_type_name(String).should eql("String")
  end
end

describe Aquarium::Utils::NameUtils, ".make_type_or_object_key" do
  it "should return the same string as :make_valid_type_name if the input is a type" do
    Aquarium::Utils::NameUtils.make_type_or_object_key(Aquarium::Utils::NameUtils).should eql(Aquarium::Utils::NameUtils.make_valid_type_name(Aquarium::Utils::NameUtils))
  end

  it "should return the same string as :make_valid_object_name if the input is an object" do
    object = "string"
    Aquarium::Utils::NameUtils.make_type_or_object_key(object).should eql(Aquarium::Utils::NameUtils.make_valid_object_name(object))
  end
end
