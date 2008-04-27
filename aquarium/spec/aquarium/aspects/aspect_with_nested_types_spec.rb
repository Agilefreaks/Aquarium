
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require 'aquarium/aspects'

include Aquarium::Aspects

# Explicitly check that nested types are handled correctly.

module Nested1
  module Nested2
    class MyClass
      def do1 *args
        yield
      end
    end
    
    module MyModule
      def do2 *args
        yield
      end
    end
  end
end

describe Aspect, ".new when advising methods in a nested class" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should correctly advise methods in a nested class." do
    myclass = Nested1::Nested2::MyClass.new
    advice_called = false
    @aspect = Aspect.new :before, :pointcut => {:type => Nested1::Nested2::MyClass, :methods => :do1} do |jp, obj, *args|
      advice_called = true
      jp.context.advice_kind.should == :before
      jp.context.advised_object.should == myclass
      jp.context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      jp.context.returned_value.should == nil
      jp.context.raised_exception.should == nil
    end 
    block_called = 0
    myclass.do1(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    advice_called.should be_true
  end

  it "should correctly advise methods in an instance of the nested class." do
    myclass = Nested1::Nested2::MyClass.new
    advice_called = false
    @aspect = Aspect.new :before, :pointcut => {:object => myclass, :methods => :do1} do |jp, obj, *args|
      advice_called = true
      jp.context.advice_kind.should == :before
      jp.context.advised_object.should == myclass
      jp.context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      jp.context.returned_value.should == nil
      jp.context.raised_exception.should == nil
    end 
    block_called = 0
    myclass.do1(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    advice_called.should be_true
  end
end

describe Aspect, ".new when advising methods in a nested module included by a class" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should correctly advise the module's methods when the nested module is specified." do
    class MyClassWithModule1
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule1.new
    advice_called = false
    @aspect = Aspect.new :before, :pointcut => {:type => Nested1::Nested2::MyModule, :methods => :do2} do |jp, obj, *args|
      advice_called = true
      jp.context.advice_kind.should == :before
      jp.context.advised_object.should == myclass
      jp.context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      jp.context.returned_value.should == nil
      jp.context.raised_exception.should == nil
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    advice_called.should be_true
  end

  it "should correctly advise the module's methods when the class is specified." do
    class MyClassWithModule2
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule2.new
    advice_called = false
    @aspect = Aspect.new :before, :pointcut => {:type => MyClassWithModule2, :methods => :do2} do |jp, obj, *args|
      advice_called = true
      jp.context.advice_kind.should == :before
      jp.context.advised_object.should == myclass
      jp.context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      jp.context.returned_value.should == nil
      jp.context.raised_exception.should == nil
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    advice_called.should be_true
  end

  it "should correctly advise the module's methods when an instance of the class is specified." do
    class MyClassWithModule3
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule3.new
    context = nil
    advice_called = false
    @aspect = Aspect.new :before, :pointcut => {:object => myclass, :methods => :do2} do |jp, obj, *args|
      advice_called = true
      jp.context.advice_kind.should == :before
      jp.context.advised_object.should == myclass
      jp.context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      jp.context.returned_value.should == nil
      jp.context.raised_exception.should == nil
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    advice_called.should be_true
  end
end

