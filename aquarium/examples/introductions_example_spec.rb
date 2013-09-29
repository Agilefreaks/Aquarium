require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper'
require 'aquarium'

# Example demonstrating how to use the TypeFinder class to conveniently "introduce" new
# methods and attributes in a set of types, like you might do with AspectJ in Java.
# Of course, in Ruby, you can simply use Object#extend(module). However, if you want to
# do this in a cross-cutting way, TypeFinder. is convenient.

module Aquarium
  module TypeFinderIntroductionExampleTargetModule1
  end
  module TypeFinderIntroductionExampleTargetModule2
  end
  class TypeFinderIntroductionExampleTargetClass1
  end
  class TypeFinderIntroductionExampleTargetClass2
  end
  module TypeFinderIntroductionExampleModule
    def introduced_method; end
  end
end

# include Aquarium::Finders

describe "Using TypeFinder to introduce modules in a set of other types" do
  it "should extend each found type with the specified module if you use the finder result #each method" do
    found = Aquarium::Finders::TypeFinder.new.find :types => /Aquarium::TypeFinderIntroductionExampleTarget/
    found.each {|t| t.extend Aquarium::TypeFinderIntroductionExampleModule }
    [Aquarium::TypeFinderIntroductionExampleTargetModule1, 
     Aquarium::TypeFinderIntroductionExampleTargetModule2,
     Aquarium::TypeFinderIntroductionExampleTargetClass1,
     Aquarium::TypeFinderIntroductionExampleTargetClass2].each do |t|
       t.methods.to include('introduced_method')
    end
  end
end
  