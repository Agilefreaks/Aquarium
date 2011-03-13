require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils/type_utils_sample_nested_types'
require 'aquarium/aspects/aspect'
require 'aquarium/dsl'
require 'aquarium/utils/array_utils'
require 'aquarium/finders/pointcut_finder_spec_test_classes'
require 'stringio'
require 'profiler'

include Aquarium::Aspects
include Aquarium::Utils::ArrayUtils
include Aquarium::PointcutFinderTestClasses 


def aspects_should_be_equal num_jps, aspect1, aspect2
  # We don't use @aspect1.should eql(@aspect2) because the "specifications" are different.
  aspect1.pointcuts.size.should == 1
  aspect2.pointcuts.size.should == 1
  aspect1.pointcuts.should eql(aspect2.pointcuts)
  aspect1.advice.should eql(@advice)
  aspect2.advice.should eql(@advice)
  join_points_should_be_equal num_jps, aspect1, aspect2
end

def join_points_should_be_equal num_jps, aspect1, aspect2
  aspect1.join_points_matched.size.should == num_jps
  aspect2.join_points_matched.size.should == num_jps
  aspect1.join_points_matched.each {|jp| @expected_methods.should include(jp.method_name)}
  aspect2.join_points_matched.each {|jp| @expected_methods.should include(jp.method_name)}
  aspect1.join_points_matched.should eql(aspect2.join_points_matched)
  aspect1.join_points_not_matched.should eql(aspect2.join_points_not_matched)
end

module Aquarium
  class AspectInvocationTestClass
    include Aquarium::DSL
    attr_accessor :public_test_method_args
    def public_test_method *args; @args=args; end
    protected
    def protected_test_method *args; @args=args; end
    private
    def private_test_method *args; @args=args; end
    def self.public_class_test_method *args; end
    def self.private_class_test_method *args; end
    private_class_method :private_class_test_method
  end
  class AspectInvocationTestClass2
    include Aquarium::DSL
    attr_accessor :public_test_method_args
    def public_test_method *args; @args=args; end
  end
  class AspectInvocationTestClass3
    attr_accessor :public_test_method_args
    attr_accessor :public_test_method_args2
    def public_test_method *args; @args=args; end
  end
end

