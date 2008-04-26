
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require 'aquarium/aspects'
require 'logger'

include Aquarium::Aspects

class MyError1 < StandardError; end
class MyError2 < StandardError; end
class MyError3 < StandardError; end
class ClassThatRaises
  class CTRException < Exception; end
  def raises
    raise CTRException
  end
end
class ClassThatRaisesString
  class CTRException < Exception; end
  def raises
    raise "A string exception."
  end
end


describe Aspect, " cannot advise the private implementation methods inserted by other aspects" do  
  it "should have no affect." do
    class WithAspectLikeMethod
      def _aspect_foo; end
    end
    aspect = Aspect.new(:after, :pointcut => {:type => WithAspectLikeMethod, :methods => :_aspect_foo}) {|jp, obj, *args| fail}
    WithAspectLikeMethod.new._aspect_foo
    aspect.unadvise
  end
end

describe Aspect, " when advising a type" do  
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect.unadvise
  end
  
  it "should not add new public instance or class methods that the advised type responds to." do
    all_public_methods_before = all_public_methods_of_type Watchful
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :method_options => :exclude_ancestor_methods}, :advice => @advice 
    (all_public_methods_of_type(Watchful) - all_public_methods_before).should == []
  end

  it "should not add new protected instance methods that the advised type responds to." do
    all_protected_methods_before = all_protected_methods_of_type Watchful
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :method_options => :exclude_ancestor_methods}, :advice => @advice  
    (all_protected_methods_of_type(Watchful) - all_protected_methods_before).should == []
  end
end

describe Aspect, " when advising an object" do  
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect.unadvise
  end

  it "should not add new public instance or class methods that the advised object responds to." do
    watchful = Watchful.new
    all_public_methods_before = all_public_methods_of_object Watchful
    @aspect = Aspect.new :after, :pointcut => {:object => watchful, :method_options => :exclude_ancestor_methods}, :advice => @advice  
    (all_public_methods_of_object(Watchful) - all_public_methods_before).should == []
  end

  it "should not add new protected instance or class methods that the advised object responds to." do
    watchful = Watchful.new
    all_protected_methods_before = all_protected_methods_of_object Watchful
    @aspect = Aspect.new :after, :pointcut => {:object => watchful, :method_options => :exclude_ancestor_methods}, :advice => @advice  
    (all_protected_methods_of_object(Watchful) - all_protected_methods_before).should == []
  end
end

describe Aspect, " with :before advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end

  it "should evaluate the advice before the method body and its block (if any)." do
    @aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
end

describe Aspect, " with :after advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the return value when the method returns normally." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :after
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == block_called
    context.raised_exception.should == nil
  end

  it "should pass the context information to the advice, including self, the method parameters, and the rescued exception when an exception is raised." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, obj, *args|
      context = jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.kind_of?(Watchful::WatchfulError).should be_true
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
  
  it "should ignore the value returned by the advice" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  it "should all the advice to assign a new return value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      jp.context.returned_value = %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[aa a b c d e]
  end

  it "should allow advice to change the exception raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new :after, :pointcut => {:type => ClassThatRaises, :methods => :raises} do |jp, obj, *args|
      aspect_advice_invoked = true
      jp.context.raised_exception = MyError1
    end 
    aspect_advice_invoked.should be_false
    ctr = ClassThatRaises.new
    lambda {ctr.raises}.should raise_error(MyError1)
    aspect_advice_invoked.should be_true
  end
end

describe Aspect, " with :after_returning advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the return value." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :after_returning
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == block_called
    context.raised_exception.should == nil
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
  
  it "should ignore the value returned by the advice" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after_returning, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  it "should allow the advice to change the returned value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after_returning, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      jp.context.returned_value = %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[aa a b c d e]
  end
end

