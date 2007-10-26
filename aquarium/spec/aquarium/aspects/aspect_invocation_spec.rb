require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects/aspect'
require 'aquarium/aspects/dsl'

include Aquarium::Aspects

describe Aspect, "#new with invalid invocation parameter list" do
  it "should have as the first parameter at least one of :around, :before, :after, :after_returning, and :after_raising." do
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
end

describe Aspect, "#new, when the arguments contain more than one advice type," do
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

describe Aspect, "#new arguments for specifying the types and methods" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
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

describe Aspect, "#new arguments for specifying the types and attributes" do
  class ClassWithAttrib1
    def initialize *args
      @state = args
    end
    def dummy; end
    attr_accessor :state
  end
  
  before :each do
    @advice = proc {|jp,*args| "advice"}
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
    # pending "working on Pointcut.new first."
    @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, &@advice
    join_point1 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state
    join_point2 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state=
    @aspect2 = Aspect.new :after, :pointcut => Pointcut.new(:join_points => [join_point1, join_point2]), &@advice
    join_points_should_be_equal 2, @aspect1, @aspect2
  end

  it "should advise an equivalent join point when :type => T and :method => :a= (the attribute's writer) is used or :pointcut => join_point is used, where join_point matches :type => T and :method => a=." do
    # pending "working on Pointcut.new first."
    @aspect1 = Aspect.new :after, :type => ClassWithAttrib1, :attribute => :state, :attribute_options => [:writer], &@advice
    join_point = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttrib1, :method => :state=
    @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
    join_points_should_be_equal 1, @aspect1, @aspect2
  end
end

describe Aspect, "#new arguments for specifying the objects and methods" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
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

describe Aspect, "#new arguments for specifying the objects and attributes" do
  class ClassWithAttrib2
    def initialize *args
      @state = args
    end
    def dummy; end
    attr_accessor :state
  end
  
  before :each do
    @advice = proc {|jp,*args| "advice"}
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
    # pending "working on Pointcut.new first."
    @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, &@advice
    join_point1 = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state
    join_point2 = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state=
    @aspect2 = Aspect.new :after, :pointcut => Pointcut.new(:join_points => [join_point1, join_point2]), &@advice
    join_points_should_be_equal 2, @aspect1, @aspect2
  end

  it "should advise an equivalent join point when :type => T and :method => :a= (the attribute's writer) is used or :pointcut => join_point is used, where join_point matches :type => T and :method => a=." do
    # pending "working on Pointcut.new first."
    @aspect1 = Aspect.new :after, :object => @object, :attribute => :state, :attribute_options => [:writer], &@advice
    join_point = Aquarium::Aspects::JoinPoint.new :object => @object, :method => :state=
    @aspect2 = Aspect.new :after, :pointcut => join_point, &@advice
    join_points_should_be_equal 1, @aspect1, @aspect2
  end
end