describe Aspect, "methods" do
  include Aquarium::TypeUtilsStub
  
  before :all do
    stub_type_utils_descendents
  end
  after :all do
    unstub_type_utils_descendents
  end
    
  describe Aspect, ".new (the :ignore_no_matching_join_points parameter that specifies whether or not to warn about no join point matches)" do
    before :each do
      @log_stream = StringIO.new
    end
  
    it "should warn about no join point matches if the :ignore_no_matching_join_points is not specified." do
      lambda {Aspect.new(:after, :logger_stream => @log_stream) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      @log_stream.string.should_not be_empty
    end
    it "should warn about no join point matches if :ignore_no_matching_join_points => false is specified." do
      lambda {Aspect.new(:after, :logger_stream => @log_stream, :ignore_no_matching_join_points => false) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      @log_stream.string.should_not be_empty
    end
    it "should not warn about no join point matches if :ignore_no_matching_join_points => true is specified." do
      lambda {Aspect.new(:after, :logger_stream => @log_stream, :ignore_no_matching_join_points => true) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      @log_stream.string.should be_empty
    end
  end

  describe Aspect, ".new (parameters that specify the kind of advice)" do
    before :all do
      @pointcut_opts = {:type => Aquarium::AspectInvocationTestClass}
    end
    
    it "should require the kind of advice as the first parameter." do
      lambda { Aspect.new :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should contain no other advice types if :around advice specified." do
      lambda { Aspect.new :around, :before,          :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda { Aspect.new :around, :after,           :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda { Aspect.new :around, :after_returning, :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda { Aspect.new :around, :after_raising,   :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should allow only one of :after, :after_returning, or :after_raising advice to be specified." do
      lambda { Aspect.new :after, :after_returning, :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda { Aspect.new :after, :after_raising,   :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda { Aspect.new :after_returning, :after_raising, :pointcut => @pointcut_opts }.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should allow :before to be specified with :after." do
      lambda { Aspect.new :before, :after, :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should allow :before to be specified with :after_returning." do
      lambda { Aspect.new :before, :after_returning, :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should allow :before to be specified with :after_raising." do
      lambda { Aspect.new :before, :after_raising,   :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should accept a single exception specified with :after_raising." do
      lambda { Aspect.new :before, :after_raising => Exception, :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should accept a list of exceptions specified with :after_raising." do
      lambda { Aspect.new :before, :after_raising => [Exception, String], :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should accept a separate :exceptions => list of exceptions specified with :after_raising." do
      lambda { Aspect.new :before, :after_raising, :exceptions => [Exception, String], :pointcut => @pointcut_opts, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should reject the :exceptions argument unless specified with :after_raising." do
      lambda { Aspect.new :before, :after, :exceptions => [Exception, String], :pointcut => @pointcut_opts, :noop => true }.should raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Aspect, ".new (parameters that specify pointcuts)" do
    before :all do
      @pointcut_opts = {:type => Aquarium::AspectInvocationTestClass}
    end
    
    it "should contain at least one of :method(s), :pointcut(s), :named_pointcut(s), :type(s), or :object(s)." do
      lambda {Aspect.new(:after, :ignore_no_matching_join_points => true) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should contain at least one of :pointcut(s), :named_pointcut(s), :type(s), or :object(s) unless :default_objects => object is given." do
      aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass.new, :method => :public_test_method, :noop => true) {true}
    end

    it "should ignore the :default_objects if at least one other :object is given and the :default_objects are objects." do
      object1 = Aquarium::AspectInvocationTestClass.new
      object2 = Aquarium::AspectInvocationTestClass2.new
      aspect = Aspect.new(:after, :default_objects => object1, :object => object2, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == object1}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one other :object is given and the :default_objects are types." do
      object = Aquarium::AspectInvocationTestClass2.new
      aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass, 
        :object => object, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == Aquarium::AspectInvocationTestClass}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one :pointcut is given even if the :default_objects => object are given." do
      object = Aquarium::AspectInvocationTestClass.new
      aspect = Aspect.new(:after, :default_objects => object, 
        :pointcut => {:type => Aquarium::AspectInvocationTestClass2, :method => :public_test_method}, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == object}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one :pointcut is given even if the :default_objects => type are given." do
      aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass, 
        :pointcut => {:type => Aquarium::AspectInvocationTestClass2, :method => :public_test_method}, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == Aquarium::AspectInvocationTestClass}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one :join_point is given and the :default_objects are objects." do
      join_point = JoinPoint.new :type => Aquarium::AspectInvocationTestClass2, :method => :public_test_method
      object = Aquarium::AspectInvocationTestClass.new
      aspect = Aspect.new(:after, :default_objects => object, :join_point => join_point, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == object}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one :join_point is given and the :default_objects are types." do
      join_point = JoinPoint.new :type => Aquarium::AspectInvocationTestClass2, :method => :public_test_method
      aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass, :join_point => join_point, :method => :public_test_method) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == Aquarium::AspectInvocationTestClass}
      aspect.unadvise
    end

    [:type, :type_and_descendents, :type_and_ancestors, :type_and_nested_types].each do |type_key|
      it "should ignore the :default_objects if at least one :#{type_key} is given and the :default_objects are objects." do
        object = Aquarium::AspectInvocationTestClass.new
        aspect = Aspect.new(:after, :default_objects => object, type_key => Aquarium::AspectInvocationTestClass2, :method => :public_test_method, :method => :public_test_method) {true}
        aspect.join_points_matched.size.should == 1
        aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == object}
        aspect.unadvise
      end

      it "should ignore the :default_objects if at least one :#{type_key} is given and the :default_objects are types." do
        aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass, type_key => Aquarium::AspectInvocationTestClass2, :method => :public_test_method, :method => :public_test_method) {true}
        aspect.join_points_matched.size.should == 1
        aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == Aquarium::AspectInvocationTestClass}
        aspect.unadvise
      end
    end

    Aspect::CANONICAL_OPTIONS["default_objects"].each do |key|
      it "should accept :#{key} as a synonym for :default_objects." do
        aspect = Aspect.new(:after, key.intern => Aquarium::AspectInvocationTestClass.new, :method => :public_test_method, :noop => true) {true}
        aspect.unadvise
      end
    end
  
    it "should not contain :pointcut(s) and either :type(s) or :object(s)." do
      lambda {Aspect.new(:after, :pointcuts => @pointcut_opts, :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda {Aspect.new(:after, :pointcuts => @pointcut_opts, :object => Aquarium::AspectInvocationTestClass.new, :method => :public_test_method) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Aspect, ".new (parameters that specify named constant and/or class variable pointcuts)" do
    it "should contain at least one :types or TypeFinder synonym for :types." do
      lambda {Aspect.new(:after, :named_pointcuts => {}, :noop => true) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda {Aspect.new(:after, :named_pointcuts => {:types => all_pointcut_classes}, :noop => true) {true}}.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should ignore the :default_objects if at least one :named_pointcut is given even if the :default_objects => object are given." do
      object = Aquarium::AspectInvocationTestClass.new
      aspect = Aspect.new(:after, :default_objects => object, :named_pointcut => {:types => Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1}) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == object}
      aspect.unadvise
    end

    it "should ignore the :default_objects if at least one :named_pointcut is given even if the :default_objects => type are given." do
      aspect = Aspect.new(:after, :default_objects => Aquarium::AspectInvocationTestClass, :named_pointcut => {:types => Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1}) {true}
      aspect.join_points_matched.size.should == 1
      aspect.join_points_matched.each {|jp| jp.type_or_object.should_not == Aquarium::AspectInvocationTestClass}
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["named_pointcuts"].each do |key|
      it "should accept :#{key} as a synonym for :named_pointcuts." do
        aspect = Aspect.new :before, key.intern => {:types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes}, :noop => true do; end
        aspect.unadvise
      end
    end

    it "should not contain :named_pointcut(s) and either :type(s) or :object(s)." do
      lambda {Aspect.new(:after, :named_pointcuts => {:types => Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1}, :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
      lambda {Aspect.new(:after, :named_pointcuts => {:types => Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1}, :object => Aquarium::AspectInvocationTestClass.new, :method => :public_test_method) {true}}.should raise_error(Aquarium::Utils::InvalidOptions)
    end
  end
  
  describe Aspect, ".new with :types parameter" do
    it "should advise the specified types." do
      @advice_called = false
      aspect = Aspect.new :before, :types => Aquarium::AspectInvocationTestClass, :method => :public_test_method do; @advice_called = true; end
      Aquarium::AspectInvocationTestClass.new.public_test_method
      aspect.unadvise
      @advice_called.should be_true
    end

    Aspect::CANONICAL_OPTIONS["types"].each do |key|
      it "should accept :#{key} as a synonym for :types." do
        aspect = Aspect.new :before, key.intern => Aquarium::AspectInvocationTestClass, :method => :public_test_method, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new with :pointcuts parameter" do
    it "should advise the specified pointcuts." do
      @advice_called = false
      aspect = Aspect.new :before, :pointcuts => {:types => Aquarium::AspectInvocationTestClass, :method => :public_test_method} do; @advice_called = true; end
      Aquarium::AspectInvocationTestClass.new.public_test_method
      aspect.unadvise
      @advice_called.should be_true
    end

    Aspect::CANONICAL_OPTIONS["pointcuts"].each do |key|
      it "should accept :#{key} as a synonym for :pointcuts." do
        aspect = Aspect.new :before, key.intern => {:type => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new with :objects parameter" do
    it "should advise the specified objects." do
      @advice_called = false
      object = Aquarium::AspectInvocationTestClass.new
      aspect = Aspect.new :before, :objects => object, :method => :public_test_method do; @advice_called = true; end
      object.public_test_method
      aspect.unadvise
      @advice_called.should be_true
    end

    Aspect::CANONICAL_OPTIONS["objects"].each do |key|
      it "should accept :#{key} as a synonym for :objects." do
        object = Aquarium::AspectInvocationTestClass.new
        aspect = Aspect.new :before, key.intern => object, :method => :public_test_method, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new with :methods parameter" do
    it "should advise the specified methods." do
      @advice_called = false
      aspect = Aspect.new :before, :types => Aquarium::AspectInvocationTestClass, :methods => :public_test_method do; @advice_called = true; end
      Aquarium::AspectInvocationTestClass.new.public_test_method
      aspect.unadvise
      @advice_called.should be_true
    end

    Aspect::CANONICAL_OPTIONS["methods"].each do |key|
      it "should accept :#{key} as a synonym for :methods." do
        aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, key.intern => :public_test_method, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (:attributes parameter)" do
    Aspect::CANONICAL_OPTIONS["attributes"].each do |key|
      it "should accept :#{key} as a synonym for :attributes." do
        @advice_called = false
        aspect = Aspect.new :before, :types => Aquarium::AspectInvocationTestClass, :attributes => :public_test_method_args do; @advice_called = true; end
        Aquarium::AspectInvocationTestClass.new.public_test_method_args
        aspect.unadvise
      end
    end

    it "should require the values for :reading => ... and :writing => ... to be equal if both are specified." do
      @advice = Proc.new {}
      lambda {Aspect.new :before, :type => Aquarium::AspectInvocationTestClass3, 
        :reading => :public_test_method_args, :writing => :public_test_method_args2, :advice => @advice}.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should require the values for :reading => ... and :changing => ... to be equal if both are specified." do
      @advice = Proc.new {}
      lambda {Aspect.new :before, :type => Aquarium::AspectInvocationTestClass3, 
        :reading => :public_test_method_args, :changing => :public_test_method_args2, :advice => @advice}.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should accept :reading => ... as a synonym for :attributes => ..., :attribute_options => [:readers]." do
      @advice = Proc.new {}
      @expected_methods = [:public_test_method_args]
      aspect1 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :reading    => :public_test_method_args, :advice => @advice
      aspect2 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :attributes => :public_test_method_args, :attribute_options => [:readers], :advice => @advice
      aspects_should_be_equal 1, aspect1, aspect2
      aspect1.unadvise
      aspect2.unadvise
    end

    it "should accept :writing => ... as a synonym for :attributes => ..., :attribute_options => [:writer]." do
      @advice = Proc.new {}
      @expected_methods = [:public_test_method_args=]
      aspect1 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :writing    => :public_test_method_args, :advice => @advice
      aspect2 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :attributes => :public_test_method_args, :attribute_options => [:writers], :advice => @advice
      aspects_should_be_equal 1, aspect1, aspect2
      aspect1.unadvise
      aspect2.unadvise
    end

    it "should accept :changing => ... as a synonym for :attributes => ..., :attribute_options => [:writer]." do
      @advice = Proc.new {}
      @expected_methods = [:public_test_method_args=]
      aspect1 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :changing   => :public_test_method_args, :advice => @advice
      aspect2 = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :attributes => :public_test_method_args, :attribute_options => [:writers], :advice => @advice
      aspects_should_be_equal 1, aspect1, aspect2
      aspect1.unadvise
      aspect2.unadvise
    end
  end

  describe Aspect, ".new (with a :type(s) parameter and a :method(s) parameter)" do  
    before :each do
      @protection = 'public'
      @are_class_methods = false
      @types_option = :types
      @method_options = []
    end
  
    def do_type_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, @types_option => @type_spec, :methods => @method_spec, :method_options => @method_options do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      if @are_class_methods
        Aquarium::AspectInvocationTestClass.method("#{@protection}_class_test_method").call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      else
        Aquarium::AspectInvocationTestClass.new.method("#{@protection}_test_method").call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      end
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept :type(s) => T1, :methods => m" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = :public_test_method
      do_type_spec
    end

    it "should accept :type(s) => T1, :methods => [m, ...]" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s) => T1, :methods => /m/" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = /test_method/
      do_type_spec
    end

    it "should accept :type(s) => [T1, ...], :methods => m" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = :public_test_method
      do_type_spec
    end

    it "should accept :type(s) => [T1, ...], :methods => [m, ...]" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s) => [T1, ...], :methods => /m/" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = /test_method/
      do_type_spec
    end

    it "should accept :type(s) => /T1/, :methods => m" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = :public_test_method
      do_type_spec
    end

    it "should accept :type(s) => /T1/, :methods => [m, ...]" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s) => /T1/, :methods => /m/" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = /test_method/
      do_type_spec
    end

    it "should accept :type(s)_and_ancestors => T1, :methods => [m, ...]" do  
      @types_option = :types_and_ancestors
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_ancestors => [T1, ...], :methods => [m, ...]" do  
      @types_option = :types_and_ancestors
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_ancestors => /T1/, :methods => [m, ...]" do  
      @types_option = :types_and_ancestors
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_descendents => T1, :methods => [m, ...]" do  
      @types_option = :types_and_descendents
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_descendents => [T1, ...], :methods => [m, ...]" do  
      @types_option = :types_and_descendents
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_descendents => /T1/, :methods => [m, ...]" do  
      @types_option = :types_and_descendents
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_nested_types => T1, :methods => [m, ...]" do  
      @types_option = :types_and_nested_types
      @type_spec = Aquarium::AspectInvocationTestClass
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_nested_types => [T1, ...], :methods => [m, ...]" do  
      @types_option = :types_and_nested_types
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s)_and_nested_types => /T1/, :methods => [m, ...]" do  
      @types_option = :types_and_nested_types
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = [:public_test_method]
      do_type_spec
    end

    it "should accept :type(s) => ..., :methods => ..., :method_options => [:exclude_ancestor_methods] to exclude methods defined in ancestors" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = /test_method/
      @method_options = [:exclude_ancestor_methods]
      do_type_spec
    end

    it "should accept :type(s) => ..., :methods => ..., :method_options => [:instance, :public] to match only instance and public (both are the defaults) methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = /test_method/
      @method_options = [:instance, :public]
      do_type_spec
    end

    %w[public protected private].each do |protection|
      it "should accept :type(s) => ..., :methods => ..., :method_options => [#{protection.intern}] to match only instance (default) #{protection} methods" do  
        @type_spec = /Aquarium::AspectInvocationTestClass/
        @method_spec = /test_method/
        @method_options = [protection.intern]
        @protection = protection
        do_type_spec
      end
    end

    it "should accept :type(s) => ..., :methods => ..., :method_options => [:class] to match only public (default) class methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @method_spec = /test_method/
      @method_options = [:class]
      @are_class_methods = true
      do_type_spec
    end

    %w[public private].each do |protection|
      it "should accept :type(s) => ..., :methods => ..., :method_options => [:class, :#{protection.intern}] to match only class #{protection} methods" do  
        @type_spec = /Aquarium::AspectInvocationTestClass/
        @method_spec = /test_method/
        @method_options = [:class, protection.intern]
        @protection = protection
        @are_class_methods = true
        do_type_spec
      end
    end
  end


  describe Aspect, ".new (with a :type(s) parameter and a :attribute(s) parameter)" do  
    before :each do
      @protection = 'public'
      @attribute_options = []
      @are_class_methods = false
    end
  
    def do_type_attribute_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types => @type_spec, :attributes => @attribute_spec, :attribute_options => @attribute_options do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        expected_args = make_array(@expected_args)
        args.should == expected_args
        args.size.should == expected_args.size
      end 
      object = Aquarium::AspectInvocationTestClass.new
      @expected_args = nil
      object.method("#{@protection}_test_method_args".intern).call 
      @expected_args = :a1
      object.method("#{@protection}_test_method_args=".intern).call @expected_args
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept :type(s) => [T1, ...], :attribute(s) => [a, ...]" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @attribute_spec = [:public_test_method_args]
      do_type_attribute_spec
    end

    it "should accept :type(s) => [T1, ...], :attribute(s) => a" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @attribute_spec = :public_test_method_args
      do_type_attribute_spec
    end

    it "should accept :type(s) => [T1, ...], :attribute(s) => /a/" do  
      @type_spec = [Aquarium::AspectInvocationTestClass]
      @attribute_spec = /test_method_args/
      do_type_attribute_spec
    end

    it "should accept :type(s) => T1, :attribute(s) => [a]" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @attribute_spec = [:public_test_method_args]
      do_type_attribute_spec
    end

    it "should accept :type(s) => T1, :attribute(s) => a" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @attribute_spec = :public_test_method_args
      do_type_attribute_spec
    end

    it "should accept :type(s) => T1, :attribute(s) => /a/" do  
      @type_spec = Aquarium::AspectInvocationTestClass
      @attribute_spec = /test_method_args/
      do_type_attribute_spec
    end

    it "should accept :type(s) => /T1/, :attribute(s) => [a, ...]" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = [:public_test_method_args]
      do_type_attribute_spec
    end

    it "should accept :type(s) => /T1/, :attribute(s) => a" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = :public_test_method_args
      do_type_attribute_spec
    end

    it "should accept :type(s) => /T1/, :attribute(s) => a" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:readers, :writers] to include both attribute reader and writer methods (default)" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:readers, :writers]
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:readers] to include only attribute reader methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:readers]
      do_type_attribute_spec
    end

    it "should accept attribute option :reader as a synonym for :readers" do
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:reader]
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:writers] to include only attribute writer methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:writers]
      do_type_attribute_spec
    end

    it "should accept attribute option :writer as a synonym for :writers" do
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:writer]
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :readers, :writers] to include both attribute reader and writer methods (default) for class methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:class, :readers, :writers]
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :readers] to include only attribute reader class methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:class, :readers]
      do_type_attribute_spec
    end

    it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :writers] to include only attribute writer class methods" do  
      @type_spec = /Aquarium::AspectInvocationTestClass/
      @attribute_spec = /test_method_args/
      @attribute_options = [:class, :writers]
      do_type_attribute_spec
    end
  end

  describe Aspect, ".new (with a :object(s) parameter and a :method(s) parameter)" do  
    before :each do
      @object1 = Aquarium::AspectInvocationTestClass.new
      @object2 = Aquarium::AspectInvocationTestClass.new
      @protection = 'public'
      @method_options = []
    end
  
    def do_object_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :objects => @object_spec, :methods => @method_spec, :method_options => @method_options do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      make_array(@object_spec).each do |object|
        object.method("#{@protection}_test_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      end
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept :object(s) => [o1, ...], :methods => [m, ...]" do  
      @object_spec = [@object1, @object2]
      @method_spec = [:public_test_method]
      do_object_spec
    end

    it "should accept :object(s) => [o1, ...], :methods => m" do  
      @object_spec = [@object1, @object2]
      @method_spec = :public_test_method
      do_object_spec
    end

    it "should accept :object(s) => [o1, ...], :methods => /m/" do  
      @object_spec = [@object1, @object2]
      @method_spec = /test_method/
      do_object_spec
    end

    it "should accept :object(s) => o1, :methods => [m, ...]" do  
      @object_spec = @object1
      @method_spec = [:public_test_method]
      do_object_spec
    end

    it "should accept :object(s) => o1, :methods => m" do  
      @object_spec = @object1
      @method_spec = :public_test_method
      do_object_spec
    end

    it "should accept :object(s) => o1, :methods => /m/" do  
      @object_spec = @object1
      @method_spec = /test_method/
      do_object_spec
    end

    it "should accept :object(s) => ..., :methods => ..., :method_options => [:exclude_ancestor_methods] to exclude methods defined in ancestors" do  
      @object_spec = @object1
      @method_spec = /test_method/
      @method_options = [:exclude_ancestor_methods]
      do_object_spec
    end

    it "should accept :object(s) => ..., :methods => ..., :method_options => [:instance, :public] to match only instance and public (both are the defaults) methods" do  
      @object_spec = @object1
      @method_spec = /test_method/
      @method_options = [:instance, :public]
      do_object_spec
    end

    %w[public protected private].each do |protection|
      it "should accept :object(s) => ..., :methods => ..., :method_options => [#{protection.intern}] to match only instance (default) #{protection} methods" do  
        @object_spec = @object1
        @method_spec = /test_method/
        @method_options = [protection.intern]
        @protection = protection
        do_object_spec
      end

      it "should accept :object(s) => ..., :methods => ..., :method_options => [:instance, #{protection.intern}] to match only instance #{protection} methods" do  
        @object_spec = @object1
        @method_spec = /test_method/
        @method_options = [:instance, protection.intern]
        @protection = protection
        do_object_spec
      end
    end
  end

  describe Aspect, ".new (with a :object(s) parameter and a :attribute(s) parameter)" do  
    before :each do
      @object1 = Aquarium::AspectInvocationTestClass.new
      @object2 = Aquarium::AspectInvocationTestClass.new
      @protection = 'public'
      @attribute_options = []
    end
  
    def do_object_attribute_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :objects => @object_spec, :attributes => @attribute_spec, :attribute_options => @attribute_options do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        expected_args = make_array(@expected_args)
        args.should == expected_args
        args.size.should == expected_args.size
      end 
      make_array(@object_spec).each do |object|
        @expected_args = nil
        object.method("#{@protection}_test_method_args".intern).call 
        @expected_args = :a1
        object.method("#{@protection}_test_method_args=".intern).call @expected_args
        advice_called.should be_true
      end
      aspect.unadvise
    end

    it "should accept :object(s) => [T1, ...], :attribute(s) => [a, ...]" do  
      @object_spec = [@object1, @object2]
      @attribute_spec = [:public_test_method_args]
      do_object_attribute_spec
    end

    it "should accept :object(s) => [T1, ...], :attribute(s) => a" do  
      @object_spec = [@object1, @object2]
      @attribute_spec = :public_test_method_args
      do_object_attribute_spec
    end

    it "should accept :object(s) => [T1, ...], :attribute(s) => /a/" do  
      @object_spec = [@object1, @object2]
      @attribute_spec = /test_method_args/
      do_object_attribute_spec
    end

    it "should accept :object(s) => T1, :attribute(s) => [a]" do  
      @object_spec = @object1
      @attribute_spec = [:public_test_method_args]
      do_object_attribute_spec
    end

    it "should accept :object(s) => T1, :attribute(s) => a" do  
      @object_spec = @object1
      @attribute_spec = :public_test_method_args
      do_object_attribute_spec
    end

    it "should accept :object(s) => T1, :attribute(s) => /a/" do  
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      do_object_attribute_spec
    end

    it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:readers, :writers] to include both attribute reader and writer methods (default)" do  
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      @attribute_options = [:readers, :writers]
      do_object_attribute_spec
    end

    it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:readers] to include only attribute reader methods" do  
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      @attribute_options = [:readers]
      do_object_attribute_spec
    end

    it "should accept attribute option :reader as a synonym for :readers" do
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      @attribute_options = [:reader]
      do_object_attribute_spec
    end

    it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:writers] to include only attribute writer methods" do  
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      @attribute_options = [:writers]
      do_object_attribute_spec
    end

    it "should accept attribute option :writer as a synonym for :writers" do
      @object_spec = @object1
      @attribute_spec = /test_method_args/
      @attribute_options = [:writer]
      do_object_attribute_spec
    end
  end

  describe Aspect, ".new (with a :pointcut parameter taking a hash with type specifications)" do  
    before :each do
      @protection = 'public'
      @are_class_methods = false
    end
  
    def do_type_pointcut_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcut => @pointcut_hash do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      if @are_class_methods
        Aquarium::AspectInvocationTestClass.method("#{@protection}_class_test_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      else
        Aquarium::AspectInvocationTestClass.new.method("#{@protection}_test_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      end
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept {:type(s) => [T1, ...], :methods => [m, ...]} " do  
      @pointcut_hash = {:type => [Aquarium::AspectInvocationTestClass], :methods => [:public_test_method]}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => [T1, ...], :methods => m} " do  
      @pointcut_hash = {:type => [Aquarium::AspectInvocationTestClass], :methods => :public_test_method}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => [T1, ...], :methods => /m/} " do  
      @pointcut_hash = {:type => [Aquarium::AspectInvocationTestClass], :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_ancestors => [T1, ...], :methods => /m/} " do  
      @pointcut_hash = {:type_and_ancestors => [Aquarium::AspectInvocationTestClass], :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_descendents => [T1, ...], :methods => /m/} " do  
      @pointcut_hash = {:type_and_descendents => [Aquarium::AspectInvocationTestClass], :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_nested_types => [T1, ...], :methods => /m/} " do  
      @pointcut_hash = {:type_and_nested_types => [Aquarium::AspectInvocationTestClass], :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => T1, :methods => [m, ...]} " do  
      @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => [:public_test_method]}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => T1, :methods => m} " do  
      @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => T1, :methods => /m/} " do  
      @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_ancestors => T1, :methods => /m/} " do  
      @pointcut_hash = {:type_and_ancestors => Aquarium::AspectInvocationTestClass, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_descendents => T1, :methods => /m/} " do  
      @pointcut_hash = {:type_and_descendents => Aquarium::AspectInvocationTestClass, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_nested_types => T1, :methods => /m/} " do  
      @pointcut_hash = {:type_and_nested_types => Aquarium::AspectInvocationTestClass, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => /T1/, :methods => [m, ...]} " do  
      @pointcut_hash = {:type => /Aquarium::AspectInvocationTestClass/, :methods => [:public_test_method]}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => /T1/, :methods => m} " do  
      @pointcut_hash = {:type => /Aquarium::AspectInvocationTestClass/, :methods => :public_test_method}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => /T1/, :methods => /m/} " do  
      @pointcut_hash = {:type => /Aquarium::AspectInvocationTestClass/, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_ancestors => /T1/, :methods => /m/} " do  
      @pointcut_hash = {:type_and_ancestors => /Aquarium::AspectInvocationTestClass/, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_descendents => /T1/, :methods => /m/} " do  
      @pointcut_hash = {:type_and_descendents => /Aquarium::AspectInvocationTestClass/, :methods => /test_method/}
      do_type_pointcut_spec
    end

    it "should accept {:type(s)_and_nested_types => /T1/, :methods => /m/} " do  
      @pointcut_hash = {:type_and_nested_types => /Aquarium::AspectInvocationTestClass/, :methods => /test_method/}
      do_type_pointcut_spec
    end

    %w[public protected private].each do |protection|
      it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:instance, #{protection}]} " do  
        @protection = protection
        @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => /test_method/, :method_options =>[:instance, protection.intern]}
        do_type_pointcut_spec
      end
    end

    %w[public private].each do |protection|
      it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:class, #{protection}]} " do  
        @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => /class_test_method/, :method_options =>[:class, protection.intern]}
        @protection = protection
        @are_class_methods = true
        do_type_pointcut_spec
      end
    end

    it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:instance]} defaults to public methods" do  
      @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => /test_method/, :method_options =>[:instance]}
      do_type_pointcut_spec
    end

    it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:class]} defaults to public class methods" do  
      @pointcut_hash = {:type => Aquarium::AspectInvocationTestClass, :methods => /test_method/, :method_options =>[:class]}
      @are_class_methods = true
      do_type_pointcut_spec
    end
  end

  describe Aspect, ".new (with a :pointcut parameter taking a hash with object specifications)" do  
    before :each do
      @protection = 'public'
      @expected_advice_count = 2
      @object1 = Aquarium::AspectInvocationTestClass.new
      @object2 = Aquarium::AspectInvocationTestClass.new
    end
  
    def do_object_pointcut_spec
      aspect = nil
      advice_count = 0
      aspect = Aspect.new :before, :pointcut => @pointcut_hash do |jp, obj, *args|
        advice_count += 1
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      @object1.method("#{@protection}_test_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      @object2.method("#{@protection}_test_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_count.should == @expected_advice_count
      aspect.unadvise
    end

    it "should accept {:objects => [o1, ...], :methods => [m, ...]} " do  
      @pointcut_hash = {:objects => [@object1, @object2], :methods => [:public_test_method]}
      do_object_pointcut_spec
    end

    it "should accept {:objects => [o1, ...], :methods => m} " do  
      @pointcut_hash = {:objects => [@object1, @object2], :methods => :public_test_method}
      do_object_pointcut_spec
    end

    it "should accept {:objects => [o1, ...], :methods => /m/} " do  
      @pointcut_hash = {:objects => [@object1, @object2], :methods => /test_method/}
      do_object_pointcut_spec
    end

    it "should accept {:object => o1, :methods => [m, ...]} " do  
      @expected_advice_count = 1
      @pointcut_hash = {:object => @object1, :methods => [:public_test_method]}
      do_object_pointcut_spec
    end

    it "should accept {:objects => o1, :methods => m} " do  
      @expected_advice_count = 1
      @pointcut_hash = {:objects => @object1, :methods => :public_test_method}
      do_object_pointcut_spec
    end

    it "should accept {:objects => o1, :methods => /m/} " do  
      @expected_advice_count = 1
      @pointcut_hash = {:objects => @object1, :methods => /test_method/}
      do_object_pointcut_spec
    end
  end

  describe Aspect, ".new (with a :pointcut parameter and a Pointcut object or an array of Pointcuts)" do  
    def do_pointcut_pointcut_spec
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcut => @pointcuts do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      Aquarium::AspectInvocationTestClass.new.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept a single Pointcut object." do
      @pointcuts = Pointcut.new :type => [Aquarium::AspectInvocationTestClass], :methods => :public_test_method
      do_pointcut_pointcut_spec
    end
  
    it "should accept an array of Pointcut objects." do
      pointcut1 = Pointcut.new :type => [Aquarium::AspectInvocationTestClass], :methods => :public_test_method
      pointcut2 = Pointcut.new :type => [Aquarium::AspectInvocationTestClass], :methods => :public_class_test_method, :method_options => [:class]
      @pointcuts = [pointcut1, pointcut2]
      do_pointcut_pointcut_spec
    end
  end

  describe Aspect, ".new (with a :pointcut parameter and an array of Pointcuts)" do  
    it "should treat the array as if it is one Pointcut \"or'ed\" together." do
      advice_called = 0
      advice = Proc.new {|jp, obj, *args|
        advice_called += 1
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      }
      pointcut1 = Pointcut.new :type => [Aquarium::AspectInvocationTestClass], :methods => :public_test_method
      pointcut2 = Pointcut.new :type => [Aquarium::AspectInvocationTestClass], :methods => :public_class_test_method, :method_options => [:class]
      pointcut12 = pointcut1.or pointcut2
      aspect1 = Aspect.new :before, :pointcut => [pointcut1, pointcut2], :advice => advice
      Aquarium::AspectInvocationTestClass.new.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      Aquarium::AspectInvocationTestClass.public_class_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should == 2
      aspect1.unadvise
      advice_called = 0
      aspect2 = Aspect.new :before, :pointcut => pointcut12, :advice => advice
      Aquarium::AspectInvocationTestClass.new.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      Aquarium::AspectInvocationTestClass.public_class_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should == 2
      aspect2.unadvise
      aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    end
  end

  describe Aspect, ".new (with a :type(s) parameter and a :method(s) parameter or one of several equivalent :pointcut parameters)" do
    before :each do
      @advice = proc {|jp, obj, *args| "advice"}
      @expected_methods = [:public_test_method]
    end
    after :each do
      @aspect1.unadvise
      @aspect2.unadvise
    end
  
    it "should advise equivalent join points when :type => T and :method => m is used or :pointcut =>{:type => T, :method => m} is used." do
      @aspect1 = Aspect.new :after, :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
      @aspect1 = Aspect.new :after, :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end
  
    it "should advise equivalent join points when :pointcut =>{:type => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
      @aspect1 = Aspect.new :after, :pointcut => {:type => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise an equivalent join point when :type => T and :method => m is used or :pointcut => join_point is used, where join_point matches :type => T and :method => m." do
      @aspect1 = Aspect.new :after, :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      join_point = Aquarium::Aspects::JoinPoint.new :type => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
      join_points_should_be_equal 1, @aspect1, @aspect2
    end
  
    it "should advise equivalent join points when :type_and_ancestors => T and :method => m is used or :pointcut =>{:type_and_ancestors => T, :method => m} is used." do
      @aspect1 = Aspect.new :after, :type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type_and_ancestors => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type_and_ancestors => T and :method => m." do
      @aspect1 = Aspect.new :after, :type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end
  
    it "should advise equivalent join points when :pointcut =>{:type_and_ancestors => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type_and_ancestors => T and :method => m." do
      @aspect1 = Aspect.new :after, :pointcut => {:type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_ancestors => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type_and_descendents => T and :method => m is used or :pointcut =>{:type_and_descendents => T, :method => m} is used." do
      @aspect1 = Aspect.new :after, :type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type_and_descendents => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type_and_descendents => T and :method => m." do
      @aspect1 = Aspect.new :after, :type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end
  
    it "should advise equivalent join points when :pointcut =>{:type_and_descendents => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type_and_descendents => T and :method => m." do
      @aspect1 = Aspect.new :after, :pointcut => {:type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_descendents => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type_and_nested_types => T and :method => m is used or :pointcut =>{:type_and_nested_types => T, :method => m} is used." do
      @aspect1 = Aspect.new :after, :type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type_and_nested_types => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type_and_nested_types => T and :method => m." do
      @aspect1 = Aspect.new :after, :type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end
  
    it "should advise equivalent join points when :pointcut =>{:type_and_nested_types => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type_and_nested_types => T and :method => m." do
      @aspect1 = Aspect.new :after, :pointcut => {:type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type_and_nested_types => Aquarium::AspectInvocationTestClass, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

  end

  describe Aspect, ".new (with a :type(s) parameter and an :attributes(s) parameter or one of several equivalent :pointcut parameters)" do
    class ClassWithAttrib1
      def dummy; end
      attr_accessor :state
    end
  
    before :each do
      @advice = proc {|jp, obj, *args| "advice"}
      @expected_methods = [:state, :state=]
    end
    after :each do
      @aspect1.unadvise
      @aspect2.unadvise
    end
  
    it "should not advise any method join points except those corresponding to attribute methods." do
      @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type => ClassWithAttrib1, :attribute => :state}, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a is used or :pointcut =>{:type => T, :attribute => a} is used." do
      @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:type => ClassWithAttrib1, :attribute => :state}, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a is used or :pointcut => pointcut is used, where pointcut matches :type => T and :attribute => a." do
      @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type => ClassWithAttrib1, :attribute => :state
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :pointcut =>{:type => T, :attribute => a} is used or :pointcut => pointcut is used, where pointcut matches :type => T and :attribute => a." do
      @aspect1 = Aspect.new :after, :pointcut => {:type => ClassWithAttrib1, :attribute => :state}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :type => ClassWithAttrib1, :attribute => :state
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a (the attribute's reader and writer) is used or :pointcut => [join_points] is used, where the join_points match :type => T and :method => :a and :method => :a=." do
      @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, &@advice
      join_point1 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state
      join_point2 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state=
      @aspect2 = Aspect.new :after, :pointcut => Pointcut.new(:join_points => [join_point1, join_point2]), &@advice
      join_points_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise an equivalent join point when :type => T and :method => :a= (the attribute's writer) is used or :pointcut => join_point is used, where join_point matches :type => T and :method => a=." do
      @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, :attribute_options => [:writer], &@advice
      join_point = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state=
      @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
      join_points_should_be_equal 1, @aspect1, @aspect2
    end
  end

  describe Aspect, ".new (with a :object(s) parameter and a :method(s) parameter or one of several equivalent :pointcut parameters)" do
    before :each do
      @advice = proc {|jp, obj, *args| "advice"}
      @expected_methods = [:public_test_method]
    end
    after :each do
      @aspect1.unadvise
      @aspect2.unadvise
    end

    it "should advise equivalent join points when :object => o and :method => m is used or :pointcut =>{:object => o, :method => m} is used." do
      object = Aquarium::AspectInvocationTestClass.new
      @aspect1 = Aspect.new :after, :object => object, :method => :public_test_method, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:object => object, :method => :public_test_method}, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :object => o and :method => m is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
      object = Aquarium::AspectInvocationTestClass.new
      @aspect1 = Aspect.new :after, :object => object, :method => :public_test_method, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :object => object, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :pointcut =>{:object => o, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
      object = Aquarium::AspectInvocationTestClass.new
      @aspect1 = Aspect.new :after, :pointcut => {:object => object, :method => :public_test_method}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :object => object, :method => :public_test_method
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 1, @aspect1, @aspect2
    end
  end

  describe Aspect, ".new (with a :object(s) parameter and an :attributes(s) parameter or one of several equivalent :pointcut parameters)" do
    class ClassWithAttrib2
      def initialize *args
        @state = args
      end
      def dummy; end
      attr_accessor :state
    end
  
    before :each do
      @advice = proc {|jp, obj, *args| "advice"}
      @object = ClassWithAttrib2.new
      @expected_methods = [:state, :state=]
    end
    after :each do
      @aspect1.unadvise
      @aspect2.unadvise
    end
  
    it "should not advise any method join points except those corresponding to attribute methods." do
      @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:object => @object, :attribute => :state}, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a is used or :pointcut =>{:type => T, :attribute => a} is used." do
      @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, &@advice
      @aspect2 = Aspect.new :after, :pointcut => {:object => @object, :attribute => :state}, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a is used or :pointcut => pointcut is used, where pointcut matches :type => T and :attribute => a." do
      @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :object => @object, :attribute => :state
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :pointcut =>{:type => T, :attribute => a} is used or :pointcut => pointcut is used, where pointcut matches :type => T and :attribute => a." do
      @aspect1 = Aspect.new :after, :pointcut => {:object => @object, :attribute => :state}, &@advice
      pointcut = Aquarium::Aspects::Pointcut.new :object => @object, :attribute => :state
      @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
      aspects_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise equivalent join points when :type => T and :attribute => a (the attribute's reader and writer) is used or :pointcut => [join_points] is used, where the join_points match :type => T and :method => :a and :method => :a=." do
      @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, &@advice
      join_point1 = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state
      join_point2 = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state=
      @aspect2 = Aspect.new :after, :pointcut => Pointcut.new(:join_points => [join_point1, join_point2]), &@advice
      join_points_should_be_equal 2, @aspect1, @aspect2
    end

    it "should advise an equivalent join point when :type => T and :method => :a= (the attribute's writer) is used or :pointcut => join_point is used, where join_point matches :type => T and :method => a=." do
      @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, :attribute_options => [:writer], &@advice
      join_point = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state=
      @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
      join_points_should_be_equal 1, @aspect1, @aspect2
    end
  end

  describe Aspect, ".new (block for advice)" do  
    it "should accept a block as the advice to use." do
      object = Aquarium::AspectInvocationTestClass.new
      advice_called = false
      aspect = Aspect.new :before, :object => object, :methods => :public_test_method do |jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      object.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end

    it "should accept an :advice => Proc parameter indicating the advice to use." do
      object = Aquarium::AspectInvocationTestClass.new
      advice_called = false
      advice = Proc.new {|jp, obj, *args|
        advice_called = true
        jp.should_not be_nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      }
      aspect = Aspect.new :before, :object => object, :methods => :public_test_method, :advice => advice
      object.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end
  
    Aspect::CANONICAL_OPTIONS["advice"].each do |key|
      it "should accept :#{key} => proc as a synonym for :advice." do
        object = Aquarium::AspectInvocationTestClass.new
        advice_called = false
        advice = Proc.new {|jp, obj, *args|
          advice_called = true
          jp.should_not be_nil
          args.size.should == 4
          args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
        }
        aspect = Aspect.new :before, :object => object, :methods => :public_test_method, key.intern => advice
        object.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
        advice_called.should be_true
        aspect.unadvise
      end
    end
  
    it "should allow only one :advice object to be specified (including synonyms)." do
      object = Aquarium::AspectInvocationTestClass.new
      advice_called = false
      advice1 = Proc.new {|jp, obj, *args| fail "advice1"}
      advice2 = Proc.new {|jp, obj, *args| fail "advice2"}
      lambda {Aspect.new :before, :object => object, :methods => :public_test_method, :advice => advice1, :invoke => advice2}.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should allow ignore an :advice option if a block is given." do
      object = Aquarium::AspectInvocationTestClass.new
      advice_called = false
      advice1 = Proc.new {|jp, obj, *args| fail "advice1"}
      advice2 = Proc.new {|jp, obj, *args| fail "advice2"}
      aspect = Aspect.new :before, :object => object, :methods => :public_test_method, :advice => advice1 do |jp, obj, *args|
        advice_called = true
      end
      object.public_test_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end
  end

  describe Aspect, ".new (advice block or proc parameter list)" do  
    it "should raise unless an advice block or :advice => advice parameter is specified." do
      lambda { Aspect.new(:after, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method)}.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should raise if obsolete |jp, *args| list is used." do
      lambda { Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method do |jp, *args|; end }.should raise_error(Aquarium::Utils::InvalidOptions)
    end

    it "should accept an argument list matching |jp, object, *args|." do
      aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method, :noop => true do |jp, object, *args|; end
      aspect.unadvise
    end

    it "should accept an argument list matching |jp, object|." do
      aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method, :noop => true do |jp, object|; end
      aspect.unadvise
    end

    it "should accept an argument list matching |jp|." do
      aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method, :noop => true do |jp|; end
      aspect.unadvise
    end

    it "should accept an argument list matching ||." do
      aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method, :noop => true do ||; end
      aspect.unadvise
    end

    it "should accept no argument list." do
      aspect = Aspect.new :before, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method, :noop => true do; end
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (advice block to around advice with just the join_point parameter - Bug #19262)" do  
    it "should not raise an error" do
      aspect = Aspect.new :around, :type => Aquarium::AspectInvocationTestClass, :methods => :public_test_method do |jp|; jp.proceed; end
      Aquarium::AspectInvocationTestClass.new.public_test_method
      aspect.unadvise
    end
  end

  class ExcludeBase
    def doit; end
    def initialize arg; @value = arg; end
    attr_accessor :value
    def inspect; "(#{self.class}: #{@value})"; end
    def eql? other
      return false unless other.kind_of?(self.class)
      @value == other.value
    end
    alias_method :==, :eql?
  end
  class DontExclude1 < ExcludeBase; end
  class DontExclude2 < ExcludeBase; end
  class Exclude1 < ExcludeBase; end
  class Exclude2 < ExcludeBase; end

  class Exclude1b < Exclude1
    def initialize arg; super(arg); end
    def doit2; end
  end  
  class Exclude1c < Exclude1
    def initialize arg; super(arg); end
    def doit3; end
  end  

  describe Aspect, ".new (with a :type(s) parameter and an :exclude_type(s), and :exclude_type(s)_and_ancestors, an :exclude_type(s)_and_descendents, or an :exclude_type(s)_and_nested_types parameter)" do  
    before :all do
      @included_types = [DontExclude1, DontExclude2]
      @excluded_types = [Exclude1, Exclude2]
      @all_types = @included_types + @excluded_types
    end
    
    def do_exclude_types exclude_type_sym
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types => @all_types, exclude_type_sym => @excluded_types, :methods => :doit do |jp, obj, *args|
        advice_called = true
        @excluded_types.should_not include(jp.target_type)
      end 
      @included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      @excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  
    it "should accept :type(s) => [T1, ...], :exclude_types => [T2, ...] and exclude join points in the excluded types" do  
      do_exclude_types :exclude_types
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_types"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types." do
        aspect = Aspect.new :before, :types => @all_types, key.intern => @excluded_types, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end

    it "should accept :type(s) => [T1, ...], :exclude_types_and_ancestors => [T2, ...] and exclude join points in the excluded types" do  
      do_exclude_types :exclude_types_and_ancestors
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_types_and_ancestors"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_ancestors." do
        aspect = Aspect.new :before, :types => @all_types, key.intern => @excluded_types, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end

    it "should accept :type(s) => [T1, ...], :exclude_types_and_descendents => [T2, ...] and exclude join points in the excluded types" do  
      do_exclude_types :exclude_types_and_descendents
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_types_and_descendents"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_descendents." do
        aspect = Aspect.new :before, :types => @all_types, key.intern => @excluded_types, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end

    it "should accept :type(s) => [T1, ...], :exclude_types_and_nested_types => [T2, ...] and exclude join points in the excluded types" do  
      do_exclude_types :exclude_types_and_nested_types
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_types_and_nested_types"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_nested_types." do
        aspect = Aspect.new :before, :types => @all_types, key.intern => @excluded_types, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end

  end


  describe Aspect, ".new (with a :object(s) parameter and an :exclude_object(s) parameter)" do  
    before :all do
      dontExclude1 = DontExclude1.new(1)
      dontExclude2 = DontExclude1.new(2)
      exclude1 = DontExclude1.new(3)
      exclude2 = DontExclude1.new(4)
      @included_objects = [dontExclude1, dontExclude2]
      @excluded_objects = [exclude1, exclude2]
      @all_objects = @included_objects + @excluded_objects
    end
    
    it "should accept :object(s) => [o1, ...], :exclude_object(s) => [o2, ...] and exclude join points in the excluded objects" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :objects => @all_objects, :exclude_objects => @excluded_objects, :methods => :doit do |jp, obj, *args|
        advice_called = true
        @excluded_objects.should_not include(obj)
      end 
      @included_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should be_true
      end
      @excluded_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_objects"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_objects." do
        aspect = Aspect.new :before, :objects => @all_objects, key.intern => @excluded_objects, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end
  end


  describe Aspect, ".new (with an :object(s) and an :exclude_join_point(s) parameter)" do  
    before :all do
      dontExclude1 = DontExclude1.new(1)
      dontExclude2 = DontExclude1.new(2)
      exclude1 = DontExclude1.new(3)
      exclude2 = DontExclude1.new(4)
      @included_objects = [dontExclude1, dontExclude2]
      @excluded_objects = [exclude1, exclude2]
      @all_objects = @included_objects + @excluded_objects
      excluded_join_point1 = JoinPoint.new :object => exclude1, :method => :doit
      excluded_join_point2 = JoinPoint.new :object => exclude2, :method => :doit
      @excluded_join_points = [excluded_join_point1, excluded_join_point2]
    end
    
    it "should accept :type(s) => [T1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :objects => @all_objects, :exclude_join_points => @excluded_join_points, :methods => :doit do |jp, obj, *args|
        advice_called = true
        @excluded_objects.should_not include(obj)
      end 

      @included_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should be_true
      end
      @excluded_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_join_points"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_join_points." do
        aspect = Aspect.new :before, :objects => @all_objects, key.intern => @excluded_join_points, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end
  end  

  describe Aspect, ".new (with a :type(s) parameter and an :exclude_join_point(s) parameter)" do  
    it "should accept :type(s) => [T1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      included_types = [DontExclude1, DontExclude2]
      excluded_types = [Exclude1, Exclude2]
      excluded_join_point1 = JoinPoint.new :type => Exclude1, :method => :doit
      excluded_join_point2 = JoinPoint.new :type => Exclude2, :method => :doit
      excluded_join_points = [excluded_join_point1, excluded_join_point2]
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types => (included_types + excluded_types), :exclude_join_points => excluded_join_points, :methods => :doit do |jp, obj, *args|
        advice_called = true
        excluded_types.should_not include(jp.target_type)
      end 

      included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (with a :type(s)_and_ancestors parameter and an :exclude_join_point(s) parameter)" do  
    it "should accept :type(s)_and_ancestors => [T1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      included_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      excluded_join_point1 = JoinPoint.new :type => ClassWithPublicInstanceMethod, :method => :public_instance_test_method
      excluded_join_point2 = JoinPoint.new :type => ModuleWithPublicInstanceMethod, :method => :public_instance_module_test_method
      excluded_join_points = [excluded_join_point1, excluded_join_point2]
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types_and_ancestors => included_types, :methods => :doit, 
        :exclude_join_points => excluded_join_points, :ignore_no_matching_join_points => true do |jp, obj, *args|; advice_called = true; end 

      advice_called = false
      ClassWithPublicInstanceMethod.new.public_instance_test_method
      advice_called.should be_false
      advice_called = false
      ClassIncludingModuleWithPublicInstanceMethod.new.public_instance_module_test_method
      advice_called.should be_false
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (with a :type(s)_and_descendents parameter and an :exclude_join_point(s) parameter)" do  
    it "should accept :type(s)_and_descendents => [T1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      included_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      excluded_join_point1 = JoinPoint.new :type => ClassWithPublicInstanceMethod, :method => :public_instance_test_method
      excluded_join_point2 = JoinPoint.new :type => ModuleWithPublicInstanceMethod, :method => :public_instance_module_test_method
      excluded_join_points = [excluded_join_point1, excluded_join_point2]
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types_and_descendents => included_types, :methods => :doit, 
        :exclude_join_points => excluded_join_points, :ignore_no_matching_join_points => true do |jp, obj, *args|; advice_called = true; end

      advice_called = false
      ClassWithPublicInstanceMethod.new.public_instance_test_method
      advice_called.should be_false
      advice_called = false
      ClassIncludingModuleWithPublicInstanceMethod.new.public_instance_module_test_method
      advice_called.should be_false
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (with a :type(s)_and_nested_types parameter and an :exclude_join_point(s) parameter)" do  
    it "should accept :type(s)_and_nested_types => [T1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      included_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      excluded_join_point1 = JoinPoint.new :type => ClassWithPublicInstanceMethod, :method => :public_instance_test_method
      excluded_join_point2 = JoinPoint.new :type => ModuleWithPublicInstanceMethod, :method => :public_instance_module_test_method
      excluded_join_points = [excluded_join_point1, excluded_join_point2]
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types_and_nested_types => included_types, :methods => :doit, 
        :exclude_join_points => excluded_join_points, :ignore_no_matching_join_points => true do |jp, obj, *args|; advice_called = true; end

      advice_called = false
      ClassWithPublicInstanceMethod.new.public_instance_test_method
      advice_called.should be_false
      advice_called = false
      ClassIncludingModuleWithPublicInstanceMethod.new.public_instance_module_test_method
      advice_called.should be_false
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (with a :pointcut(s) parameter and an :exclude_join_point(s) parameter)" do  
    it "should accept :pointcut(s) => [P1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the types and methods to exclude" do  
      included_types = [DontExclude1, DontExclude2]
      excluded_types = [Exclude1, Exclude2]
      excluded_join_point1 = JoinPoint.new :type => Exclude1, :method => :doit
      excluded_join_point2 = JoinPoint.new :type => Exclude2, :method => :doit
      excluded_join_points = [excluded_join_point1, excluded_join_point2]
      pointcut1 = Pointcut.new :types => included_types, :method => :doit
      pointcut2 = Pointcut.new :types => excluded_types, :method => :doit
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcuts => [pointcut1, pointcut2], :exclude_join_points => excluded_join_points do |jp, obj, *args|
        advice_called = true
        excluded_types.should_not include(jp.target_type)
      end 
      included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  end

  describe Aspect, ".new (with an :object(s) and an :exclude_pointcut(s) parameter)" do  
    before :all do
      dontExclude1 = DontExclude1.new(1)
      dontExclude2 = DontExclude1.new(2)
      exclude1 = DontExclude1.new(3)
      exclude2 = DontExclude1.new(4)
      @included_objects = [dontExclude1, dontExclude2]
      @excluded_objects = [exclude1, exclude2]
      @all_objects = @included_objects + @excluded_objects
      excluded_pointcut1 = Pointcut.new :object => exclude1, :method => :doit
      excluded_pointcut2 = Pointcut.new :object => exclude2, :method => :doit
      @excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
    end
    
    it "should accept :object(s) => [o1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the objects and methods to exclude" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :objects => @all_objects, :methods => :doit, :exclude_pointcuts => @excluded_pointcuts, :ignore_no_matching_join_points => true do |jp, obj, *args|
        advice_called = true
        @excluded_objects.should_not include(obj)
      end 

      @included_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should be_true
      end
      @excluded_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_pointcuts"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_pointcuts." do
        aspect = Aspect.new :before, :objects => @all_objects, key.intern => @excluded_pointcuts, :methods => :doit, :noop => true do; end
        aspect.unadvise
      end
    end
  end
    
  describe Aspect, ".new (with a :type(s) and an :exclude_pointcut(s) parameter)" do  
    before :all do
      @included_types = [DontExclude1, DontExclude2]
      @excluded_types = [Exclude1, Exclude2]
      @all_types = @included_types + @excluded_types
      excluded_pointcut1 = Pointcut.new :type => Exclude1, :method => :doit
      excluded_pointcut2 = Pointcut.new :type => Exclude2, :method => :doit
      @excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
    end
    
    it "should accept :type(s) => [T1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the types and methods to exclude" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :types => @all_types, :exclude_pointcuts => @excluded_pointcuts, :methods => :doit do |jp, obj, *args|
        advice_called = true
        @excluded_types.should_not include(jp.target_type)
      end 

      @included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      @excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  end
  
  describe Aspect, ".new (with a :pointcut(s) and an :exclude_pointcut(s) parameter)" do  
    before :all do
      @included_types = [DontExclude1, DontExclude2]
      @excluded_types = [Exclude1, Exclude2]
      @all_types = @included_types + @excluded_types
      excluded_pointcut1 = Pointcut.new :type => Exclude1, :method => :doit
      excluded_pointcut2 = Pointcut.new :type => Exclude2, :method => :doit
      @excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
      pointcut1 = Pointcut.new :types => @included_types, :method => :doit
      pointcut2 = Pointcut.new :types => @excluded_types, :method => :doit
      @all_pointcuts = [pointcut1, pointcut2]
    end
    
    it "should accept :pointcut(s) => [P1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the types and methods to exclude" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcuts => @all_pointcuts, :exclude_pointcuts => @excluded_pointcuts do |jp, obj, *args|
        advice_called = true
        @excluded_types.should_not include(jp.target_type)
      end 
      @included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      @excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end
  end

  describe Aspect, ".new (with a :pointcut(s) and an :exclude_named_pointcut(s) parameter)" do  
    it "should accept :pointcut(s) => [P1, ...], :exclude_named_pointcut(s) => {...}, where any pointcuts matching the latter are excluded" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcuts => Aquarium::PointcutFinderTestClasses.all_pointcuts, 
        :exclude_named_pointcuts => {:matching => /POINTCUT/, :in_types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes} do |jp, obj, *args|
        advice_called = true
        Aquarium::PointcutFinderTestClasses.all_constants_pointcut_classes.should_not include(jp.target_type)
      end 
      Aquarium::PointcutFinderTestClasses.all_class_variables_pointcut_classes.each do |type|
        advice_called = false
        type.new.doit
        advice_called.should be_true
      end
      Aquarium::PointcutFinderTestClasses.all_constants_pointcut_classes.each do |type|
        advice_called = false
        type.new.doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_named_pointcuts"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_named_pointcuts." do
        aspect = Aspect.new :before,  :pointcuts => Aquarium::PointcutFinderTestClasses.all_pointcuts, 
          key.intern => {:matching => /POINTCUT/, :in_types => Aquarium::PointcutFinderTestClasses.all_pointcut_classes},
          :noop => true do; end
        aspect.unadvise
      end
    end
  end
  
  describe Aspect, ".new (with type-based :pointcut(s) and :exclude_type(s) parameter)" do 
    before :all do
      @included_types = [DontExclude1, DontExclude2]
      @excluded_types = [Exclude1, Exclude2]
      @pointcut1 = Pointcut.new :types => @included_types, :method => :doit
      @pointcut2 = Pointcut.new :types => @excluded_types, :method => :doit
    end
       
    it "should accept :pointcut(s) => [P1, ...], :exclude_type(s) => [types], where join points with [types] are excluded" do  
      advice_called = false
      aspect = Aspect.new :before, :pointcuts => [@pointcut1, @pointcut2], :exclude_types => @excluded_types do |jp, obj, *args|
        advice_called = true
        @excluded_types.should_not include(jp.target_type)
      end 

      @included_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should be_true
      end
      @excluded_types.each do |type|
        advice_called = false
        type.new(1).doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_types"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types." do
        aspect = Aspect.new :before,  :pointcuts => [@pointcut1, @pointcut2], key.intern => @excluded_types,
          :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (with type-based :pointcut(s) and :exclude_type(s)_and_ancestors parameter)" do  
    before :all do
      @excluded_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      @types = @excluded_types + [ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod]
      @pointcut1 = Pointcut.new :types => @types, :method => :all, :method_options => [:exclude_ancestor_methods]
    end
    
    it "should accept :pointcut(s) => [P1, ...], :exclude_type(s)_and_ancestors => [types], where join points with [types] are excluded" do  
      aspect = Aspect.new :before, :pointcuts => @pointcut1, :exclude_types_and_ancestors => @excluded_types do |jp, obj, *args|; end
      aspect.pointcuts.each do |pc|
        pc.join_points_matched.each do |jp|
          jp.target_type.should == ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod
        end
      end
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_types_and_ancestors"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_ancestors." do
        aspect = Aspect.new :before,  :pointcuts => @pointcut1, key.intern => @excluded_types,
          :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (with type-based :pointcut(s) and :exclude_type(s)_and_descendents parameter)" do  
    before :all do
      @excluded_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      @types = @excluded_types + [ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod]
      @pointcut1 = Pointcut.new :types => @types, :method => :all, :method_options => [:exclude_ancestor_methods]
    end
    it "should accept :pointcut(s) => [P1, ...], :exclude_type(s)_and_descendents => [types], where join points with [types] are excluded" do  
      aspect = Aspect.new :before, :pointcuts => @pointcut1, :exclude_types_and_descendents => @excluded_types, 
        :ignore_no_matching_join_points => true do |jp, obj, *args|; end
      aspect.pointcuts.size.should == 0
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_types_and_descendents"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_descendents." do
        aspect = Aspect.new :before, :pointcuts => @pointcut1, key.intern => @excluded_types,
          :ignore_no_matching_join_points => true, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (with type-based :pointcut(s) and :exclude_type(s)_and_nested_types parameter)" do  
    before :all do
      @excluded_types = [ClassWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      @types = @excluded_types + [ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod]
      @pointcut1 = Pointcut.new :types => @types, :method => :all, :method_options => [:exclude_ancestor_methods]
    end
    it "should accept :pointcut(s) => [P1, ...], :exclude_type(s)_and_nested_types => [types], where join points with [types] are excluded" do  
      aspect = Aspect.new :before, :pointcuts => @pointcut1, :exclude_types_and_nested_types => @excluded_types, 
        :ignore_no_matching_join_points => true do |jp, obj, *args|; end
      aspect.pointcuts.size.should == 1
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_types_and_nested_types"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_nested_types." do
        aspect = Aspect.new :before, :pointcuts => @pointcut1, key.intern => @excluded_types,
          :ignore_no_matching_join_points => true, :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (with object-based :pointcut(s) and :exclude_object(s) parameter)" do  
    before :all do
      @dontExclude1 = DontExclude1.new(1)
      @dontExclude2 = DontExclude1.new(2)
      @exclude1 = DontExclude1.new(3)
      @exclude2 = DontExclude1.new(4)
      @included_objects = [@dontExclude1, @dontExclude2]
      @excluded_objects = [@exclude1, @exclude2]
      @pointcut1 = Pointcut.new :objects => @included_objects, :method => :doit
      @pointcut2 = Pointcut.new :objects => @excluded_objects, :method => :doit
    end
    
    it "should accept :pointcut(s) => [P1, ...], :exclude_object(s) => [objects], where join points with [objects] are excluded" do  
      aspect = nil
      advice_called = false
      aspect = Aspect.new :before, :pointcuts => [@pointcut1, @pointcut2], :exclude_objects => @excluded_objects do |jp, obj, *args|
        advice_called = true
        @excluded_objects.should_not include(obj)
      end 
      @included_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should be_true
      end
      @excluded_objects.each do |object|
        advice_called = false
        object.doit
        advice_called.should_not be_true
      end
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_objects"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_objects." do
        aspect = Aspect.new :before, :pointcuts => [@pointcut1, @pointcut2], key.intern => @excluded_objects,
          :noop => true do; end
        aspect.unadvise
      end
    end
  end

  describe Aspect, ".new (with :method(s) and :exclude_method(s) parameter)" do  
    before :each do
      @dontExclude1 = DontExclude1.new(1)
      @dontExclude2 = DontExclude1.new(2)
      @exclude1 = DontExclude1.new(3)
      @exclude2 = DontExclude1.new(4)
      @exclude1c = Exclude1c.new(5)
      @included_objects = [@dontExclude1, @dontExclude2, @exclude1, @exclude2]
      @excluded_objects = [@exclude1c]
      @included_types = [DontExclude1, DontExclude2, Exclude1, Exclude2]
      @excluded_types = [Exclude1c]
      @excluded_methods = [:doit3]
      @pointcut1 = Pointcut.new :objects => @included_objects, :method => /doit/
      @pointcut2 = Pointcut.new :objects => @excluded_objects, :method => /doit/
      @pointcut3 = Pointcut.new :types => @included_types, :method => /doit/
      @pointcut4 = Pointcut.new :types => @excluded_types, :method => /doit/
    end
  
    def do_method_exclusion parameter_hash, types_were_specified 
      parameter_hash[:before] = ''
      parameter_hash[:exclude_methods] = :doit3    
      aspect = nil
      advice_called = false
      aspect = Aspect.new parameter_hash do |jp, obj, *args|
        advice_called = true
        @excluded_methods.should_not include(jp.method_name)
      end 
      if types_were_specified
        (@included_types + @excluded_types).each do |type|
          advice_called = false
          type.new(1).doit
          advice_called.should be_true
        end
        @excluded_types.each do |type|
          advice_called = false
          type.new(1).doit3
          advice_called.should_not be_true
        end
      end
      (@included_objects + @excluded_objects).each do |object|
        advice_called = false
        object.doit
        advice_called.should be_true
      end
      @excluded_objects.each do |object|
        advice_called = false
        object.doit3
        advice_called.should_not be_true
      end
      aspect.unadvise
    end

    Aspect::CANONICAL_OPTIONS["exclude_methods"].each do |key|
      it "should accept :#{key} as a synonym for :exclude_methods." do
        aspect = Aspect.new :before, :pointcuts => [@pointcut1, @pointcut2, @pointcut3, @pointcut4], key.intern => :doit3, :noop => true
        aspect.unadvise
      end
    end
  
    it "should accept :pointcut(s) => [P1, ...], :exclude_method(s) => [methods], where join points with [methods] are excluded" do
      parameter_hash = { :pointcuts => [@pointcut1, @pointcut2, @pointcut3, @pointcut4] }
      do_method_exclusion parameter_hash, true
    end

    it "should accept :type(s) => ..., :method(s) => ..., :exclude_method(s) => [methods], where join points with [methods] are excluded" do
      parameter_hash = { :types => (@included_types + @excluded_types), :methods => /doit/ }
      do_method_exclusion parameter_hash, true
    end

    # it "should accept :object(s) => ..., :method(s) => ..., :exclude_method(s) => [methods], where join points with [methods] are excluded" do
    #   pending "bug fix"
    #   Aspect.echo = true
    #   parameter_hash = { :objects => (@included_objects + @excluded_objects), :methods => /doit/ }
    #   do_method_exclusion parameter_hash, false
    #   Aspect.echo = false
    # end
    # 
    # def do_method_exclusion2 parameter_hash, types_were_specified
    #   parameter_hash[:before] = ''
    #   parameter_hash[:exclude_method] = :doit3    
    #   parameter_hash[:method] = /doit/  
    #   aspect = nil
    #   advice_called = false
    #   aspect = Aspect.new parameter_hash do |jp, obj, *args|
    #     advice_called = true
    #     @excluded_methods.should_not include(jp.method_name)
    #   end 
    #   (@excluded_objects).each do |object|
    #     advice_called = false
    #     object.doit
    #     advice_called.should be_true
    #   end
    #   aspect.unadvise
    # end
    # 
    # def buggy parameter_hash
    #   parameter_hash[:before] = ''
    #   parameter_hash[:exclude_method] = :doit3  
    #   aspect = Aspect.new parameter_hash do |jp, obj, *args|
    #   end 
    #   @excluded_objects.each do |object|
    #     object.doit
    #   end
    #   aspect.unadvise
    # end
    # 
    # it "#15202 bug..." do
    #   pending "bug fix"
    #   @pointcut5 = Pointcut.new :types => [Exclude1, Exclude1c], :method => /doit/
    #   parameter_hash = { :pointcuts => [@pointcut5] } #[@pointcut1, @pointcut2, @pointcut3, @pointcut4] }
    #   buggy parameter_hash
    #   parameter_hash = { :objects => (@excluded_objects), :method => /doit/ }
    #   buggy parameter_hash
    # end
  end
end