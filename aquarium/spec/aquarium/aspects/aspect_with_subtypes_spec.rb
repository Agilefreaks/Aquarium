
require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects'

include Aquarium::Aspects

# Explicitly check that advising subtypes works correctly.
# TODO Tests with modules included in classes.
module SubTypeAspects
  class Base
    attr_reader :base_state
    def doit *args
      @base_state = args
      yield args
    end
  end

  class Derived < Base
    attr_reader :derived_state
    def doit *args
      @derived_state = args
      super
      yield args
    end
  end
end

describe Aspect, " when advising overridden methods that call super" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should correctly invoke and advise subclass and superclass methods." do
    advised_types = []
    @aspect = Aspect.new :before, :pointcut => {:types => /SubTypeAspects::.*/, :methods => :doit} do |jp, obj, *args|
      advised_types << jp.target_type
    end 
    derived = SubTypeAspects::Derived.new
    block_called = 0
    derived.doit(:a1, :a2, :a3) { |*args| block_called += 1 }
    block_called.should == 2
    advised_types.should == [SubTypeAspects::Derived, SubTypeAspects::Base]
    derived.base_state.should == [:a1, :a2, :a3]
    derived.derived_state.should == [:a1, :a2, :a3]
  end
end