describe Aspect, " with :after_raising advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the rescued exception." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after_raising, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, obj, *args|
      context = jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.advice_kind.should == :after_raising
    context.returned_value.should == nil
    context.raised_exception.kind_of?(Watchful::WatchfulError).should be_true
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after_raising, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private true
  end
  
  it "should invoke advice when exceptions of the specified type are raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => Watchful::WatchfulError, :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_true
    block_invoked.should be_true
  end
  
  it "should invoke advice when exceptions of the specified type are raised, which were specified with :exceptions => ..." do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising, :exceptions => Watchful::WatchfulError, :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_true
    block_invoked.should be_true
  end
  
  it "should not invoke advice when exceptions of types that don't match the specified exception type are raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => MyError1, :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should not invoke advice when exceptions of types that don't match the specified exception type are raised, which were specified with :exceptions => ..." do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising, :exceptions => MyError1, :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should invoke advice when one exception in the list of the specified types is raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => [Watchful::WatchfulError, MyError1], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_true
    block_invoked.should be_true
  end
  
  it "should not invoke advice when exceptions of types that don't match the specified list of exception types are raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => [MyError1, MyError2], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should not invoke advice when exceptions of types that don't match the specified list of exception types are raised, which were specified with :exceptions => ..." do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising, :exceptions => [MyError1, MyError2], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should treat :exception as a synonym for :exceptions" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising, :exception => [MyError1, MyError2], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should merge exceptions specified with :exception(s) and :after_raising" do
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => MyError1, :exception => [MyError2, MyError3], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, obj, *args| aspect_advice_invoked = true}
    @aspect.specification[:after_raising].should eql(Set.new([MyError1, MyError2, MyError3]))
  end
  
  it "should advise all methods that raise exceptions when no specific exceptions are specified" do
    aspect_advice_invoked = false
    @aspect = Aspect.new :after_raising, :pointcut => {:type => ClassThatRaises, :methods => :raises} do |jp, obj, *args|
      aspect_advice_invoked = true
    end 
    aspect_advice_invoked.should be_false
    ctr = ClassThatRaises.new
    lambda {ctr.raises}.should raise_error(ClassThatRaises::CTRException)
    aspect_advice_invoked.should be_true
  end

  it "should advise all methods that raise strings (which are converted to RuntimeError) when no specific exceptions are specified" do
    aspect_advice_invoked = false
    @aspect = Aspect.new :after_raising, :pointcut => {:type => ClassThatRaisesString, :methods => :raises} do |jp, obj, *args|
      aspect_advice_invoked = true
    end 
    aspect_advice_invoked.should be_false
    ctr = ClassThatRaisesString.new
    lambda {ctr.raises}.should raise_error(RuntimeError)
    aspect_advice_invoked.should be_true
  end

  it "should allow advice to change the exception raised" do
    aspect_advice_invoked = false
    @aspect = Aspect.new :after_raising, :pointcut => {:type => ClassThatRaises, :methods => :raises} do |jp, obj, *args|
      aspect_advice_invoked = true
      jp.context.raised_exception = MyError1
    end 
    aspect_advice_invoked.should be_false
    ctr = ClassThatRaises.new
    lambda {ctr.raises}.should raise_error(MyError1)
    aspect_advice_invoked.should be_true
  end
end

describe Aspect, " with :before and :after advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the return value for the after-advice case." do
    contexts = []
    @aspect = Aspect.new :before, :after, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]} do |jp, obj, *args|
      contexts << jp.context
    end 
    watchful = Watchful.new
    public_block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called += 1 }
    public_block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after
    contexts[0].returned_value.should == nil
    contexts[1].returned_value.should == 1
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.raised_exception.should == nil
    end

    %w[protected private].each do |protection|  
      block_called = 0
      watchful.send("#{protection}_watchful_method", :b1, :b2, :b3) {|*args| block_called += 1}
      block_called.should == 1
      contexts.size.should == 2
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private false, 2 
  end
end

describe Aspect, " with :before and :after_returning advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the return value for the after-advice case." do
    watchful = Watchful.new
    contexts = []
    @aspect = Aspect.new :before, :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      contexts << jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after_returning
    contexts[0].returned_value.should == nil
    contexts[1].returned_value.should == block_called
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.raised_exception.should == nil
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private false, 2 
  end
