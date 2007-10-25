require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/finders/object_finder'

# :stopdoc:
class OBase
  attr_reader :name
  def initialize name; @name = name; end
  def == other
    name == other.name
  end
end

class ODerived < OBase
  def initialize name; super; end
end

module Mod; end

class IncludesMod
  include Mod
  attr_reader :name
  def initialize name; @name = name; end
  def == other
    name == other.name
  end
end
  
class ClassNotInstantiated; end
class ClassNotInstantiated2; end
# :startdoc:

b1 = OBase.new "b1"
b2 = OBase.new "b2"
d1 = ODerived.new "d1"
d2 = ODerived.new "d2"
m1 = IncludesMod.new "m1"
m2 = IncludesMod.new "m2"

def space_of_objects
end

# Running the tests with the real Aquarium::Finders::ObjectFinder is too slow when looking
# for "objects" of type Class or Module, i.e., to retrieve classes and modules.
class MockObjectSpace
  @@space_of_objects = [OBase, ODerived, String, IncludesMod, Mod, Kernel, Class]
  
  def self.each_object type
    @@space_of_objects.each do |object|
      yield(object) if (object.kind_of?(type) and block_given?)
    end
  end
end

class TestObjectFinder < Aquarium::Finders::ObjectFinder
  def initialize
    super MockObjectSpace
  end
end

describe Aquarium::Finders::ObjectFinder, "#find_all_by_types" do
  it "should return an empty FinderResult#matched hash and FinderResult#not_matched list if no types are specified." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types
    actual.matched.should == {}
    actual.not_matched == []
  end

  it "should return the input types in the FinderResult#not_matched list if the specified types have no instances." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types ClassNotInstantiated
    actual.matched_keys.should == []
    actual.not_matched == [ClassNotInstantiated]
  end
end

