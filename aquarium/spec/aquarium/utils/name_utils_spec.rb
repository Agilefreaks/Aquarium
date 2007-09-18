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

  it "should convert question marks into _tilde_" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo~bar~baz").should eql(:foo_tilde_bar_tilde_baz)
  end

  it "should convert all of the above in the same symbol" do
    Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name(:"foo=bar?baz!boz~bat").should eql(:foo_equalsign_bar_questionmark_baz_exclamationmark_boz_tilde_bat)
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
