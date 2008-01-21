#!/usr/bin/env ruby
# Example demonstrating "around" advice that traces calls to all methods in
# classes Foo and Bar

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

module Aquarium
  class Foo
    def initialize *args
      p "Inside:   Foo#initialize: args = #{args.inspect}"
    end
    def do_it *args
      p "Inside:   Foo#do_it: args = #{args.inspect}"
    end
  end

  module BarModule
    def initialize *args
      p "Inside:   BarModule#initialize: args = #{args.inspect}"
    end
    def do_something_else *args
      p "Inside:   BarModule#do_something_else: args = #{args.inspect}"
    end
  end

  class Bar
    include BarModule
  end
end

p "Before advising the methods:"
foo1 = Aquarium::Foo.new :a1, :a2
foo1.do_it :b1, :b2

bar1 = Aquarium::Bar.new :a3, :a4
bar1.do_something_else :b3, :b4

include Aquarium::Aspects

Aspect.new :around, :calls_to => :all_methods, :for_types => [Aquarium::Foo, Aquarium::Bar],
    :method_options => :exclude_ancestor_methods do |execution_point, obj, *args|
  begin
    p "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
    execution_point.proceed
  ensure
    p "Leaving:  #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
  end
end

p "After advising the methods. Notice that #intialize isn't advised:"
foo2 = Aquarium::Foo.new :a5, :a6
foo2.do_it :b5, :b6

bar1 = Aquarium::Bar.new :a7, :a8
bar1.do_something_else :b7, :b8

# The "begin/ensure/end" idiom shown causes the advice to return the correct value; the result
# of the "proceed", rather than the value returned by "p"!
Aspect.new :around, :invocations_of => :initialize, :for_types => [Aquarium::Foo, Aquarium::Bar],  
    :restricting_methods_to => :private_methods do |execution_point, obj, *args|
  begin
    p "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
    execution_point.proceed
  ensure
    p "Leaving:  #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
  end
end

p "After advising the private methods. Notice that #intialize is advised:"
foo2 = Aquarium::Foo.new :a9, :a10
foo2.do_it :b9, :b10

bar1 = Aquarium::Bar.new :a11, :a12
bar1.do_something_else :b11, :b12

