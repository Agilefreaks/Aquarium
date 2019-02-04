require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/aspects/advice'
require 'aquarium/aspects/aspect'
include Aquarium::Aspects

describe Advice, "#sort_by_priority_order" do
  it "should return an empty array for empty input" do
    Advice.sort_by_priority_order([]).should == []
  end
  
  it "should return a properly-sorted array for arbitrary input of valid advice kind symbols" do
    Advice.sort_by_priority_order([:after_raising, :after_returning, :before, :after, :around]).should == [:around, :before, :after, :after_returning, :after_raising]
  end
  
  it "should accept strings for the advice kinds, but return sorted symbols" do
    Advice.sort_by_priority_order(["after_raising", "after_returning", "before", "after", "around"]).should == [:around, :before, :after, :after_returning, :after_raising]
  end
end

def puts_advice_chain aspect, label
    puts label
    aspect.pointcuts.each do |pc|
      pc.join_points_matched.each do |jp|
        chain = Aspect.get_advice_chain(jp)
        chain.each do |a|
          puts "advice_node: #{a.inspect}"
        end
        puts "last: #{chain.last}"
      end
    end
    puts ""
end
describe Advice, "#invoke_original_join_point" do
  class InvocationCounter
    def initialize; @counter = 0; end
    def increment; @counter += 1; end
    def counter; @counter; end
  end
  
  it "should invoke the original join_point with multiple advices" do
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
  
  Advice.kinds.each do |kind|
    it "should invoke the original join_point with #{kind} advice" do
      aspect = Aspect.new kind, :type => InvocationCounter, :method => :increment do |jp, o|
        jp.invoke_original_join_point
      end
      ic = InvocationCounter.new
      ic.increment
      ic.counter == 1
      aspect.unadvise
    end
  end
end

def should_raise_expected_exception_with_message message
  begin
    yield ; fail
  rescue => e
    e.message.should include(message)
  end
end

describe Advice, "that raises an exception" do
  context "when debug_backtraces is true" do
    before do
      @debug_backtraces_orig = Aquarium::Aspects::Advice.debug_backtraces
      Aquarium::Aspects::Advice.debug_backtraces = true
    end

    after do
      Aquarium::Aspects::Advice.debug_backtraces = @debug_backtraces_orig
    end

    it "should add the kind of advice to the exception message." do
      aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args| 
        raise SpecExceptionForTesting.new("advice called with args: #{args.inspect}")
      end
      should_raise_expected_exception_with_message("\"before\" advice") {Watchful.new.public_watchful_method(:a1, :a2)}
      aspect.unadvise
    end

    it "should add the \"Class#method\" of the advised object's type and method to the exception message." do
      aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args| 
        raise "advice called with args: #{args.inspect}"
      end
      should_raise_expected_exception_with_message("Watchful#public_watchful_method") {Watchful.new.public_watchful_method(:a1, :a2)}
      aspect.unadvise
    end

    it "should add the \"Class.method\" of the advised type's class method to the exception message." do
      aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
        raise "advice called with args: #{args.inspect}"
      end
      should_raise_expected_exception_with_message("Watchful.public_class_watchful_method") {Watchful.public_class_watchful_method(:a1, :a2)}
      aspect.unadvise
    end
  end

  it "should rethrow an exception of the same type as the original exception." do
    class MyException1 < Exception; end
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
      raise MyException1.new("advice called with args: #{args.inspect}")
    end
    expect { Watchful.public_class_watchful_method :a1, :a2 }.to raise_error(MyException1)
    aspect.unadvise
  end

  it "should rethrow an exception with the same backtrace as the original exception." do
    class MyException2 < Exception; end
    @backtrace = nil
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options => [:class]} do |jp, obj, *args| 
      begin
        exception = MyException2.new("advice called with args: #{args.inspect}")
        raise exception
      rescue Exception => e
        @backtrace = e.backtrace
        raise e
      end
    end
    begin
      Watchful.public_class_watchful_method(:a1, :a2) ; fail
    rescue Exception => e
      e.backtrace.should == @backtrace
    end
    aspect.unadvise
  end
end

