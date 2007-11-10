require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects/aspect'
require 'aquarium/aspects/dsl'
require 'aquarium/utils/array_utils'

require 'profiler'

include Aquarium::Aspects
include Aquarium::Utils::ArrayUtils


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


describe Aspect, "#new parameters that specify the kind of advice" do
  it "should require the kind of advice as the first parameter." do
    lambda { Aspect.new :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should contain no other advice types if :around advice specified." do
    lambda { Aspect.new :around, :before,          :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aspect.new :around, :after,           :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aspect.new :around, :after_returning, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aspect.new :around, :after_raising,   :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow only one of :after, :after_returning, or :after_raising advice to be specified." do
    lambda { Aspect.new :after, :after_returning, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aspect.new :after, :after_raising,   :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aspect.new :after_returning, :after_raising, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow :before to be specified with :after." do
    lambda { Aspect.new :before, :after, :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow :before to be specified with :after_returning." do
    lambda { Aspect.new :before, :after_returning, :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow :before to be specified with :after_raising." do
    lambda { Aspect.new :before, :after_raising,   :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Aspect, "#new parameters that specify join points" do
  it "should contain at least one of :method(s), :pointcut(s), :type(s), or :object(s)." do
    lambda {Aspect.new(:after) {|jp, obj, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should contain at least one of :pointcut(s), :type(s), or :object(s) unless :default_object => object is given." do
    aspect = Aspect.new(:after, :default_object => Watchful.new, :methods => :public_watchful_method) {|jp, obj, *args| true}
    aspect.unadvise
  end

  it "should not contain :pointcut(s) and either :type(s) or :object(s)." do
    lambda {Aspect.new(:after, :pointcuts => {:type => Watchful, :methods => :public_watchful_method}, :type => Watchful, :methods => :public_watchful_method) {|jp, obj, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda {Aspect.new(:after, :pointcuts => {:type => Watchful, :methods => :public_watchful_method}, :object => Watchful.new, :methods => :public_watchful_method) {|jp, obj, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should include an advice block or :advice => advice parameter." do
    lambda {Aspect.new(:after, :type => Watchful, :methods => :public_watchful_method)}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end


describe Aspect, "#new :type parameter" do
  it "should be accepted as a synonym for :types" do
    @advice = Proc.new {}
    @expected_methods = [:public_watchful_method]
    aspect1 = Aspect.new :before, :type  => Watchful, :method => @expected_methods, :advice => @advice
    aspect2 = Aspect.new :before, :types => Watchful, :method => @expected_methods, :advice => @advice
    aspects_should_be_equal 1, aspect1, aspect2
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Aspect, "#new :pointcut parameter" do
  it "should be accepted as a synonym for :pointcuts" do
    @advice = Proc.new {}
    @expected_methods = [:public_watchful_method]
    aspect1 = Aspect.new :before, :pointcut  => {:type => Watchful, :method => @expected_methods}, :advice => @advice
    aspect2 = Aspect.new :before, :pointcuts => {:type => Watchful, :method => @expected_methods}, :advice => @advice
    aspects_should_be_equal 1, aspect1, aspect2
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Aspect, "#new :object parameter" do
  it "should be accepted as a synonym for :objects" do
    @advice = Proc.new {}
    @expected_methods = [:public_watchful_method]
    watchful = Watchful.new
    aspect1 = Aspect.new :before, :object  => watchful, :method => @expected_methods, :advice => @advice
    aspect2 = Aspect.new :before, :objects => watchful, :method => @expected_methods, :advice => @advice
    aspects_should_be_equal 1, aspect1, aspect2
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Aspect, "#new :method parameter" do
  it "should be accepted as a synonym for :methods" do
    @advice = Proc.new {}
    @expected_methods = [:public_watchful_method]
    aspect1 = Aspect.new :before, :type => Watchful, :method  => @expected_methods, :advice => @advice
    aspect2 = Aspect.new :before, :type => Watchful, :methods => @expected_methods, :advice => @advice
    aspects_should_be_equal 1, aspect1, aspect2
    aspect1.unadvise
    aspect2.unadvise
  end
end

describe Aspect, "#new :attribute parameter" do
  it "should be accepted as a synonym for :attributes" do
    @advice = Proc.new {}
    @expected_methods = [:public_watchful_method_args, :public_watchful_method_args=]
    aspect1 = Aspect.new :before, :type => Watchful, :attribute  => @expected_methods, :advice => @advice
    aspect2 = Aspect.new :before, :type => Watchful, :attributes => @expected_methods, :advice => @advice
    aspects_should_be_equal 2, aspect1, aspect2
    aspect1.unadvise
    aspect2.unadvise
  end
end


describe Aspect, "#new with a :type(s) parameter and a :method(s) parameter" do  
  before :each do
    @protection = 'public'
    @are_class_methods = false
    @method_options = []
  end
  
  def do_type_spec
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :types => @type_spec, :methods => @method_spec, :method_options => @method_options do |jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    if @are_class_methods
      Watchful.method("#{@protection}_class_watchful_method").call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    else
      Watchful.new.method("#{@protection}_watchful_method").call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    end
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :type(s) => [T1, ...], :methods => [m, ...]" do  
    @type_spec = [Watchful]
    @method_spec = [:public_watchful_method]
    do_type_spec
  end

  it "should accept :type(s) => [T1, ...], :methods => m" do  
    @type_spec = [Watchful]
    @method_spec = :public_watchful_method
    do_type_spec
  end

  it "should accept :type(s) => [T1, ...], :methods => /m/" do  
    @type_spec = [Watchful]
    @method_spec = /watchful_method/
    do_type_spec
  end

  it "should accept :type(s) => T1, :methods => [m, ...]" do  
    @type_spec = Watchful
    @method_spec = [:public_watchful_method]
    do_type_spec
  end

  it "should accept :type(s) => T1, :methods => m" do  
    @type_spec = Watchful
    @method_spec = :public_watchful_method
    do_type_spec
  end

  it "should accept :type(s) => T1, :methods => /m/" do  
    @type_spec = Watchful
    @method_spec = /watchful_method/
    do_type_spec
  end

  it "should accept :type(s) => /T1/, :methods => [m, ...]" do  
    @type_spec = /Watchful/
    @method_spec = [:public_watchful_method]
    do_type_spec
  end

  it "should accept :type(s) => /T1/, :methods => m" do  
    @type_spec = /Watchful/
    @method_spec = :public_watchful_method
    do_type_spec
  end

  it "should accept :type(s) => /T1/, :methods => /m/" do  
    @type_spec = /Watchful/
    @method_spec = /watchful_method/
    do_type_spec
  end

  it "should accept :type(s) => ..., :methods => ..., :method_options => [:exclude_ancestor_methods] to exclude methods defined in ancestors" do  
    @type_spec = /Watchful/
    @method_spec = /watchful_method/
    @method_options = [:exclude_ancestor_methods]
    do_type_spec
  end

  it "should accept :type(s) => ..., :methods => ..., :method_options => [:instance, :public] to match only instance and public (both are the defaults) methods" do  
    @type_spec = /Watchful/
    @method_spec = /watchful_method/
    @method_options = [:instance, :public]
    do_type_spec
  end

  %w[public protected private].each do |protection|
    it "should accept :type(s) => ..., :methods => ..., :method_options => [#{protection.intern}] to match only instance (default) #{protection} methods" do  
      @type_spec = /Watchful/
      @method_spec = /watchful_method/
      @method_options = [protection.intern]
      @protection = protection
      do_type_spec
    end
  end

  it "should accept :type(s) => ..., :methods => ..., :method_options => [:class] to match only public (default) class methods" do  
    @type_spec = /Watchful/
    @method_spec = /watchful_method/
    @method_options = [:class]
    @are_class_methods = true
    do_type_spec
  end

  %w[public private].each do |protection|
    it "should accept :type(s) => ..., :methods => ..., :method_options => [:class, :#{protection.intern}] to match only class #{protection} methods" do  
      @type_spec = /Watchful/
      @method_spec = /watchful_method/
      @method_options = [:class, protection.intern]
      @protection = protection
      @are_class_methods = true
      do_type_spec
    end
  end
end


describe Aspect, "#new with a :type(s) parameter and a :attribute(s) parameter" do  
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
    watchful = Watchful.new
    @expected_args = nil
    watchful.method("#{@protection}_watchful_method_args".intern).call 
    @expected_args = :a1
    watchful.method("#{@protection}_watchful_method_args=".intern).call @expected_args
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :type(s) => [T1, ...], :attribute(s) => [a, ...]" do  
    @type_spec = [Watchful]
    @attribute_spec = [:public_watchful_method_args]
    do_type_attribute_spec
  end

  it "should accept :type(s) => [T1, ...], :attribute(s) => a" do  
    @type_spec = [Watchful]
    @attribute_spec = :public_watchful_method_args
    do_type_attribute_spec
  end

  it "should accept :type(s) => [T1, ...], :attribute(s) => /a/" do  
    @type_spec = [Watchful]
    @attribute_spec = /watchful_method_args/
    do_type_attribute_spec
  end

  it "should accept :type(s) => T1, :attribute(s) => [a]" do  
    @type_spec = Watchful
    @attribute_spec = [:public_watchful_method_args]
    do_type_attribute_spec
  end

  it "should accept :type(s) => T1, :attribute(s) => a" do  
    @type_spec = Watchful
    @attribute_spec = :public_watchful_method_args
    do_type_attribute_spec
  end

  it "should accept :type(s) => T1, :attribute(s) => /a/" do  
    @type_spec = Watchful
    @attribute_spec = /watchful_method_args/
    do_type_attribute_spec
  end

  it "should accept :type(s) => /T1/, :attribute(s) => [a, ...]" do  
    @type_spec = /Watchful/
    @attribute_spec = [:public_watchful_method_args]
    do_type_attribute_spec
  end

  it "should accept :type(s) => /T1/, :attribute(s) => a" do  
    @type_spec = /Watchful/
    @attribute_spec = :public_watchful_method_args
    do_type_attribute_spec
  end

  it "should accept :type(s) => /T1/, :attribute(s) => a" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:readers, :writers] to include both attribute reader and writer methods (default)" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:readers, :writers]
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:readers] to include only attribute reader methods" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:readers]
    do_type_attribute_spec
  end

  it "should accept attribute option :reader as a synonym for :readers" do
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:reader]
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:writers] to include only attribute writer methods" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:writers]
    do_type_attribute_spec
  end

  it "should accept attribute option :writer as a synonym for :writers" do
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:writer]
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :readers, :writers] to include both attribute reader and writer methods (default) for class methods" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:class, :readers, :writers]
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :readers] to include only attribute reader class methods" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:class, :readers]
    do_type_attribute_spec
  end

  it "should accept :type(s) => ..., :attributes => ..., :attribute_options => [:class, :writers] to include only attribute writer class methods" do  
    @type_spec = /Watchful/
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:class, :writers]
    do_type_attribute_spec
  end
end

describe Aspect, "#new with a :object(s) parameter and a :method(s) parameter" do  
  before :each do
    @watchful1 = Watchful.new
    @watchful2 = Watchful.new
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
      object.method("#{@protection}_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    end
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :object(s) => [o1, ...], :methods => [m, ...]" do  
    @object_spec = [@watchful1, @watchful2]
    @method_spec = [:public_watchful_method]
    do_object_spec
  end

  it "should accept :object(s) => [o1, ...], :methods => m" do  
    @object_spec = [@watchful1, @watchful2]
    @method_spec = :public_watchful_method
    do_object_spec
  end

  it "should accept :object(s) => [o1, ...], :methods => /m/" do  
    @object_spec = [@watchful1, @watchful2]
    @method_spec = /watchful_method/
    do_object_spec
  end

  it "should accept :object(s) => o1, :methods => [m, ...]" do  
    @object_spec = @watchful1
    @method_spec = [:public_watchful_method]
    do_object_spec
  end

  it "should accept :object(s) => o1, :methods => m" do  
    @object_spec = @watchful1
    @method_spec = :public_watchful_method
    do_object_spec
  end

  it "should accept :object(s) => o1, :methods => /m/" do  
    @object_spec = @watchful1
    @method_spec = /watchful_method/
    do_object_spec
  end

  it "should accept :object(s) => ..., :methods => ..., :method_options => [:exclude_ancestor_methods] to exclude methods defined in ancestors" do  
    @object_spec = @watchful1
    @method_spec = /watchful_method/
    @method_options = [:exclude_ancestor_methods]
    do_object_spec
  end

  it "should accept :object(s) => ..., :methods => ..., :method_options => [:instance, :public] to match only instance and public (both are the defaults) methods" do  
    @object_spec = @watchful1
    @method_spec = /watchful_method/
    @method_options = [:instance, :public]
    do_object_spec
  end

  %w[public protected private].each do |protection|
    it "should accept :object(s) => ..., :methods => ..., :method_options => [#{protection.intern}] to match only instance (default) #{protection} methods" do  
      @object_spec = @watchful1
      @method_spec = /watchful_method/
      @method_options = [protection.intern]
      @protection = protection
      do_object_spec
    end

    it "should accept :object(s) => ..., :methods => ..., :method_options => [:instance, #{protection.intern}] to match only instance #{protection} methods" do  
      @object_spec = @watchful1
      @method_spec = /watchful_method/
      @method_options = [:instance, protection.intern]
      @protection = protection
      do_object_spec
    end
  end
end

describe Aspect, "#new with a :object(s) parameter and a :attribute(s) parameter" do  
  before :each do
    @watchful1 = Watchful.new
    @watchful2 = Watchful.new
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
      object.method("#{@protection}_watchful_method_args".intern).call 
      @expected_args = :a1
      object.method("#{@protection}_watchful_method_args=".intern).call @expected_args
      advice_called.should be_true
    end
    aspect.unadvise
  end

  it "should accept :object(s) => [T1, ...], :attribute(s) => [a, ...]" do  
    @object_spec = [@watchful1, @watchful2]
    @attribute_spec = [:public_watchful_method_args]
    do_object_attribute_spec
  end

  it "should accept :object(s) => [T1, ...], :attribute(s) => a" do  
    @object_spec = [@watchful1, @watchful2]
    @attribute_spec = :public_watchful_method_args
    do_object_attribute_spec
  end

  it "should accept :object(s) => [T1, ...], :attribute(s) => /a/" do  
    @object_spec = [@watchful1, @watchful2]
    @attribute_spec = /watchful_method_args/
    do_object_attribute_spec
  end

  it "should accept :object(s) => T1, :attribute(s) => [a]" do  
    @object_spec = @watchful1
    @attribute_spec = [:public_watchful_method_args]
    do_object_attribute_spec
  end

  it "should accept :object(s) => T1, :attribute(s) => a" do  
    @object_spec = @watchful1
    @attribute_spec = :public_watchful_method_args
    do_object_attribute_spec
  end

  it "should accept :object(s) => T1, :attribute(s) => /a/" do  
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    do_object_attribute_spec
  end

  it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:readers, :writers] to include both attribute reader and writer methods (default)" do  
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:readers, :writers]
    do_object_attribute_spec
  end

  it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:readers] to include only attribute reader methods" do  
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:readers]
    do_object_attribute_spec
  end

  it "should accept attribute option :reader as a synonym for :readers" do
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:reader]
    do_object_attribute_spec
  end

  it "should accept :object(s) => ..., :attributes => ..., :attribute_options => [:writers] to include only attribute writer methods" do  
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:writers]
    do_object_attribute_spec
  end

  it "should accept attribute option :writer as a synonym for :writers" do
    @object_spec = @watchful1
    @attribute_spec = /watchful_method_args/
    @attribute_options = [:writer]
    do_object_attribute_spec
  end
