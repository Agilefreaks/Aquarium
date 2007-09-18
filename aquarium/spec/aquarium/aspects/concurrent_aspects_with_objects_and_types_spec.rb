# Specifically tests behavior when two or more advices apply to the same join points, 
# where one advice is for the type and the other is for an object of the type.

require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require File.dirname(__FILE__) + '/concurrently_accessed'
require 'aquarium/aspects'

include Aquarium::Aspects

def make_aspect method, advice_kind, type_or_object_key, type_or_object
  Aspect.new advice_kind, :pointcut => {type_or_object_key => type_or_object, :method => method} do |jp, *args|
    @invoked << type_or_object_key
    jp.proceed if advice_kind == :around
  end
end

describe "Advising an object join point and then the corresponding type join point" do
  before :each do
    @aspects = []
    @invoked = []
    @accessed = ConcurrentlyAccessed.new
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end
  
  Aquarium::Aspects::Advice.kinds.each do |advice_kind|
    it "should invoke only the advice on the object join point for :#{advice_kind} advice" do
      method = advice_kind == :after_raising ? :invoke_raises : :invoke
      @aspects << make_aspect(method, advice_kind, :object, @accessed)
      @aspects << make_aspect(method, advice_kind, :type,   ConcurrentlyAccessed)
      begin
        @accessed.method(method).call :a1, :a2
        fail if advice_kind == :after_raising 
      rescue ConcurrentlyAccessed::Error
        fail unless advice_kind == :after_raising 
      end
      @invoked.should == [:object]
    end
  end  
end
  
describe "Advising a type join point and then the corresponding join point on an object of the type" do
  before :each do
    @aspects = []
    @invoked = []
    @accessed = ConcurrentlyAccessed.new
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end
  
  [:around, :before].each do |advice_kind|
    it "should invoke first the advice on the object join point and then invoke the advice on the type join point for :#{advice_kind} advice" do
      method = advice_kind == :after_raising ? :invoke_raises : :invoke
      @aspects << make_aspect(:invoke, advice_kind, :type,   ConcurrentlyAccessed)
      @aspects << make_aspect(:invoke, advice_kind, :object, @accessed)
      @accessed.invoke :a1, :a2
      @invoked.should == [:object, :type]
    end
  end

  [:after, :after_returning, :after_raising].each do |advice_kind|
    it "should invoke first the advice on the type join point and then invoke the advice on the object join point for :#{advice_kind} advice" do
      method = advice_kind == :after_raising ? :invoke_raises : :invoke
      @aspects << make_aspect(method, advice_kind, :type,   ConcurrentlyAccessed)
      @aspects << make_aspect(method, advice_kind, :object, @accessed)
      begin
        @accessed.method(method).call :a1, :a2
        fail if advice_kind == :after_raising 
      rescue ConcurrentlyAccessed::Error
        fail unless advice_kind == :after_raising 
      end
      @invoked.should == [:type, :object]
    end
  end
end

describe "Removing two advices, one from an object join point and one from the corresponding type join point" do
  before :each do
    @aspects = []
    @invoked = []
    @accessed = ConcurrentlyAccessed.new
  end

  Aquarium::Aspects::Advice.kinds.each do |advice_kind|
    it "should be removable for :#{advice_kind} advice only when the object join point was advised first" do
      method = advice_kind == :after_raising ? :invoke_raises : :invoke
      @aspects << make_aspect(method, advice_kind, :object, @accessed)
      @aspects << make_aspect(method, advice_kind, :type,   ConcurrentlyAccessed)
      @aspects.each {|a| a.unadvise}
      begin
        @accessed.method(method).call :a1, :a2
        fail if advice_kind == :after_raising 
      rescue ConcurrentlyAccessed::Error
        fail unless advice_kind == :after_raising 
      end
      @invoked.should == []
    end
  end  
end



