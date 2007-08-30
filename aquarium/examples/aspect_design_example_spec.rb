require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper.rb'
require 'aquarium'

# Example demonstrating emerging ideas about good aspect-oriented design. Specifically, this 
# example follows ideas of Jonathan Aldrich on "Open Modules", where a "module" (in the generic
# sense of the word...) is responsible for defining and maintaining the pointcuts that it is 
# willing to expose to potential aspects. Aspects are only allowed to advise the module through
# the pointcut. (Enforcing this constraint is TBD)
# Griswold, Sullivan, and collaborators have expanded on these ideas. See their IEEE Software,
# March 2006 paper.

module Aquarium
  class ClassWithStateAndBehavior
    def initialize *args
      @state = args
    end
    attr_accessor :state

    # A simpler version of the following would be 
    # STATE_CHANGE = pointcut :method => :state
    STATE_CHANGE = pointcut :attribute => :state, :attribute_options => :writer
  end
end

describe "An example of an aspect using a class-defined pointcut." do
  it "should observe state changes in the class." do
    @new_state = nil
    observer = after :pointcut => Aquarium::ClassWithStateAndBehavior::STATE_CHANGE do |jp, *args|
      @new_state = jp.context.advised_object.state
      @new_state.should be_eql(*args)
    end
    object = Aquarium::ClassWithStateAndBehavior.new(:a1, :a2, :a3)
    object.state = [:b1, :b2]
    @new_state.should == [:b1, :b2]
    observer.unadvise
  end
end