describe Aquarium::Finders::ObjectFinder, ".find_all_by_types" do
  
  it "should return all objects of a specified base type and its derivatives." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types(OBase)
    actual.matched.size.should == 1
    actual.matched[OBase].sort_by {|o| o.name}.should == [b1, b2, d1, d2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a specified derived type." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types(ODerived)
    actual.matched.size.should == 1
    actual.matched[ODerived].sort_by {|o| o.name}.should == [d1, d2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a specified module." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types(Mod)
    actual.matched.size.should == 1
    actual.matched[Mod].sort_by {|o| o.name}.should == [m1, m2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a list of types." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types(ODerived, Mod)
    actual.matched.size.should == 2
    actual.matched[ODerived].sort_by {|o| o.name}.should == [d1, d2]
    actual.matched[Mod].sort_by {|o| o.name}.should == [m1, m2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of an array of types." do
    actual = Aquarium::Finders::ObjectFinder.new.find_all_by_types([ODerived, Mod])
    actual.matched.size.should == 2
    actual.matched[ODerived].sort_by {|o| o.name}.should == [d1, d2]
    actual.matched[Mod].sort_by {|o| o.name}.should == [m1, m2]
    actual.not_matched.should == {}
  end
  
end

describe Aquarium::Finders::ObjectFinder, "#find" do
  
  it "should return all objects of a specified base type and its derivatives." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => OBase
    actual.matched.size.should == 1
    actual.matched[OBase].sort_by {|o| o.name}.should == [b1, b2, d1, d2]
    actual.matched[OBase].each {|o| [b1, b2, d1, d2].include?(o)}
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a specified derived type." do
    actual = Aquarium::Finders::ObjectFinder.new.find :types => ODerived
    actual.matched.size.should == 1
    actual.matched[ODerived].sort_by {|o| o.name}.should == [d1, d2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a specified module." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => Mod
    actual.matched.size.should == 1
    actual.matched[Mod].sort_by {|o| o.name}.should == [m1, m2]
    actual.not_matched.should == {}
  end
  
  it "should return all objects of a list of types." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => [ODerived, Mod]
    actual.matched.size.should == 2
    actual.matched[ODerived].sort_by {|o| o.name}.should == [d1, d2]
    actual.matched[Mod].sort_by {|o| o.name}.should == [m1, m2]
    actual.not_matched.should == {}
  end
  
  it "should accept an array of one type or the type itself as the value for the :type key." do
    actual1 = Aquarium::Finders::ObjectFinder.new.find :type => Mod
    actual2 = Aquarium::Finders::ObjectFinder.new.find :type => [Mod]
    actual1.matched.should == actual2.matched
    actual1.matched.should == actual2.matched
  end
  
  it "should accept :type as a synonym for the :types key." do
    actual1 = Aquarium::Finders::ObjectFinder.new.find :types => Mod
    actual2 = Aquarium::Finders::ObjectFinder.new.find :type => Mod
    actual1.matched.should == actual2.matched
    actual1.matched.should == actual2.matched
  end
  

  it "should behave as find_all_by with a different invocation syntax." do
    actual1 = Aquarium::Finders::ObjectFinder.new.find :types => Mod
    actual2 = Aquarium::Finders::ObjectFinder.new.find :type => Mod
    actual1.matched.should == actual2.matched
    actual1.matched.should == actual2.matched
  end
end

describe Aquarium::Finders::ObjectFinder, "#find" do
  it "should return an empty FinderResult#matched hash and FinderResult#not_matched list if no types are specified." do
    actual = Aquarium::Finders::ObjectFinder.new.find
    actual.matched.should == {}
    actual.not_matched.should == {}
  end

  it "should return the input types in the FinderResult#not_matched list if the types have no instances." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => "ClassNotInstantiated"
    actual.matched_keys.should == []
    actual.not_matched_keys.should == [ClassNotInstantiated]
  end
  
  it "should accept a single type name as the value for the key :type." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => "ClassNotInstantiated"
    actual.matched_keys.should == []
    actual.not_matched_keys.should == [ClassNotInstantiated]
  end

  it "should accept an array of type names as the value for the key :types." do
    actual = Aquarium::Finders::ObjectFinder.new.find :type => ["ClassNotInstantiated", "ClassNotInstantiated2"]
    actual.matched_keys.should == []
    actual.not_matched_keys.size.should == 2
    actual.not_matched_keys.should include(ClassNotInstantiated)
    actual.not_matched_keys.should include(ClassNotInstantiated2)
  end

  it "should return the input types in the FinderResult#not_matched list if the types do not exist." do
    type_list = [/^NeverBeforeSeen/, "NotLikelyToExistClass"]
    actual = Aquarium::Finders::ObjectFinder.new.find :type => type_list
    actual.matched_keys.should == []
    actual.not_matched_keys.should == type_list
  end
  
  it "should accept :type and :types as synonyms for type name hash keys." do
    type_list = [/^NeverBeforeSeen/, "NotLikelyToExistClass"]
    actual1 = Aquarium::Finders::ObjectFinder.new.find :type => type_list
    actual2 = Aquarium::Finders::ObjectFinder.new.find :types => type_list
    actual1.matched.should == actual2.matched
    actual1.not_matched.should  == actual2.not_matched
  end
end

describe Aquarium::Finders::ObjectFinder, "#find" do 
  it "should return classes, not objects, when given Class as the type." do
    # Uses Test override for faster test execution.
    actual = TestObjectFinder.new.find :type => Class
    actual.matched[Class].should include(OBase)
    actual.matched[Class].should include(ODerived)
    actual.matched[Class].should include(String)
    actual.not_matched_keys.should == []
  end

  it "should return modules, not objects, when given Module as the type." do
    # Uses Test override for faster test execution.
    actual = TestObjectFinder.new.find :type => Module
    actual.matched[Module].should include(Mod)
    actual.matched[Module].should include(Kernel)
    actual.matched[Module].should include(Class)
    actual.not_matched_keys.should == []
  end
end