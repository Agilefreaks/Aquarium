require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_classes'
require 'aquarium/finders/type_finder'

include Aquarium::Utils
  
def purge_actuals actuals
  # Remove extra stuff inserted by RSpec, Aquarium, and "pretty printer" (rake?), possibly in other specs! (TODO undo those when finished...)
  actuals.matched_keys.reject do |t2| 
    t2.name.include?("Spec::") or t2.name =~ /Aquarium::(Utils|Extras|Examples|Aspects|PointcutFinderTestClasses)/ or t2.name =~ /^PP/
  end
end

describe TypeUtils, "#find types and their descendents, using :types_and_descendents" do
  it "should find the matching types and their descendent subclasses, even in different nested modules." do
    TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find :types_and_descendents => (t.name)
      actual_keys = purge_actuals actual
      actual_keys.sort{|x,y| x.name <=> y.name}.should == TypeUtils.sample_types_descendents[t].sort{|x,y| x.name <=> y.name}
      actual.not_matched_keys.should == []
    end
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["types_and_descendents"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :types_and_descendents" do
      lambda {Aquarium::Finders::TypeFinder.new.find synonym.intern => TypeUtils.sample_types, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end

describe TypeUtils, "#find types subtracting out excluded types and descendents, using :exclude_types_and_descendents" do
  it "should find the matching types and their descendent subclasses, minus the excluded type hierarchies." do
    actual = Aquarium::Finders::TypeFinder.new.find :types_and_descendents => ModuleForDescendents, :exclude_types_and_descendents => D1ForDescendents
    actual_keys = purge_actuals actual
    expected = TypeUtils.sample_types_descendents[ModuleForDescendents].reject do |c|
      TypeUtils.sample_types_descendents[D1ForDescendents].include? c
    end
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}
    actual.not_matched_keys.should == []
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["exclude_types_and_descendents"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :exclude_types_and_descendents" do
      lambda {Aquarium::Finders::TypeFinder.new.find :types_and_descendents => ModuleForDescendents, synonym.intern => D1ForDescendents, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end


describe TypeUtils, "#find types and their ancestors, using :types_and_ancestors" do
  it "should find the matching types and their ancestors, even in different nested modules." do
    TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => (t.name)
      actual_keys = purge_actuals actual
      actual_keys.sort{|x,y| x.name <=> y.name}.should == TypeUtils.sample_types_ancestors[t].sort{|x,y| x.name <=> y.name}
      actual.not_matched_keys.should == []
    end
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["types_and_ancestors"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :types_and_ancestors" do
      lambda {Aquarium::Finders::TypeFinder.new.find synonym.intern => TypeUtils.sample_types, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end


describe TypeUtils, "#find types subtracting out excluded types and ancestors, using :exclude_types_and_ancestors" do
  it "should find the matching types and their ancestors, minus the excluded types and ancestors." do
    actual = Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => D1ForDescendents, :exclude_types_and_ancestors => ModuleForDescendents
    actual_keys = purge_actuals actual
    expected = TypeUtils.sample_types_ancestors[D1ForDescendents].reject do |c|
      TypeUtils.sample_types_ancestors[ModuleForDescendents].include? c
    end
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}
    actual.not_matched_keys.should == []
  end

  Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS["exclude_types_and_ancestors"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :exclude_types_and_ancestors" do
      lambda {Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => D1ForDescendents, synonym.intern => ModuleForDescendents, :noop => true}.should_not raise_error(InvalidOptions)
    end
  end
end


describe TypeUtils, "#find types and their descendents and ancestors" do
  it "should find the matching types and their descendents and ancestors, even in different nested modules." do
    TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => (t.name), :types_and_descendents => (t.name)
      actual_keys = purge_actuals actual
      expected = TypeUtils.sample_types_ancestors[t] + TypeUtils.sample_types_descendents[t]
      actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}.uniq
      actual.not_matched_keys.should == []
    end
  end
end

describe TypeUtils, "#find types subtracting out excluded types and their descendents and ancestors" do
  it "should find the matching types and their descendents and ancestors, minus the excluded types and their descendents and ancestors." do
    actual = Aquarium::Finders::TypeFinder.new.find \
      :types_and_ancestors => Aquarium::ForDescendents::NestedD1ForDescendents, 
      :types_and_descendents => Aquarium::ForDescendents::NestedD1ForDescendents, 
      :exclude_types_and_ancestors => Aquarium::ForDescendents::NestedD2ForDescendents, 
      :exclude_types_and_descendents => Aquarium::ForDescendents::NestedD2ForDescendents
    actual_keys = purge_actuals actual
    expected = [Aquarium::ForDescendents::NestedD1ForDescendents, Aquarium::ForDescendents::NestedD11ForDescendents, Aquarium::ForDescendents::NestedModuleForDescendents]
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}.uniq
    actual.not_matched_keys.should == []
  end
end

describe TypeUtils, "#find types and their descendents and ancestors, specified with regular expressions" do
  it "should find the matching types and their descendents and ancestors, even in different nested modules." do
    regexs = [/ForDescendents$/, /Aquarium::ForDescendents::.*ForDescendents/]
    actual = Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => regexs, :types_and_descendents => regexs
    actual_keys = purge_actuals actual
    expected = TypeUtils.sample_types_descendents_and_ancestors.keys + [Kernel, Object]
    actual_keys.size.should == expected.size
    expected.each do |t|
      actual_keys.should include(t)
    end
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}
    actual.not_matched_keys.should == []
  end
end

describe TypeUtils, "#find types and their descendents and ancestors, subtracting out excluded types and their descendents and ancestors, specified using regular expressions" do
  it "should find the matching types and their descendents and ancestors, minus the excluded types and their descendents and ancestors." do
    actual = Aquarium::Finders::TypeFinder.new.find :types_and_ancestors => /Aquarium::ForDescendents::.*D1ForDescendents/, 
      :types_and_descendents => /Aquarium::ForDescendents::.*D1ForDescendents/, 
      :exclude_types_and_ancestors => /Aquarium::ForDescendents::.*D2ForDescendents/, 
      :exclude_types_and_descendents => /Aquarium::ForDescendents::.*D2ForDescendents/
    actual_keys = purge_actuals actual
    expected = [Aquarium::ForDescendents::NestedD1ForDescendents, Aquarium::ForDescendents::NestedD11ForDescendents, Aquarium::ForDescendents::NestedModuleForDescendents]
    actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}
    actual.not_matched_keys.should == []
  end
end
