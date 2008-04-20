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
    include Aquarium::DSL
    def initialize *args
      @state = args
      p "Initializing: #{args.inspect}"
    end
    attr_accessor :state
  
    # Two alternative versions of the following pointcut would be 
    # STATE_CHANGE = pointcut :method => :state=
    # STATE_CHANGE = pointcut :attribute => :state, :attribute_options => [:writers]
    # Note that only matching on the attribute writers is important, especially
    # given the advice block below, because if the reader is allowed to be advised,
    # we get an infinite recursion of advice invocation! The correct solution is
    # the planned extension of the pointcut language to support condition tests for
    # context. I.e., we don't want the advice applied when it's already inside advice.
    STATE_CHANGE = pointcut :writing => :state
  end
end

include Aquarium::Aspects

# Observe state changes in the class, using the class-defined pointcut.
# Two ways of referencing the pointcut are shown. The first assumes you know the particular
# pointcuts you care about. The second is more general; it uses the recently-introduced
# :named_pointcut feature to search for all pointcuts matching a name in a set of types.

observer1 = Aspect.new :after, 
  :pointcut => Aquarium::ClassWithStateAndBehavior::STATE_CHANGE do |jp, obj, *args|
  p "State has changed. "
  state = obj.state
  p "  New state is #{state.nil? ? 'nil' : state.inspect}"
  p "  Equivalent to *args: #{args.inspect}"
end  

observer2 = Aspect.new :after, :named_pointcuts => {:matching => /CHANGE/, 
    :within_types => Aquarium::ClassWithStateAndBehavior} do |jp, obj, *args|
  p "State has changed. "
  state = obj.state
  p "  New state is #{state.nil? ? 'nil' : state.inspect}"
  p "  Equivalent to *args: #{args.inspect}"
end  

object = Aquarium::ClassWithStateAndBehavior.new(:a1, :a2, :a3)
object.state = [:b1, :b2]