end

describe Aspect, " with :before and :after_raising advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the raised exception for the after-advice case." do
    watchful = Watchful.new
    contexts = []
    @aspect = Aspect.new :before, :after_raising, :pointcut => {:type => Watchful, :methods => :public_watchful_method_that_raises} do |jp, obj, *args|
      contexts << jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after_raising
    contexts[0].raised_exception.should == nil
    contexts[1].raised_exception.kind_of?(Watchful::WatchfulError).should be_true
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.returned_value.should == nil
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after_raising, :pointcut => {:type => Watchful, :methods => :public_watchful_method_that_raises} do |jp, obj, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private true, 2 
  end
end

describe Aspect, " with :around advice" do  
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including the object, advice kind, the method invocation parameters, etc." do
    contexts = []
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]} do |jp, obj, *args|
      contexts << jp.context
    end 
    watchful = Watchful.new
    public_block_called = false
    protected_block_called = false
    private_block_called = false
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called = true }
    watchful.send(:protected_watchful_method, :b1, :b2, :b3) {|*args| protected_block_called = true}
    watchful.send(:private_watchful_method, :c1, :c2, :c3) {|*args| private_block_called = true}
    public_block_called.should be_false  # proceed is never called!
    protected_block_called.should be_true
    private_block_called.should be_true
    contexts.size.should == 1
    contexts[0].advised_object.should == watchful
    contexts[0].advice_kind.should == :around
    contexts[0].returned_value.should == nil
    contexts[0].parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    contexts[0].raised_exception.should == nil
  end

  it "should advise subclass invocations of methods advised in the superclass." do
    module AdvisingSuperClass
      class SuperClass
        def public_method *args
          # yield *args if block_given?
        end
        protected
        def protected_method *args
          yield *args if block_given?
        end
        private
        def private_method *args
          yield *args if block_given?
        end
      end
      class SubClass < SuperClass
      end
    end
    
    context = nil
    @aspect = Aspect.new :around, :pointcut => {:type => AdvisingSuperClass::SuperClass, :methods => [:public_method]} do |jp, obj, *args|
      context = jp.context
    end 
    child = AdvisingSuperClass::SubClass.new
    public_block_called = false
    protected_block_called = false
    private_block_called = false
    child.public_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| fail }
    child.send(:protected_method, :b1, :b2, :b3) {|*args| protected_block_called = true}
    child.send(:private_method, :c1, :c2, :c3) {|*args| private_block_called = true}
    public_block_called.should be_false  # proceed is never called!
    protected_block_called.should be_true
    private_block_called.should be_true
    context.advised_object.should == child
    context.advice_kind.should == :around
    context.returned_value.should == nil
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.raised_exception.should == nil
  end

  it "should advise subclass invocations of methods advised in the subclass that are defined in the superclass." do
    module AdvisingSubClass
      class SuperClass
        def public_method *args
          # yield *args if block_given?
        end
        protected
        def protected_method *args
          yield *args if block_given?
        end
        private
        def private_method *args
          yield *args if block_given?
        end
      end
      class SubClass < SuperClass
      end
    end
    
    context = nil
    @aspect = Aspect.new :around, :pointcut => {:type => AdvisingSubClass::SuperClass, :methods => [:public_method]} do |jp, obj, *args|
      context = jp.context
    end 
    child = AdvisingSubClass::SubClass.new
    public_block_called = false
    protected_block_called = false
    private_block_called = false
    child.public_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| fail }
    child.send(:protected_method, :b1, :b2, :b3) {|*args| protected_block_called = true}
    child.send(:private_method, :c1, :c2, :c3) {|*args| private_block_called = true}
    public_block_called.should be_false  # proceed is never called!
    protected_block_called.should be_true
    private_block_called.should be_true
    context.advised_object.should == child
    context.advice_kind.should == :around
    context.returned_value.should == nil
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.raised_exception.should == nil
  end

  it "should not advise subclass overrides of superclass methods, when advising superclasses (but calls to superclass methods are advised)." do
    class WatchfulChild2 < Watchful
      def public_watchful_method *args
        @override_called = true
        yield(*args) if block_given?
      end
      attr_reader :override_called
      def initialize
        super
        @override_called = false
      end
    end
    @aspect = Aspect.new(:around, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]}) {|jp, obj, *args| fail}
    child = WatchfulChild2.new
    public_block_called = false
    child.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called = true }
    public_block_called.should be_true  # advice never called
  end

  it "should evaluate the advice and only evaluate the method body and its block (if any) when JoinPoint#proceed is called." do
    do_around_spec
  end
  
  it "should pass the block that was passed to the method by default if the block is not specified explicitly in the around advice in the call to JoinPoint#proceed." do
    do_around_spec
  end
  
  it "should pass the parameters and block that were passed to the method by default if JoinPoint#proceed is invoked without parameters and a block." do
    do_around_spec
  end
  
  it "should pass parameters passed explicitly to JoinPoint#proceed, rather than the original method parameters, but also pass the original block if a new block is not specified." do
    do_around_spec :a4, :a5, :a6
  end
  
  it "should pass parameters and a block passed explicitly to JoinPoint#proceed, rather than the original method parameters and block." do
    override_block_called = false
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      jp.proceed(:a4, :a5, :a6) {|*args| override_block_called = true}
    end 
    watchful = Watchful.new
    orig_block_called = false
    watchful.public_watchful_method(:a1, :a2, :a3) {|*args| orig_block_called = true}
    override_block_called.should be_true
    orig_block_called.should be_false
    watchful.public_watchful_method_args.should == [:a4, :a5, :a6]
  end
  
  it "should return the value returned by the advice, NOT the value returned by the advised join point!" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :around, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      jp.proceed
      %w[aa bb cc]
    end 
    ReturningValue.new.doit(ary).should == %w[aa bb cc]
  end

  it "should return the value returned by the advised join point only if the advice returns the value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :around, :type => ReturningValue, :method => :doit do |jp, obj, *args|
      begin
        jp.proceed
      ensure
        %w[aa bb cc]
      end
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  def do_around_spec *args_passed_to_proceed
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, obj, *args|
      @advice_called += 1
      returned_value = args_passed_to_proceed.empty? ? jp.proceed : jp.proceed(*args_passed_to_proceed) 
      @advice_called += 1
      returned_value
    end 
    do_watchful_public_protected_private false, 2, (args_passed_to_proceed.empty? ? nil : args_passed_to_proceed)
  end
