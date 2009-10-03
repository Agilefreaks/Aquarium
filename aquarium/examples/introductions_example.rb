$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

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

include Aquarium::Finders

# First, find the types

found = TypeFinder.new.find :types => /Aquarium::TypeFinderIntroductionExampleTarget/

# Now, iterate through them and "extend" them with the module defining 
# the new behavior.

found.each {|t| t.extend Aquarium::TypeFinderIntroductionExampleModule }

# See if the "introduced" modules's method is there.

[Aquarium::TypeFinderIntroductionExampleTargetModule1, 
 Aquarium::TypeFinderIntroductionExampleTargetModule2,
 Aquarium::TypeFinderIntroductionExampleTargetClass1,
 Aquarium::TypeFinderIntroductionExampleTargetClass2].each do |t|
   p "type #{t}, method there? #{t.methods.include?("introduced_method")}"
end
