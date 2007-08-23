
require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
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

describe Aspect, "#new when advising methods in a nested class" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should correctly advise methods in a nested class." do
    myclass = Nested1::Nested2::MyClass.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:type => Nested1::Nested2::MyClass, :methods => :do1} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    myclass.do1(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == myclass
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end

  it "should correctly advise methods in an instance of the nested class." do
    myclass = Nested1::Nested2::MyClass.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:object => myclass, :methods => :do1} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    myclass.do1(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == myclass
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end
end

describe Aspect, "#new when advising methods in a nested module included by a class" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should correctly advise the module's methods when the nested module is specified." do
    class MyClassWithModule1
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule1.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:type => Nested1::Nested2::MyModule, :methods => :do2} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == myclass
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end

  it "should correctly advise the module's methods when the class is specified." do
    class MyClassWithModule2
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule2.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:type => MyClassWithModule2, :methods => :do2} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == myclass
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end

  it "should correctly advise the module's methods when an instance of the class is specified." do
    class MyClassWithModule3
      include Nested1::Nested2::MyModule
    end

    myclass = MyClassWithModule3.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:object => myclass, :methods => :do2} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    myclass.do2(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == myclass
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end
end