end

describe Aspect, " with advice that calls JoinPoint#invoke_original_join_point" do
  class AdvicesInvocationCounter
    def initialize; @counter = 0; end
    def increment; @counter += 1; end
    def counter; @counter; end
  end
  
  it "should not call the intermediate advices" do
    aspect1 = Aspect.new :around, :type => AdvicesInvocationCounter, :method => :increment do |jp, obj, *args|; fail; end
    aspect2 = Aspect.new :around, :type => AdvicesInvocationCounter, :method => :increment do |jp, obj, *args|
      jp.invoke_original_join_point
    end
    aic = AdvicesInvocationCounter.new
    aic.increment
    aic.counter.should == 1
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Aspect, "#unadvise called more than once on the same aspect" do
  before(:all) do
    @advice = Proc.new {}
  end
  
  it "should do nothing on the second invocation." do
    aspect = Aspect.new :around, :type => Watchful, :method => /does_not_exist/, :advice => @advice, :severity => Logger::Severity::ERROR
    aspect.unadvise
    lambda {aspect.unadvise}.should_not raise_error
    lambda {aspect.unadvise}.should_not raise_error
  end
end

describe Aspect, "#unadvise for 'empty' aspects" do
  before(:all) do
    @advice = Proc.new {}
  end
  
  it "should do nothing for unadvised types." do
    expected_methods = (Watchful.private_methods + Watchful.private_instance_methods).sort
    aspect = Aspect.new :around, :type => Watchful, :method => /does_not_exist/, :advice => @advice, :severity => Logger::Severity::ERROR
    ((Watchful.private_methods + Watchful.private_instance_methods).sort - expected_methods).should == []
    aspect.unadvise
    ((Watchful.private_methods + Watchful.private_instance_methods).sort - expected_methods).should == []
    aspect.unadvise
    ((Watchful.private_methods + Watchful.private_instance_methods).sort - expected_methods).should == []
  end
    
  it "should do nothing for unadvised objects." do
    @watchful = Watchful.new
    expected_methods = @watchful.private_methods.sort
    aspect = Aspect.new :around, :object => @watchful, :method => /does_not_exist/, :advice => @advice, :severity => Logger::Severity::ERROR
    (@watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (@watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (@watchful.private_methods.sort - expected_methods).should == []
  end
end

describe Aspect, "#unadvise clean up" do
  before(:all) do
    @advice = Proc.new {}
    @watchful = Watchful.new
  end

  def get_type_methods
    public_methods    = (Watchful.public_methods    + Watchful.public_instance_methods).sort
    protected_methods = (Watchful.protected_methods + Watchful.protected_instance_methods).sort
    private_methods   = (Watchful.private_methods   + Watchful.private_instance_methods).sort
    [public_methods, protected_methods, private_methods]
  end
  
  def get_object_methods
    public_methods    = @watchful.public_methods.sort
    protected_methods = @watchful.protected_methods.sort
    private_methods   = @watchful.private_methods.sort
    [public_methods, protected_methods, private_methods]
  end
  
  def diff_methods actual, expected, private_should_not_be_equal = false
    3.times do |i|
      if i==2 && private_should_not_be_equal
        actual[i].should_not == expected[i] 
      else
        actual[i].should == expected[i] 
      end
    end
  end
  
  def do_unadvise_spec parameters, which_get_methods
    parameters[:after] = ''
    expected_methods = send(which_get_methods)
    advice_called = false
    aspect = Aspect.new(:after, parameters) {|jp, obj, *args| advice_called = true}
    diff_methods send(which_get_methods), expected_methods, true
    aspect.unadvise
    diff_methods send(which_get_methods), expected_methods

    %w[public protected private].each do |protection|
      advice_called = false
      block_called = false
      @watchful.send("#{protection}_watchful_method".intern, :a1, :a2, :a3) {|*args| block_called = true}
      advice_called.should be_false
      block_called.should be_true
    end
  end
  
  it "should remove all advice added by a pointcut-based aspect." do
    do_unadvise_spec({:pointcut => {:type => Watchful, :method_options => :exclude_ancestor_methods}}, :get_type_methods)
  end
  
  it "should remove all advice added by a type-based aspect." do
    do_unadvise_spec({:type => Watchful, :method_options => :exclude_ancestor_methods}, :get_type_methods)
  end
  
  it "should remove all advice added by an object-based aspect." do
    do_unadvise_spec({:object => @watchful, :method_options => :exclude_ancestor_methods}, :get_object_methods)
  end
end  

module Aquarium
  class FooForPrivateCheck
    def bar; end
  end
end

describe Aspect, "#unadvise clean up when all advices have been removed" do
  before(:all) do
    @advice = Proc.new {}
    @aspect1 = @aspect2 = nil
  end

  def check_cleanup before_methods, before_class_variables
    after  = yield
    (after[0] - before_methods).should_not == []
    (after[1] - before_class_variables).should_not == []
    @aspect1.unadvise
    after  = yield
    (after[0] - before_methods).should_not == []
    (after[1] - before_class_variables).should_not == []
    @aspect2.unadvise
    after  = yield
    (after[0] - before_methods).should == []
    (after[1] - before_class_variables).should == []
  end
  
  it "should remove all advice overhead for pointcut-based aspects." do
    before_methods = Aquarium::FooForPrivateCheck.private_instance_methods.sort
    before_class_variables = Aquarium::FooForPrivateCheck.class_variables.sort
    @aspect1 = Aspect.new(:before, :pointcut => {:type => Aquarium::FooForPrivateCheck, :method_options => :exclude_ancestor_methods}) {|jp, obj, *args| true}
    @aspect2 = Aspect.new(:after,  :pointcut => {:type => Aquarium::FooForPrivateCheck, :method_options => :exclude_ancestor_methods}) {|jp, obj, *args| true}
    check_cleanup(before_methods, before_class_variables) do
      [Aquarium::FooForPrivateCheck.private_instance_methods.sort, Aquarium::FooForPrivateCheck.class_variables.sort]
    end
  end
  
  it "should remove all advice overhead for type-based aspects." do
    before_methods = Aquarium::FooForPrivateCheck.private_instance_methods.sort
    before_class_variables = Aquarium::FooForPrivateCheck.class_variables.sort
    @aspect1 = Aspect.new(:before, :type => Aquarium::FooForPrivateCheck, :method_options => :exclude_ancestor_methods) {|jp, obj, *args| true}
    @aspect2 = Aspect.new(:after,  :type => Aquarium::FooForPrivateCheck, :method_options => :exclude_ancestor_methods) {|jp, obj, *args| true}
    check_cleanup(before_methods, before_class_variables) do
      [Aquarium::FooForPrivateCheck.private_instance_methods.sort, Aquarium::FooForPrivateCheck.class_variables.sort]
    end
  end

  it "should remove all advice overhead for object-based aspects." do
    object = Aquarium::FooForPrivateCheck.new
    before_methods = object.private_methods.sort
    before_class_variables = (class << object; self.class_variables.sort; end)
    @aspect1 = Aspect.new(:before, :object => object, :method_options => :exclude_ancestor_methods) {|jp, obj, *args| true}
    @aspect2 = Aspect.new(:after,  :object => object, :method_options => :exclude_ancestor_methods) {|jp, obj, *args| true}
    check_cleanup(before_methods, before_class_variables) do
      [object.private_methods.sort, (class << object; self.class_variables.sort; end)]
    end
  end
end

%w[public protected private].each do |protection|
  describe Aspect, " when advising and unadvising #{protection} methods" do
    it "should keep the protection level of the advised methods unchanged." do
      meta   = "#{protection}_instance_methods"
      method = "#{protection}_watchful_method"
      Watchful.send(meta).should include(method)
      aspect = Aspect.new(:after, :type => Watchful, :method => method.intern, :method_options => [protection.intern]) {|jp, obj, *args| true }
      Watchful.send(meta).should include(method)
      aspect.unadvise
      Watchful.send(meta).should include(method)
    end
  end  
end


describe Aspect, " when unadvising methods for instance-type pointcuts for type-defined methods" do
  class TypeDefinedMethodClass
    def inititalize; @called = false; end
    def m; @called = true; end
    attr_reader :called
  end
  
  it "should cause the object to respond to the type's original method." do
    object = TypeDefinedMethodClass.new
    aspect = Aspect.new(:before, :object => object, :method => :m) {true}
    aspect.unadvise
    object.m
    object.called.should be_true
  end
end

describe Aspect, " when unadvising methods for instance-type pointcuts for instance-defined methods" do
  class InstanceDefinedMethodClass
    def inititalize; @called = false; end
    attr_reader :called
  end
  
  it "should cause the object to respond to the object's original method." do
    object = TypeDefinedMethodClass.new
    def object.m; @called = true; end
    aspect = Aspect.new(:before, :object => object, :method => :m) {true}
    aspect.unadvise
    object.m
    object.called.should be_true
  end
end

describe Aspect, " when advising methods with non-alphanumeric characters" do
  module Aquarium::Aspects
    class ClassWithMethodNamesContainingOddChars
      @@method_names = []
      %w[= ! ?].each do |s|
        @@method_names << "_a#{s}" << "a#{s}"
      end
      %w[+ - * / < << > >> =~ == === <=> % ^ ~ [] & | `].each do |s|
        @@method_names << s 
      end
      @@method_names.each do |s|
        class_eval(<<-EOF, __FILE__, __LINE__)
          def #{s}; "#{s}"; end
        EOF
      end
      def self.method_names; @@method_names; end
    end
  end
  it "should work with any valid ruby character" do
    actual = ""
    Aspect.new :before, :type => Aquarium::Aspects::ClassWithMethodNamesContainingOddChars, 
      :methods => Aquarium::Aspects::ClassWithMethodNamesContainingOddChars.method_names do |jp, obj, *args|
      actual += ", #{jp.method_name}"
    end
    object = Aquarium::Aspects::ClassWithMethodNamesContainingOddChars.new
    expected = ""
    Aquarium::Aspects::ClassWithMethodNamesContainingOddChars.method_names.each do |s|
      object.send s
      expected += ", #{s}"
    end
    actual.should == expected
  end
end

describe Aspect, "#eql?" do
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect1.unadvise
    @aspect2.unadvise
  end
  
  it "should return true if both aspects have the same specification and pointcuts." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice 
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice 
    @aspect1.should eql(@aspect2)
  end

  it "should return true if both aspects have the same specification and pointcuts, even if the advice procs are not equal." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do true end
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do false end
    @aspect1.should eql(@aspect2)
  end

  it "should return false if each aspect advises pointcuts in different objects, even if the the objects are equivalent." do
    @aspect1 = Aspect.new :before, :pointcut => {:object => Watchful.new, :methods => :public_watchful_method} do true end
    @aspect2 = Aspect.new :before, :pointcut => {:object => Watchful.new, :methods => :public_watchful_method} do false end
    @aspect1.should_not eql(@aspect2)
  end
end

describe Aspect, "#==" do
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect1.unadvise
    @aspect2.unadvise
  end
  
  it "should be equivalent to #eql?." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice
    @aspect1.specification.should == @aspect2.specification
    @aspect1.pointcuts.should == @aspect2.pointcuts
    @aspect1.should eql(@aspect2)
    @aspect1.should == @aspect2
  end
end

describe Aspect, "#advice_chain_inspect" do
  it "should return the string '[nil]' if passed a nil advice chain" do
    Aspect.advice_chain_inspect(nil).should == "[nil]"
    chain = NoAdviceChainNode.new({:aspect => nil}) 
    Aspect.advice_chain_inspect(chain).should include("NoAdviceChainNode")
  end
end

def all_public_methods_of_type type
  (type.public_methods + type.public_instance_methods).sort
end
def all_protected_methods_of_type type
  (type.protected_methods + type.protected_instance_methods).sort
end
def all_public_methods_of_object object
  object.public_methods.sort
end
def all_protected_methods_of_object object
  object.protected_methods.sort
end

def do_watchful_public_protected_private raises = false, expected_advice_called_value = 1, args_passed_to_proceed = nil
  %w[public protected private].each do |protection|
    do_watchful_spec protection, raises, expected_advice_called_value, args_passed_to_proceed
  end
end

def do_watchful_spec protection, raises, expected_advice_called_value, args_passed_to_proceed
  suffix = raises ? "_that_raises" : ""
  expected_advice_called = protection == "public" ? expected_advice_called_value : 0
  watchful = Watchful.new
  @advice_called = 0
  block_called = 0
  if raises
    lambda {watchful.send("#{protection}_watchful_method#{suffix}".intern, :a1, :a2, :a3) {|*args| block_called += 1}}.should raise_error(Watchful::WatchfulError)
  else
    watchful.send("#{protection}_watchful_method#{suffix}".intern, :a1, :a2, :a3) {|*args| block_called += 1}
  end
  @advice_called.should == expected_advice_called
  block_called.should == 1
  expected_args = (protection == "public" && !args_passed_to_proceed.nil?) ? args_passed_to_proceed : [:a1, :a2, :a3]
  watchful.instance_variable_get("@#{protection}_watchful_method#{suffix}_args".intern).should == expected_args
end