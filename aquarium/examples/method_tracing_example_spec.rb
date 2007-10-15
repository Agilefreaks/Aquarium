require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper.rb'
require 'aquarium'

# Example demonstrating "around" advice that traces calls to all methods in
# classes Foo and Bar

module Aquarium
  module LogModule
    def log message
      @log ||= []
      @log << message
    end
    def logged_messages
      @log
    end
  end

  class Foo
    include LogModule
    def initialize *args
      log "Inside: Aquarium::Foo#initialize: args = #{args.inspect}"
    end
    def do_it *args
      log "Inside: Aquarium::Foo#do_it: args = #{args.inspect}"
    end
  end

  module BarModule
    include LogModule
    def initialize *args
      log "Inside: Aquarium::BarModule#initialize: args = #{args.inspect}"
    end
    def do_something_else *args
      log "Inside: Aquarium::BarModule#do_something_else: args = #{args.inspect}"
    end
  end

  class Bar
    include BarModule
  end
end

describe "An example without advice" do
  it "should not trace any method calls." do
    foo = Aquarium::Foo.new :a1, :a2
    foo.do_it :b1, :b2
    bar = Aquarium::Bar.new :a3, :a4
    bar.do_something_else :b3, :b4    

    foo.logged_messages.size.should == 2
    bar.logged_messages.size.should == 2
  end
end

describe "An example with advice on the public instance methods (excluding ancestor methods) of Foo" do
  it "should trace all calls to the public methods defined by Foo" do
    # The "begin/ensure/end" idiom shown causes the advice to return the correct value; the result
    # of the "proceed", rather than the value returned by "p"!
    aspect = Aquarium::Aspects::Aspect.new :around, :type => Aquarium::Foo, :methods => :all, :method_options => :exclude_ancestor_methods do |execution_point, *args|
      begin
        o = execution_point.context.advised_object
        o.log "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
        execution_point.proceed
      ensure
        o.log "Leaving: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
      end
    end
    
    foo = Aquarium::Foo.new :a5, :a6
    foo.do_it :b5, :b6
    foo.logged_messages.size.should == 4
    foo.logged_messages[0].should include("Inside: Aquarium::Foo#initialize")
    foo.logged_messages[1].should include("Entering")
    foo.logged_messages[2].should include("Inside: Aquarium::Foo#do_it")
    foo.logged_messages[3].should include("Leaving")
    aspect.unadvise    
  end
end

describe "An example with advice on the public instance methods (excluding ancestor methods) of Bar" do
  it "should not trace any calls to the public methods defined by the included BarModule" do
    aspect = Aquarium::Aspects::Aspect.new :around, :type => Aquarium::Bar, :methods => :all, :method_options => :exclude_ancestor_methods do |execution_point, *args|
      begin
        o = execution_point.context.advised_object
        o.log "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
        execution_point.proceed
      ensure
        o.log "Leaving: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
      end
    end
    
    bar = Aquarium::Bar.new :a7, :a8
    bar.do_something_else :b7, :b8
    bar.logged_messages.size.should == 2
    aspect.unadvise    
  end
end

describe "An example with advice on the public instance methods (including ancestor methods) of Bar" do
  it "should trace all calls to the public methods defined by the included BarModule" do
    aspect = Aquarium::Aspects::Aspect.new :around, :type => Aquarium::Bar, :methods => /^do_/ do |execution_point, *args|
      begin
        o = execution_point.context.advised_object
        o.log "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
        execution_point.proceed
      ensure
        o.log "Leaving: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
      end
    end
    
    bar = Aquarium::Bar.new :a9, :a10
    bar.do_something_else :b9, :b10
    bar.logged_messages.size.should == 4
    bar.logged_messages[0].should include("Inside: Aquarium::BarModule#initialize")
    bar.logged_messages[1].should include("Entering: Aquarium::Bar#do_something_else")
    bar.logged_messages[2].should include("Inside: Aquarium::BarModule#do_something_else")
    bar.logged_messages[3].should include("Leaving: Aquarium::Bar#do_something_else")
    aspect.unadvise    
  end
end


describe "An example with advice on the private initialize method of Foo and Bar" do
  it "should trace all calls to initialize" do
    before_methods = Aquarium::Foo.private_instance_methods.sort #- Object.private_methods.sort
    aspect = Aquarium::Aspects::Aspect.new :around, :types => [Aquarium::Foo, Aquarium::Bar], :methods => :initialize, :method_options => :private do |execution_point, *args|
      begin
        o = execution_point.context.advised_object
        o.log "Entering: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
        execution_point.proceed
      ensure
        o.log "Leaving: #{execution_point.target_type.name}##{execution_point.method_name}: args = #{args.inspect}"
      end
    end
    
    foo = Aquarium::Foo.new :a11, :a12
    foo.do_it :b11, :b12
    foo.logged_messages.size.should == 4
    foo.logged_messages[0].should include("Entering: Aquarium::Foo#initialize")
    foo.logged_messages[1].should include("Inside: Aquarium::Foo#initialize")
    foo.logged_messages[2].should include("Leaving: Aquarium::Foo#initialize")
    foo.logged_messages[3].should include("Inside: Aquarium::Foo#do_it")

    bar = Aquarium::Bar.new :a13, :a14
    bar.do_something_else :b13, :b14
    bar.logged_messages.size.should == 4
    bar.logged_messages[0].should include("Entering: Aquarium::Bar#initialize")
    bar.logged_messages[1].should include("Inside: Aquarium::BarModule#initialize")
    bar.logged_messages[2].should include("Leaving: Aquarium::Bar#initialize")
    bar.logged_messages[3].should include("Inside: Aquarium::BarModule#do_something_else")
    aspect.unadvise    
    after_methods = Aquarium::Foo.private_instance_methods.sort #- Object.private_methods.sort
    (before_methods - after_methods).should == []
  end
end