end

describe Aspect, "#new with a :pointcut parameter taking a hash with type specifications" do  
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
      Watchful.method("#{@protection}_class_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    else
      Watchful.new.method("#{@protection}_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    end
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept {:type(s) => [T1, ...], :methods => [m, ...]} " do  
    @pointcut_hash = {:type => [Watchful], :methods => [:public_watchful_method]}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => [T1, ...], :methods => m} " do  
    @pointcut_hash = {:type => [Watchful], :methods => :public_watchful_method}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => [T1, ...], :methods => /m/} " do  
    @pointcut_hash = {:type => [Watchful], :methods => /watchful_method/}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => T1, :methods => [m, ...]} " do  
    @pointcut_hash = {:type => Watchful, :methods => [:public_watchful_method]}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => T1, :methods => m} " do  
    @pointcut_hash = {:type => Watchful, :methods => :public_watchful_method}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => T1, :methods => /m/} " do  
    @pointcut_hash = {:type => Watchful, :methods => /watchful_method/}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => /T1/, :methods => [m, ...]} " do  
    @pointcut_hash = {:type => /Watchful/, :methods => [:public_watchful_method]}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => /T1/, :methods => m} " do  
    @pointcut_hash = {:type => /Watchful/, :methods => :public_watchful_method}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => /T1/, :methods => /m/} " do  
    @pointcut_hash = {:type => /Watchful/, :methods => /watchful_method/}
    do_type_pointcut_spec
  end

  %w[public protected private].each do |protection|
    it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:instance, #{protection}]} " do  
      @protection = protection
      @pointcut_hash = {:type => Watchful, :methods => /watchful_method/, :method_options =>[:instance, protection.intern]}
      do_type_pointcut_spec
    end
  end

  %w[public private].each do |protection|
    it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:class, #{protection}]} " do  
      @pointcut_hash = {:type => Watchful, :methods => /class_watchful_method/, :method_options =>[:class, protection.intern]}
      @protection = protection
      @are_class_methods = true
      do_type_pointcut_spec
    end
  end

  it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:instance]} defaults to public methods" do  
    @pointcut_hash = {:type => Watchful, :methods => /watchful_method/, :method_options =>[:instance]}
    do_type_pointcut_spec
  end

  it "should accept {:type(s) => T1, :methods => /m/, :method_options =>[:class]} defaults to public class methods" do  
    @pointcut_hash = {:type => Watchful, :methods => /watchful_method/, :method_options =>[:class]}
    @are_class_methods = true
    do_type_pointcut_spec
  end