describe Advice, "#invoke_original_join_point that raises an exception" do
  class InvokeOriginalJoinPointRaisingException
    class IOJPRException < Exception; end
    def raise_exception *args
      raise IOJPRException.new(":raise_exception called with args: #{args.inspect}")
    end
    def self.class_raise_exception *args
      raise IOJPRException.new(":class_raise_exception called with args: #{args.inspect}")
    end
  end

  context "when debug_backtraces is true" do
    before do
      @debug_backtraces_orig = Aquarium::Aspects::Advice.debug_backtraces
      Aquarium::Aspects::Advice.debug_backtraces = true
    end

    after do
      Aquarium::Aspects::Advice.debug_backtraces = @debug_backtraces_orig
    end

    it "should add the kind of advice to the exception message." do
      aspect = Aspect.new :before, 
      :pointcut => {:type => InvokeOriginalJoinPointRaisingException, :methods => :raise_exception} do |jp, obj, *args| 
        jp.invoke_original_join_point
      end
      begin
        InvokeOriginalJoinPointRaisingException.new.raise_exception(:a1, :a2) ; fail
      rescue InvokeOriginalJoinPointRaisingException::IOJPRException => e
        e.message.should include("\"before\" advice")
      end
      aspect.unadvise
    end

    it "should add the \"Class#method\" of the advised object's type and method to the exception message." do
      aspect = Aspect.new :before, 
      :pointcut => {:type => InvokeOriginalJoinPointRaisingException, :methods => :raise_exception} do |jp, obj, *args| 
        jp.invoke_original_join_point
      end
      begin
        InvokeOriginalJoinPointRaisingException.new.raise_exception(:a1, :a2) ; fail
      rescue InvokeOriginalJoinPointRaisingException::IOJPRException => e
        e.message.should include("InvokeOriginalJoinPointRaisingException#raise_exception")
      end
      aspect.unadvise
    end

    it "should add the \"Class.method\" of the advised type's class method to the exception message." do
      aspect = Aspect.new :before, 
      :pointcut => {:type => InvokeOriginalJoinPointRaisingException, :methods => :class_raise_exception, 
        :method_options => [:class]} do |jp, obj, *args| 
        jp.invoke_original_join_point
      end
      begin
        InvokeOriginalJoinPointRaisingException.class_raise_exception(:a1, :a2) ; fail
      rescue InvokeOriginalJoinPointRaisingException::IOJPRException => e
        e.message.should include("InvokeOriginalJoinPointRaisingException.class_raise_exception")
      end
      aspect.unadvise
    end
  end

  it "should rethrow an exception of the same type as the original exception." do
    aspect = Aspect.new :before, 
      :pointcut => {:type => InvokeOriginalJoinPointRaisingException, :methods => :class_raise_exception, 
      :method_options => [:class]} do |jp, obj, *args| 
        jp.invoke_original_join_point
    end
    expect { InvokeOriginalJoinPointRaisingException.class_raise_exception :a1, :a2 }.to raise_error(InvokeOriginalJoinPointRaisingException::IOJPRException)
    aspect.unadvise
  end

  it "should rethrow an exception with the same backtrace as the original exception." do
    @backtrace = nil
    aspect = Aspect.new :before, 
      :pointcut => {:type => InvokeOriginalJoinPointRaisingException, :methods => :class_raise_exception, 
      :method_options => [:class]} do |jp, obj, *args| 
      begin
        jp.invoke_original_join_point
      rescue Exception => e
        @backtrace = e.backtrace
        raise e
      end
    end
    begin
      InvokeOriginalJoinPointRaisingException.class_raise_exception(:a1, :a2) ; fail
    rescue Exception => e
      e.backtrace.should == @backtrace
    end
    aspect.unadvise
  end
end

describe Advice, ".compare_advice_kinds with nil or UNKNOWN_ADVICE_KIND" do
  it "should return 0 when comparing nil to nil" do
    Advice.compare_advice_kinds(nil, nil).should == 0
  end
  it "should return 0 when comparing UNKNOWN_ADVICE_KIND to UNKNOWN_ADVICE_KIND" do
    Advice.compare_advice_kinds(Advice::UNKNOWN_ADVICE_KIND, Advice::UNKNOWN_ADVICE_KIND).should == 0
  end
  it "should return 1 when comparing UNKNOWN_ADVICE_KIND to nil" do
    Advice.compare_advice_kinds(Advice::UNKNOWN_ADVICE_KIND, nil).should == 1
  end
  it "should return -1 when comparing nil to UNKNOWN_ADVICE_KIND" do
    Advice.compare_advice_kinds(nil, Advice::UNKNOWN_ADVICE_KIND).should == -1
  end

  Advice::KINDS_IN_PRIORITY_ORDER.each do |kind|
    it "should return 1 when comparing :#{kind} to UNKNOWN_ADVICE_KIND" do
      Advice.compare_advice_kinds(kind, Advice::UNKNOWN_ADVICE_KIND).should == 1
    end
  end
  Advice::KINDS_IN_PRIORITY_ORDER.each do |kind|
    it "should return -1 when comparing UNKNOWN_ADVICE_KIND to :#{kind}" do
      Advice.compare_advice_kinds(Advice::UNKNOWN_ADVICE_KIND, kind).should == -1
    end
  end
end
  
describe Advice, ".compare_advice_kinds between 'real' advice kinds" do
  Advice::KINDS_IN_PRIORITY_ORDER.each do |kind1|
    Advice::KINDS_IN_PRIORITY_ORDER.each do |kind2|
      expected = Advice::KINDS_IN_PRIORITY_ORDER.index(kind1) <=> Advice::KINDS_IN_PRIORITY_ORDER.index(kind2)
      it "should return #{expected} when comparing :#{kind1} to :#{kind2} (using priority order)" do
        Advice.compare_advice_kinds(kind1, kind2).should == expected
      end
    end
  end
end

describe AdviceChainNodeFactory, "#make_node" do
  it "should raise if an unknown advice kind is specified" do
    expect {AdviceChainNodeFactory.make_node :advice_kind => :foo}.to raise_error(Aquarium::Utils::InvalidOptions)    
  end

  it "should return a node of the type corresponding to the input advice kind" do
    AdviceChainNodeFactory.make_node(:advice_kind => :no).kind_of?(NoAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :none).kind_of?(NoAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :before).kind_of?(BeforeAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :after).kind_of?(AfterAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :after_raising).kind_of?(AfterRaisingAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :after_returning).kind_of?(AfterReturningAdviceChainNode).should be_truthy
    AdviceChainNodeFactory.make_node(:advice_kind => :around).kind_of?(AroundAdviceChainNode).should be_truthy
  end
end

