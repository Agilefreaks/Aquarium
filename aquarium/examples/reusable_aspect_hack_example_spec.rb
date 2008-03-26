require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper'
require 'aquarium'

# Example demonstrating a hack for defining a reusable aspect in a module
# so that the aspect only gets created when the module is included by another
# module or class.
# Hacking like this defies the spirit of Aquarium's goal of being "intuitive",
# so I created a feature request #19122 to address this problem.
#
# WARNING: put the "include ..." statement at the END of the class declaration,
# as shown below. If you put the include statement at the beginning, as you
# normally wouuld for including a module, it won't advice any join points, 
# because no methods will have been defined at that point!!
 
module Aquarium
  module Reusables
    module TraceMethods
      def self.advice_invoked?
        @@advice_invoked
      end
      def self.reset_advice_invoked
        @@advice_invoked = false
      end

      def self.append_features mod
        Aquarium::Aspects::Aspect.new :around, :ignore_no_matching_join_points => true,
            :type => mod, :methods => :all, :method_options => [:exclude_ancestor_methods] do |jp, object, *args|
          @@advice_invoked = true
          jp.proceed
        end
      end
    end    
  end
end

class NotTraced1
  def doit; end
end
class NotTraced2
  include Aquarium::Reusables::TraceMethods
  def doit; end
end
class Traced1
  def doit; end
  include Aquarium::Reusables::TraceMethods
end
class Traced2
  def doit; end
end

describe "Reusable aspect defined in a module can be evaluated at 'include' time if append_features is used" do
  before :each do
    Aquarium::Reusables::TraceMethods.reset_advice_invoked
  end
  
  it "should not advise types that don't include the module with the aspect" do
    NotTraced1.new.doit
    Aquarium::Reusables::TraceMethods.advice_invoked?.should be_false
  end
  
  it "should not advise any methods if the module with the aspect is included before any methods are defined!" do
    NotTraced2.new.doit
    Aquarium::Reusables::TraceMethods.advice_invoked?.should be_false
  end
  
  it "should advise methods if the module with the aspect is included after the methods are defined" do
    Traced1.new.doit
    Aquarium::Reusables::TraceMethods.advice_invoked?.should be_true
  end

  it "should advise methods after the module with the aspect is included" do
    Traced2.new.doit
    Aquarium::Reusables::TraceMethods.advice_invoked?.should be_false
    class Traced2
      include Aquarium::Reusables::TraceMethods
    end
    Traced2.new.doit
    Aquarium::Reusables::TraceMethods.advice_invoked?.should be_true
  end
end
