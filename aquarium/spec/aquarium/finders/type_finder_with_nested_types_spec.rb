require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_classes'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_nested_types'
require 'aquarium/finders/type_finder'

include Aquarium::Utils
  
def purge_uninteresting actuals
  # Remove extra stuff inserted by RSpec, Aquarium, and "pretty printer" (rake?), possibly in other specs! 
  actuals.matched_keys.reject do |t2| 
    t2.name.include?("Spec::") or t2.name =~ /Aquarium::(Utils|Extras|Examples|Aspects|PointcutFinderTestClasses)/ or t2.name =~ /^PP/
  end
end

describe TypeUtils, "#find types and their nested types, using :types_and_nested_types" do
  it "should find the matching types and their nested types." do
    Aquarium::NestedTestTypes.nested_in_NestedTestTypes.keys.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find :types_and_nested_types => (t.name)
      actual_keys = purge_uninteresting actual
      actual_keys.sort{|x,y| x.name <=> y.name}.should == Aquarium::NestedTestTypes.nested_in_NestedTestTypes[t].sort{|x,y| x.name <=> y.name}
      actual.not_matched_keys.should == []
    end
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["types_and_nested_types"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :types_and_nested_types" do
      lambda {Aquarium::Finders::TypeFinder.new.find synonym.intern => TypeUtils.sample_types, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end

describe TypeUtils, "#find nested types subtracting out excluded types and descendents, using :exclude_types_and_descendents" do
  it "should find the matching types and their descendent subtypes, minus the excluded type hierarchies." do
    actual = Aquarium::Finders::TypeFinder.new.find :types_and_nested_types => Aquarium::NestedTestTypes, 
      :exclude_types_and_nested_types => Aquarium::NestedTestTypes::TopModule
    expected = [Aquarium::NestedTestTypes] + Aquarium::NestedTestTypes.nested_in_NestedTestTypes[Aquarium::NestedTestTypes::TopClass]
    actual_keys = purge_uninteresting actual
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}
    actual.not_matched_keys.should == []
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["exclude_types_and_nested_types"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :exclude_types_and_nested_types" do
      lambda {Aquarium::Finders::TypeFinder.new.find :exclude_types_and_nested_types => ModuleForDescendents, synonym.intern => D1ForDescendents, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end
