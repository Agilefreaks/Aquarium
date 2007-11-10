require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects/advice'
require 'aquarium/aspects/aspect'
include Aquarium::Aspects

describe Advice, "#sort_by_priority_order" do
  it "should return an empty array for empty input" do
    Aquarium::Aspects::Advice.sort_by_priority_order([]).should == []
  end
  
  it "should return a properly-sorted array for arbitrary input of valid advice kind symbols" do
    Aquarium::Aspects::Advice.sort_by_priority_order([:after_raising, :after_returning, :before, :after, :around]).should == [:around, :before, :after, :after_returning, :after_raising]
  end
  
  it "should accept strings for the advice kinds, but return sorted symbols" do
    Aquarium::Aspects::Advice.sort_by_priority_order(["after_raising", "after_returning", "before", "after", "around"]).should == [:around, :before, :after, :after_returning, :after_raising]
  end
end

describe Advice, "#invoke_original_join_point" do
  class InvocationCounter
    def initialize; @counter = 0; end
    def increment; @counter += 1; end
    def counter; @counter; end
  end
  
  it "should invoke the original join_point" do
    aspect1 = Aspect.new :before, :type => InvocationCounter, :method => :increment do |jp, o|
      jp.invoke_original_join_point
    end
    aspect2 = Aspect.new :around, :type => InvocationCounter, :method => :increment do |jp, o|
      jp.invoke_original_join_point
      jp.proceed
    end
    ic = InvocationCounter.new
    ic.increment
    ic.counter == 3
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Advice, "that raises an exception" do
  it "should add the kind of advice to the exception message." do
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args| 
      raise SpecExceptionForTesting.new("advice called with args: #{args.inspect}")
    end
    begin
      Watchful.new.public_watchful_method(:a1, :a2) || fail
    rescue => e
      e.message.should include("\"before\" advice")
    end
    aspect.unadvise
  end

  it "should add the \"Class#method\" of the advised object's type and method to the exception message." do
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args| 
      raise "advice called with args: #{args.inspect}"
    end
    begin
      Watchful.new.public_watchful_method(:a1, :a2) || fail
    rescue => e
      e.message.should include("Watchful#public_watchful_method")
    end
    aspect.unadvise
  end

  it "should add the \"Class.method\" of the advised type's class method to the exception message." do
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
      raise "advice called with args: #{args.inspect}"
    end
    begin
      Watchful.public_class_watchful_method(:a1, :a2) || fail
    rescue => e
      e.message.should include("Watchful.public_class_watchful_method")
    end
    aspect.unadvise
  end

  it "should rethrow an exception of the same type as the original exception." do
    class MyException < Exception; end
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
      raise MyException.new("advice called with args: #{args.inspect}")
    end
    lambda { Watchful.public_class_watchful_method :a1, :a2 }.should raise_error(MyException)
    aspect.unadvise
  end

  it "should rethrow an exception with the same backtrace as the original exception." do
    class MyException < Exception; end
    @backtrace = nil
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
      begin
        exception = MyException.new("advice called with args: #{args.inspect}")
        raise exception
      rescue Exception => e
        @backtrace = e.backtrace
        raise e
      end
    end
    begin
      Watchful.public_class_watchful_method(:a1, :a2) || fail
    rescue Exception => e
      e.backtrace.should == @backtrace
    end
    aspect.unadvise
  end
end

describe AdviceChainNode, "#new" do
  it "should raise if no advice block is specified" do
    lambda { Aquarium::Aspects::AdviceChainNode.new }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should raise if advice block appears to use an obsolete parameter list format" do
    lambda { Aquarium::Aspects::AdviceChainNode.new do |jp, *args|; end }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe AdviceChainNodeFactory, "#make_node" do
  it "should raise if an unknown advice kind is specified" do
    lambda {Aquarium::Aspects::AdviceChainNodeFactory.make_node :advice_kind => :foo}.should raise_error(Aquarium::Utils::InvalidOptions)    
  end

  it "should return a node of the type corresponding to the input advice kind" do
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :no).kind_of?(Aquarium::Aspects::NoAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :none).kind_of?(Aquarium::Aspects::NoAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :before).kind_of?(Aquarium::Aspects::BeforeAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :after).kind_of?(Aquarium::Aspects::AfterAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :after_raising).kind_of?(Aquarium::Aspects::AfterRaisingAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :after_returning).kind_of?(Aquarium::Aspects::AfterReturningAdviceChainNode).should be_true
    Aquarium::Aspects::AdviceChainNodeFactory.make_node(:advice_kind => :around).kind_of?(Aquarium::Aspects::AroundAdviceChainNode).should be_true
  end
end