end

describe Aspect, "#new with a :pointcut parameter taking a hash with object specifications" do  
  before :each do
    @protection = 'public'
    @expected_advice_count = 2
    @watchful1 = Watchful.new
    @watchful2 = Watchful.new
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
    @watchful1.method("#{@protection}_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    @watchful2.method("#{@protection}_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_count.should == @expected_advice_count
    aspect.unadvise
  end

  it "should accept {:objects => [o1, ...], :methods => [m, ...]} " do  
    @pointcut_hash = {:objects => [@watchful1, @watchful2], :methods => [:public_watchful_method]}
    do_object_pointcut_spec
  end

  it "should accept {:objects => [o1, ...], :methods => m} " do  
    @pointcut_hash = {:objects => [@watchful1, @watchful2], :methods => :public_watchful_method}
    do_object_pointcut_spec
  end

  it "should accept {:objects => [o1, ...], :methods => /m/} " do  
    @pointcut_hash = {:objects => [@watchful1, @watchful2], :methods => /watchful_method/}
    do_object_pointcut_spec
  end

  it "should accept {:object => o1, :methods => [m, ...]} " do  
    @expected_advice_count = 1
    @pointcut_hash = {:object => @watchful1, :methods => [:public_watchful_method]}
    do_object_pointcut_spec
  end

  it "should accept {:objects => o1, :methods => m} " do  
    @expected_advice_count = 1
    @pointcut_hash = {:objects => @watchful1, :methods => :public_watchful_method}
    do_object_pointcut_spec
  end

  it "should accept {:objects => o1, :methods => /m/} " do  
    @expected_advice_count = 1
    @pointcut_hash = {:objects => @watchful1, :methods => /watchful_method/}
    do_object_pointcut_spec
  end
end

describe Aspect, "#new with a :pointcut parameter and a Pointcut object or an array of Pointcuts" do  
  def do_pointcut_pointcut_spec
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :pointcut => @pointcuts do |jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a single Pointcut object." do
    @pointcuts = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    do_pointcut_pointcut_spec
  end
  
  it "should accept an array of Pointcut objects." do
    pointcut1 = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    pointcut2 = Pointcut.new :type => [Watchful], :methods => :public_class_watchful_method, :method_options => [:class]
    @pointcuts = [pointcut1, pointcut2]
    do_pointcut_pointcut_spec
  end
end

describe Aspect, "#new with a :pointcut parameter and an array of Pointcuts" do  
  it "should treat the array as if it is one Pointcut \"or'ed\" together." do
    advice_called = 0
    advice = Proc.new {|jp, obj, *args|
      advice_called += 1
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    pointcut1 = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    pointcut2 = Pointcut.new :type => [Watchful], :methods => :public_class_watchful_method, :method_options => [:class]
    pointcut12 = pointcut1.or pointcut2
    aspect1 = Aspect.new :before, :pointcut => [pointcut1, pointcut2], :advice => advice
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should == 2
    aspect1.unadvise
    advice_called = 0
    aspect2 = Aspect.new :before, :pointcut => pointcut12, :advice => advice
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should == 2
    aspect2.unadvise
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
  end
end

describe Aspect, "#new with a :type(s) parameter and a :method(s) parameter or one of several equivalent :pointcut parameters" do
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @expected_methods = [:public_watchful_method]
  end
  after :each do
    @aspect1.unadvise
    @aspect2.unadvise
  end
  
  it "should advise equivalent join points when :type => T and :method => m is used or :pointcut =>{:type => T, :method => m} is used." do
    @aspect1 = Aspect.new :after, :type => Watchful, :method => :public_watchful_method, &@advice
    @aspect2 = Aspect.new :after, :pointcut => {:type => Watchful, :method => :public_watchful_method}, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end

  it "should advise equivalent join points when :type => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
    @aspect1 = Aspect.new :after, :type => Watchful, :method => :public_watchful_method, &@advice
    pointcut = Aquarium::Aspects::Pointcut.new :type => Watchful, :method => :public_watchful_method
    @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end
  
  it "should advise equivalent join points when :pointcut =>{:type => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
    @aspect1 = Aspect.new :after, :pointcut => {:type => Watchful, :method => :public_watchful_method}, &@advice
    pointcut = Aquarium::Aspects::Pointcut.new :type => Watchful, :method => :public_watchful_method
    @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end

  it "should advise an equivalent join point when :type => T and :method => m is used or :pointcut => join_point is used, where join_point matches :type => T and :method => m." do
    @aspect1 = Aspect.new :after, :type => Watchful, :method => :public_watchful_method, &@advice
    join_point = Aquarium::Aspects::JoinPoint.new :type => Watchful, :method => :public_watchful_method
    @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
    join_points_should_be_equal 1, @aspect1, @aspect2
  end
end

describe Aspect, "#new with a :type(s) parameter and an :attributes(s) parameter or one of several equivalent :pointcut parameters" do
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

describe Aspect, "#new with a :object(s) parameter and a :method(s) parameter or one of several equivalent :pointcut parameters" do
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @expected_methods = [:public_watchful_method]
  end
  after :each do
    @aspect1.unadvise
    @aspect2.unadvise
  end

  it "should advise equivalent join points when :object => o and :method => m is used or :pointcut =>{:object => o, :method => m} is used." do
    watchful = Watchful.new
    @aspect1 = Aspect.new :after, :object => watchful, :method => :public_watchful_method, &@advice
    @aspect2 = Aspect.new :after, :pointcut => {:object => watchful, :method => :public_watchful_method}, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end

  it "should advise equivalent join points when :object => o and :method => m is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
    watchful = Watchful.new
    @aspect1 = Aspect.new :after, :object => watchful, :method => :public_watchful_method, &@advice
    pointcut = Aquarium::Aspects::Pointcut.new :object => watchful, :method => :public_watchful_method
    @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end

  it "should advise equivalent join points when :pointcut =>{:object => o, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
    watchful = Watchful.new
    @aspect1 = Aspect.new :after, :pointcut => {:object => watchful, :method => :public_watchful_method}, &@advice
    pointcut = Aquarium::Aspects::Pointcut.new :object => watchful, :method => :public_watchful_method
    @aspect2 = Aspect.new :after, :pointcut => pointcut, &@advice
    aspects_should_be_equal 1, @aspect1, @aspect2
  end
end

describe Aspect, "#new with a :object(s) parameter and an :attributes(s) parameter or one of several equivalent :pointcut parameters" do
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

describe Aspect, "#new block for advice" do  
  it "should accept a block as the advice to use." do
    watchful = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method do |jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept an :advice => Proc parameter indicating the advice to use." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advice => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end
  
  it "should accept a :call => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :call => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a :invoke => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :invoke => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a :advise_with => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advise_with => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should ignore all other advice parameters if a block is given." do
    watchful = Watchful.new
    advice_called = false
    advice1 = Proc.new {|jp, obj, *args| fail "advice1"}
    advice2 = Proc.new {|jp, obj, *args| fail "advice2"}
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advice => advice1, :invoke => advice2 do |jp, obj, *args|
      advice_called = true
    end
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should ignore all but the last advice parameter, using any synonym, if there is no advice block." do
    watchful = Watchful.new
    advice_called = false
    advice1 = Proc.new {|jp, obj, *args|
      advice_called = true
      jp.should_not be_nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    advice2 = Proc.new {|jp, obj, *args| raise "should not be called"}
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advice => advice2, :advice => advice1
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
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

describe Aspect, "#new with a :type(s) parameter and an :exclude_type(s) parameter" do  
  def do_exclude_types exclude_type_sym
    included_types = [DontExclude1, DontExclude2]
    excluded_types = [Exclude1, Exclude2]
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :types => (included_types + excluded_types), exclude_type_sym => excluded_types, :methods => :doit do |jp, obj, *args|
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
  
  it "should accept :type(s) => [T1, ...], :exclude_type(s) => [T2, ...] and exclude join points in the excluded types" do  
    do_exclude_types :exclude_types
  end
  
  it "should accept :exclude_type as a synonym for :exclude_types" do  
    do_exclude_types :exclude_type
  end
end


describe Aspect, "#new with a :object(s) parameter and an :exclude_object(s) parameter" do  
  def do_exclude_objects exclude_object_sym
    dontExclude1 = DontExclude1.new(1)
    dontExclude2 = DontExclude1.new(2)
    exclude1 = DontExclude1.new(3)
    exclude2 = DontExclude1.new(4)
    included_objects = [dontExclude1, dontExclude2]
    excluded_objects = [exclude1, exclude2]
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :objects => (included_objects + excluded_objects), exclude_object_sym => excluded_objects, :methods => :doit do |jp, obj, *args|
      advice_called = true
      excluded_objects.should_not include(jp.context.advised_object)
    end 
    included_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should be_true
    end
    excluded_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should_not be_true
    end
    aspect.unadvise
  end
  
  it "should accept :object(s) => [o1, ...], :exclude_object(s) => [o2, ...] and exclude join points in the excluded objects" do  
    do_exclude_objects :exclude_objects
  end
  
  it "should accept :exclude_object as a synonym for :exclude_objects" do  
    do_exclude_objects :exclude_object
  end
end


describe Aspect, "#new with a :pointcut(s), :type(s), :object(s), and :method(s) parameter and an :exclude_join_point(s) parameter" do  
  def do_exclude_join_points exclude_join_points_sym
    dontExclude1 = DontExclude1.new(1)
    dontExclude2 = DontExclude1.new(2)
    exclude1 = DontExclude1.new(3)
    exclude2 = DontExclude1.new(4)
    included_objects = [dontExclude1, dontExclude2]
    excluded_objects = [exclude1, exclude2]
    excluded_join_point1 = JoinPoint.new :object => exclude1, :method => :doit
    excluded_join_point2 = JoinPoint.new :object => exclude2, :method => :doit
    excluded_join_points = [excluded_join_point1, excluded_join_point2]
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :objects => (included_objects + excluded_objects), exclude_join_points_sym => excluded_join_points, :methods => :doit do |jp, obj, *args|
      advice_called = true
      excluded_objects.should_not include(jp.context.advised_object)
    end 

    included_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should be_true
    end
    excluded_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should_not be_true
    end
    aspect.unadvise
  end
  
  it "should accept :exclude_join_point as a synonym for :exclude_join_points" do
    do_exclude_join_points :exclude_join_point
  end

  it "should accept :object(s) => [o1, ...], :exclude_join_point(s) => [jps], where [jps] are the list of join points for the objects and methods to exclude" do  
    do_exclude_join_points :exclude_join_points
  end
  
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

describe Aspect, "#new with a :pointcut(s), :type(s), :object(s), and :method(s) parameter and an :exclude_pointcut(s) parameter" do  
  def do_exclude_pointcuts exclude_pointcuts_sym
    dontExclude1 = DontExclude1.new(1)
    dontExclude2 = DontExclude1.new(2)
    exclude1 = DontExclude1.new(3)
    exclude2 = DontExclude1.new(4)
    included_objects = [dontExclude1, dontExclude2]
    excluded_objects = [exclude1, exclude2]
    excluded_pointcut1 = Pointcut.new :object => exclude1, :method => :doit
    excluded_pointcut2 = Pointcut.new :object => exclude2, :method => :doit
    excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :objects => (included_objects + excluded_objects), exclude_pointcuts_sym => excluded_pointcuts, :methods => :doit do |jp, obj, *args|
      advice_called = true
      excluded_objects.should_not include(jp.context.advised_object)
    end 

    included_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should be_true
    end
    excluded_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should_not be_true
    end
    aspect.unadvise
  end
  
  it "should accept :exclude_pointcut as a synonym for :exclude_pointcuts" do
    do_exclude_pointcuts :exclude_pointcut
  end

  it "should accept :object(s) => [o1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the objects and methods to exclude" do  
    do_exclude_pointcuts :exclude_pointcuts
  end
  
  it "should accept :type(s) => [T1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the types and methods to exclude" do  
    included_types = [DontExclude1, DontExclude2]
    excluded_types = [Exclude1, Exclude2]
    excluded_pointcut1 = Pointcut.new :type => Exclude1, :method => :doit
    excluded_pointcut2 = Pointcut.new :type => Exclude2, :method => :doit
    excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :types => (included_types + excluded_types), :exclude_pointcuts => excluded_pointcuts, :methods => :doit do |jp, obj, *args|
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

  it "should accept :pointcut(s) => [P1, ...], :exclude_pointcut(s) => [pcs], where [pcs] are the list of pointcuts for the types and methods to exclude" do  
    included_types = [DontExclude1, DontExclude2]
    excluded_types = [Exclude1, Exclude2]
    excluded_pointcut1 = Pointcut.new :type => Exclude1, :method => :doit
    excluded_pointcut2 = Pointcut.new :type => Exclude2, :method => :doit
    excluded_pointcuts = [excluded_pointcut1, excluded_pointcut2]
    pointcut1 = Pointcut.new :types => included_types, :method => :doit
    pointcut2 = Pointcut.new :types => excluded_types, :method => :doit
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :pointcuts => [pointcut1, pointcut2], :exclude_pointcuts => excluded_pointcuts do |jp, obj, *args|
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

describe Aspect, "#new with type-based :pointcut(s) and :exclude_type(s) parameter" do  

  it "should accept :pointcut(s) => [P1, ...], :exclude_type(s) => [types], where join points with [types] are excluded" do  
    included_types = [DontExclude1, DontExclude2]
    excluded_types = [Exclude1, Exclude2]
    pointcut1 = Pointcut.new :types => included_types, :method => :doit
    pointcut2 = Pointcut.new :types => excluded_types, :method => :doit
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :pointcuts => [pointcut1, pointcut2], :exclude_types => excluded_types do |jp, obj, *args|
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


describe Aspect, "#new with object-based :pointcut(s) and :exclude_object(s) or :exclude_method(s) parameter" do  

  it "should accept :pointcut(s) => [P1, ...], :exclude_object(s) => [objects], where join points with [objects] are excluded" do  
    dontExclude1 = DontExclude1.new(1)
    dontExclude2 = DontExclude1.new(2)
    exclude1 = DontExclude1.new(3)
    exclude2 = DontExclude1.new(4)
    included_objects = [dontExclude1, dontExclude2]
    excluded_objects = [exclude1, exclude2]
    pointcut1 = Pointcut.new :objects => included_objects, :method => :doit
    pointcut2 = Pointcut.new :objects => excluded_objects, :method => :doit
    aspect = nil
    advice_called = false
    aspect = Aspect.new :before, :pointcuts => [pointcut1, pointcut2], :exclude_objects => excluded_objects do |jp, obj, *args|
      advice_called = true
      excluded_objects.should_not include(jp.context.advised_object)
    end 
    included_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should be_true
    end
    excluded_objects.each do |object|
      advice_called = false
      object.doit
      advice_called.should_not be_true
    end
    aspect.unadvise
  end
end

describe Aspect, "#new with :method(s) and :exclude_method(s) parameter" do  
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
    parameter_hash[:exclude_method] = :doit3    
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

  it "should accept :exclude_method as a synonym for exclude_methods" do
    parameter_hash = { :pointcuts => [@pointcut1, @pointcut2, @pointcut3, @pointcut4] }
    do_method_exclusion parameter_hash, true
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