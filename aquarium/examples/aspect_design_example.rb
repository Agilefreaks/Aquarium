#!/usr/bin/env ruby
# Example demonstrating emerging ideas about good aspect-oriented design. Specifically, this 
# example follows ideas of Jonathan Aldrich on "Open Modules", where a "module" (in the generic
# sense of the word...) is responsible for defining and maintaining the pointcuts that it is 
# willing to expose to potential aspects. Aspects are only allowed to advise the module through
# the pointcut. (Enforcing this constraint is TBD)
# Griswold, Sullivan, and collaborators have expanded on these ideas. See their IEEE Software,
# March 2006 paper.

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

module Aquarium
  class ClassWithStateAndBehavior
    include Aquarium::Aspects::DSL::AspectDSL
    def initialize *args
      @state = args
      p "Initializing: #{args.inspect}"
    end
    attr_accessor :state
  
    # A simpler version of the following would be 
    # STATE_CHANGE = pointcut :method => :state
    STATE_CHANGE = pointcut :attribute => :state, :attribute_options => :writer
  end
end

include Aquarium::Aspects

# Observe state changes in the class, using the class-defined pointcut.

observer = Aspect.new :after, :pointcut => Aquarium::ClassWithStateAndBehavior::STATE_CHANGE do |jp, *args|
  p "State has changed. "
  p "  New state is #{jp.context.advised_object.state.inspect}"
  p "  Equivalent to *args: #{args.inspect}"
end  

object = Aquarium::ClassWithStateAndBehavior.new(:a1, :a2, :a3)
object.state = [:b1, :b2]