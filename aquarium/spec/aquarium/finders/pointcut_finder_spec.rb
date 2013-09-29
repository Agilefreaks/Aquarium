require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/dsl'
require 'aquarium/finders/pointcut_finder'
require File.dirname(__FILE__) + '/pointcut_finder_spec_test_classes'

describe Aquarium::Finders::PointcutFinder, "#find with invalid invocation parameters" do
  it "should raise if no options are specified." do
    expect { Aquarium::Finders::PointcutFinder.new.find}.to raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should raise if no type options are specified." do
    expect { Aquarium::Finders::PointcutFinder.new.find :matching => :foo}.to raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with valid type invocation parameters" do
  it "should accept :types with a single type." do
    expect { Aquarium::Finders::PointcutFinder.new.find :types => Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1, :noop => true}.not_to raise_error
  end
  it "should accept :types with an array of types." do
    expect { Aquarium::Finders::PointcutFinder.new.find :types => [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1, Aquarium::PointcutFinderTestClasses::PointcutConstantHolder2], :noop => true}.not_to raise_error
  end
  it "should accept :types with a regular expression for types." do
    expect { Aquarium::Finders::PointcutFinder.new.find :types => /Aquarium::PointcutFinderTestClasses::PointcutConstantHolder/, :noop => true}.not_to raise_error
  end
  Aquarium::Finders::PointcutFinder::CANONICAL_OPTIONS["types"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :types." do
      expect { Aquarium::Finders::PointcutFinder.new.find synonym.intern => /Aquarium::PointcutFinderTestClasses::PointcutConstantHolder/, :noop => true}.not_to raise_error
    end
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with nonexistent types specified" do
  it "should return an empty FinderResult." do
    found = Aquarium::Finders::PointcutFinder.new.find :types => /UndefinedType/
    found.matched.should be_empty
    found.not_matched.keys.should eql([/UndefinedType/])
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with no pointcut name parameter" do
  it "should return all constant and class variable pointcuts in the specified types." do
    found = Aquarium::Finders::PointcutFinder.new.find :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_pointcuts
  end
end

variants = {'constant and class variable ' => '', 'constant ' => 'constants_', 'class variable ' => 'class_variables_'}.each do |name, prefix|
  describe Aquarium::Finders::PointcutFinder, "#find with valid #{name}name invocation parameters" do
    it "should accept :#{prefix}matching => :all and match all #{name} pointcuts in the specified types." do
      found = Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => :all, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
      Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, eval("Aquarium::PointcutFinderTestClasses.all_#{prefix}pointcuts")
    end
    it "should accept :#{prefix}matching with a single pointcut name." do
      expect { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => :POINTCUT1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes, :noop => true}.not_to raise_error
    end
    it "should accept :#{prefix}matching with an array of pointcut names." do
      expect { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => [:POINTCUT1, :POINTCUT2], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes, :noop => true}.not_to raise_error
    end
    it "should accept :#{prefix}matching with a regular expression for pointcut names." do
      expect { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => /POINTCUT/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes, :noop => true}.not_to raise_error
    end
    Aquarium::Finders::PointcutFinder::CANONICAL_OPTIONS["#{prefix}matching"].each do |synonym|
      it "should accept :#{synonym} as a synonym for :#{prefix}matching." do
        expect { Aquarium::Finders::PointcutFinder.new.find synonym.intern => /POINTCUT/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes, :noop => true}.not_to raise_error
      end
    end
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => single pointcut name" do
  it "should return all constant and class variable pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => :POINTCUT1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1::POINTCUT1]
    found = Aquarium::Finders::PointcutFinder.new.find :matching => :pointcut1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1.pointcut1]
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => single pointcut name" do
  it "should return all constant pointcuts and no class variable pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => :POINTCUT1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1::POINTCUT1]
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => :pointcut1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => single pointcut name" do
  it "should return all class variable pointcuts and no constant pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => :POINTCUT1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => :pointcut1, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1.pointcut1]
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => /pointcut regexps/" do
  it "should return all constant and class variable pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => /POINTCUT(1+|2)/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => /pointcut1/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => /pointcut regexps/" do
  it "should return all constant pointcuts and no class variable pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => /POINTCUT(1+|2)/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => /pointcut1/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => /pointcut regexps/" do
  it "should return all class variable pointcuts and no constant pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => /POINTCUT(1+|2)/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => /pointcut1/, :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => [pointcut names]" do
  it "should return all constant and class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:pointcut1, :pointcut11], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => [pointcut names]" do
  it "should return all constant pointcuts and no class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:pointcut1, :pointcut11], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => [pointcut names]" do
  it "should return all class variable pointcuts and no constant pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:pointcut1, :pointcut11], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => [pointcut names and regular expressions]" do
  it "should return all constant and class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:pointcut1, /cut11$/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => [pointcut names and regular expressions]" do
  it "should return all constant pointcuts and no class variable pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:pointcut1, /cut11$/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => [pointcut names and regular expressions]" do
  it "should return all class variable pointcuts and no constant pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:pointcut1, /cut11$/], :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_class_variables_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with any combination of :matching, :constant_matching, and/or :class_variables_matching" do
  it "should return the union of all matching pointcuts." do
    found = Aquarium::Finders::PointcutFinder.new.find :types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes,
      :matching => [:POINTCUT1], 
      :constants_matching => /CUT[12]/, 
      :class_variables_matching => /pointcut/
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, Aquarium::PointcutFinderTestClasses.all_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :types_and_descendents." do
  it "should return the matching pointcuts in the hierarchy." do
    found = Aquarium::Finders::PointcutFinder.new.find :types_and_descendents => Aquarium::PointcutFinderTestClasses::ParentOfPointcutHolder
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutConstantHolderChild::POINTCUT]
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :types_and_ancestors." do
  it "should return the matching pointcuts in the hierarchy." do
    found = Aquarium::Finders::PointcutFinder.new.find :types_and_ancestors => Aquarium::PointcutFinderTestClasses::DescendentOfPointcutConstantHolderChild
    Aquarium::PointcutFinderTestClasses.found_pointcuts_should_match found, [Aquarium::PointcutFinderTestClasses::PointcutConstantHolderChild::POINTCUT]
  end
end

