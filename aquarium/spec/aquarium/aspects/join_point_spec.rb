require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/extensions/hash'
require 'aquarium/utils/nil_object'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/advice'

class Dummy
  def eql?; false; end
  def count; 0; end
end

class ProtectionExample
  def public_instance_m; end
  protected
  def protected_instance_m; end
  private
  def private_instance_m; end
  def self.public_class_m; end
  def self.private_class_m; end
  private_class_method :private_class_m
end

include Aquarium::Aspects

describe JoinPoint, "#initialize with invalid parameters" do
  
  it "should require either a :type or an :object parameter, but not both." do
    expect { JoinPoint.new :method_name => :count }.to raise_error(Aquarium::Utils::InvalidOptions)
    expect { JoinPoint.new :type => String, :object => "", :method_name => :count }.to raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should require a :method_name." do
    expect { JoinPoint.new :type => String }.to raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should except :method as a synonym for :method_name." do
    expect { JoinPoint.new :type => String, :method => :split }.not_to raise_error
  end

  it "should require a valid type name if a name is specified." do
    expect { JoinPoint.new :type => "String", :method => :split }.not_to raise_error
    expect { JoinPoint.new :type => "Stringgy", :method => :split }.to raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should require a valid type name symbol if a name is specified." do
    expect { JoinPoint.new :type => :String, :method => :split }.not_to raise_error
    expect { JoinPoint.new :type => :Stringgy, :method => :split }.to raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should require a valid type name regular expression if one is specified." do
    expect { JoinPoint.new :type => /^String$/, :method => :split }.not_to raise_error
    expect { JoinPoint.new :type => /^Stringgy$/, :method => :split }.to raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should reject a regular expression that matches no types." do
    expect { JoinPoint.new :type => /^Stringgy$/, :method => :split }.to raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should reject a regular expression that matches more than one type." do
    expect { JoinPoint.new :type => /^M/, :method => :split }.to raise_error(Aquarium::Utils::InvalidOptions)
  end
end
  
describe JoinPoint, "#initialize with parameters that specify class vs. instance methods" do
  it "should assume the :method_name refers to an instance method, by default." do
    jp = JoinPoint.new :type => String, :method => :split
    jp.instance_method?.should be_true
    jp.class_method?.should be_false
  end
  
  it "should treat the :method_name as refering to an instance method if :instance_method is specified as true." do
    jp = JoinPoint.new :type => String, :method => :split, :instance_method => true
    jp.instance_method?.should be_true
    jp.class_method?.should be_false
  end
  
  it "should treat the :method_name as refering to a class method if :instance_method is specified as false." do
    jp = JoinPoint.new :type => String, :method => :split, :instance_method => false
    jp.instance_method?.should be_false
    jp.class_method?.should be_true
  end

  it "should treat the :method_name as refering to an instance method if :class_method is specified as false." do
    jp = JoinPoint.new :type => String, :method => :split, :class_method => false
    jp.instance_method?.should be_true
    jp.class_method?.should be_false
  end
  
  it "should treat the :method_name as refering to a class method if :class_method is specified as true." do
    jp = JoinPoint.new :type => String, :method => :split, :class_method => true
    jp.instance_method?.should be_false
    jp.class_method?.should be_true
  end
  
  it "should treat give precedence to :instance_method if appears with :class_method." do
    jp = JoinPoint.new :type => String, :method => :split, :instance_method => false, :class_method => true
    jp.instance_method?.should be_false
    jp.class_method?.should be_true
    jp = JoinPoint.new :type => String, :method => :split, :instance_method => true, :class_method => false
    jp.instance_method?.should be_true
    jp.class_method?.should be_false
  end
end
  
describe JoinPoint, "#visibility" do
  it "should return :public for public instance methods." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :public_instance_m
    jp.visibility.should == :public
  end
  
  it "should return :public for public instance methods, when only instance methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :public_instance_m, :instance_method => true
    jp.visibility.should == :public
  end
  
  it "should return :public for public class methods, when only class methods are specified using :instance_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :public_class_m, :instance_method => false
    jp.visibility.should == :public
  end

  it "should return :public for public instance methods, when only instance methods are specified using :class_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :public_instance_m, :class_method => false
    jp.visibility.should == :public
  end
  
  it "should return :public for public class methods, when only class methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :public_class_m, :class_method => true
    jp.visibility.should == :public
  end

  it "should return :protected for protected instance methods." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :protected_instance_m
    jp.visibility.should == :protected
  end
  
  it "should return :protected for protected instance methods, when only instance methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :protected_instance_m, :instance_method => true
    jp.visibility.should == :protected
  end
  
  it "should return nil for protected class methods, when only class methods are specified using :instance_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :protected_class_method, :instance_method => false
    jp.visibility.should == nil
  end

  it "should return :protected for protected instance methods, when only instance methods are specified using :class_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :protected_instance_m, :class_method => false
    jp.visibility.should == :protected
  end
  
  it "should return nil for protected class methods, when only class methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :protected_class_method, :class_method => true
    jp.visibility.should == nil
  end

  it "should return :private for private instance methods." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :private_instance_m
    jp.visibility.should == :private
  end
  
  it "should return :private for private instance methods, when only instance methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :private_instance_m, :instance_method => true
    jp.visibility.should == :private
  end
  
  it "should return :private for private class methods, when only class methods are specified using :instance_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :private_class_m, :instance_method => false
    jp.visibility.should == :private
  end

  it "should return :private for private instance methods, when only instance methods are specified using :class_method => false." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :private_instance_m, :class_method => false
    jp.visibility.should == :private
  end
  
  it "should return :private for private class methods, when only class methods are specified." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :private_class_m, :class_method => true
    jp.visibility.should == :private
  end
  
  it "should return nil for non-existent methods." do
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo
    jp.visibility.should == nil
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo, :instance_method => true
    jp.visibility.should == nil
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo, :instance_method => false
    jp.visibility.should == nil
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo, :class_method => true
    jp.visibility.should == nil
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo, :class_method => false
    jp.visibility.should == nil
  end
end

describe JoinPoint, "#target_type" do
  it "should return the type at the JoinPoint" do
    jp = JoinPoint.new :type => ProtectionExample, :method => :foo
    jp.target_type.should be_eql(ProtectionExample)
  end
end
  
describe JoinPoint, "#target_object" do
  it "should return the object at the JoinPoint" do
    example = ProtectionExample.new
    jp = JoinPoint.new :object => example, :method => :foo
    jp.target_object.should be_eql(example)
  end
end

class InvokeOriginalClass
  def invoke; @called = true; end
  def called; @called; end
end

describe JoinPoint, "#proceed" do
  it "should raise when the the context object doesn't have a 'proceed proc'" do
    jp = JoinPoint.new :type => InvokeOriginalClass, :method => :invoke
    ioc = InvokeOriginalClass.new
    jp.context.advice_kind = :around
    jp.context.advised_object = ioc
    jp.context.parameters = []
    jp.context.proceed_proc = nil
    expect { jp.proceed }.to raise_error(JoinPoint::ProceedMethodNotAvailable)
  end

  it "should not raise when the advice is :around advice" do
    jp = JoinPoint.new :type => InvokeOriginalClass, :method => :invoke
    ioc = InvokeOriginalClass.new
    jp.context.advice_kind = :around 
    jp.context.advised_object = ioc 
    jp.context.parameters = []
    jp.context.proceed_proc = Aquarium::Aspects::NoAdviceChainNode.new(:alias_method_name => :invoke)
    expect { jp.proceed }.not_to raise_error
  end
  
  it "should invoke the actual join point" do
    jp = JoinPoint.new :type => InvokeOriginalClass, :method => :invoke
    ioc = InvokeOriginalClass.new
    jp.context.advice_kind = :around
    jp.context.advised_object = ioc
    jp.context.parameters = []
    jp.context.proceed_proc = Aquarium::Aspects::NoAdviceChainNode.new(:alias_method_name => :invoke)
    jp.proceed
    ioc.called.should be_true
  end
end

class InvokeOriginalClass
  def invoke; @called = true; end
  def called; @called; end
end

describe JoinPoint, "#invoke_original_join_point" do
  it "should raise when the join point has an empty context" do
    jp = JoinPoint.new :type => InvokeOriginalClass, :method => :invoke
    expect { jp.invoke_original_join_point }.to raise_error(JoinPoint::ContextNotCorrectlyDefined)
  end

  it "should invoke the original join point" do
    jp = JoinPoint.new :type => InvokeOriginalClass, :method => :invoke
    ioc = InvokeOriginalClass.new
    jp.context.advice_kind = :around 
    jp.context.advised_object = ioc 
    jp.context.parameters = []
    jp.context.current_advice_node = Aquarium::Aspects::NoAdviceChainNode.new(:alias_method_name => :invoke)
    jp.invoke_original_join_point
    ioc.called.should be_true
  end
end

describe JoinPoint, "#dup" do
  it "should duplicate the fields in the join point." do
    jp  = JoinPoint.new :type => String, :method_name => :count
    jp2 = jp.dup
    jp2.should eql(jp)
  end
end

describe JoinPoint, "#eql?" do
  before :each do
    @jp1 = JoinPoint.new :type => Dummy, :method_name => :count
    @jp2 = JoinPoint.new :type => Dummy, :method_name => :count
    @jp3 = JoinPoint.new :type => Array, :method_name => :size
    @jp4 = JoinPoint.new :object => [],  :method_name => :size
    @jp5 = JoinPoint.new :object => [],  :method_name => :size
  end
  
  it "should return true for the same join point." do
    @jp1.should eql(@jp1)
  end

  it "should return true for an identical join point." do
    @jp1.should eql(@jp2)
  end

  it "should return false for a non-identical join point." do
    @jp1.should_not eql(@jp3)
  end

  it "should return false when one join point matches a method for a class and the other matches the same method in an instance of the class." do
    @jp3.should_not eql(@jp4)
  end

  it "should return false for a non-join point object." do
    @jp1.should_not eql("foo")
  end

  it "should return false for two join points that are equal except for the ids of the object they reference." do
    @jp4.should_not eql(@jp5)
  end
end

describe JoinPoint, "#==" do
  before :each do
    @jp1 = JoinPoint.new :type => Dummy, :method_name => :count
    @jp2 = JoinPoint.new :type => Dummy, :method_name => :count
    @jp3 = JoinPoint.new :type => Array, :method_name => :size
    @jp4 = JoinPoint.new :object => [],  :method_name => :size
    @jp5 = JoinPoint.new :object => [],  :method_name => :size
  end
  
  it "should return true for the same join point." do
    @jp1.should == @jp1
  end

  it "should return true for an identical join point." do
    @jp1.should == @jp2
  end

  it "should return false for a non-identical join point." do
    @jp1.should_not == @jp3
  end

  it "should return false when one join point matches a method for a class and the other matches the same method in an instance of the class." do
    @jp3.should_not == @jp4
  end

  it "should return false for a non-join point object." do
    @jp1.should_not == "foo"
  end

  it "should return false for two join points that are equal except for the ids of the object they reference." do
    @jp4.should_not == @jp5
  end
end

describe JoinPoint, "#<=>" do
  before :each do
    @jp1   = JoinPoint.new :type => Dummy, :method_name => :count
    @jp1nc = JoinPoint.new :type => Dummy, :method_name => :count
    @jp2   = JoinPoint.new :type => Dummy, :method_name => :count
    @jp2nc = JoinPoint.new :type => Dummy, :method_name => :count
    @jp3   = JoinPoint.new :type => Array, :method_name => :size
    @jp4   = JoinPoint.new :object => [],  :method_name => :size
    @jp5   = JoinPoint.new :object => [],  :method_name => :size
    dummy  = Dummy.new
    @jp6   = JoinPoint.new :object => dummy,  :method_name => :size
    @jp6nc = JoinPoint.new :object => dummy,  :method_name => :size
    @jp7   = JoinPoint.new :object => dummy,  :method_name => :size
    @jp7nc = JoinPoint.new :object => dummy,  :method_name => :size
    [@jp1, @jp2, @jp6, @jp7].each do |jp|
      jp.context.advice_kind = :before
      jp.context.advised_object = dummy
      jp.context.parameters = []
      jp.context.block_for_method = nil
      jp.context.returned_value = nil
      jp.context.raised_exception = nil
      jp.context.proceed_proc = nil
    end
  end
  
  it "should return 1 of the second object is nil" do
    (@jp1 <=> nil).should == 1
  end
  
  it "should return 0 for the same join point with no context" do
    (@jp1nc <=> @jp1nc).should == 0
    (@jp6nc <=> @jp6nc).should == 0
  end
  
  it "should return 0 for the same join point with equivalent contexts" do
    (@jp1 <=> @jp1).should == 0
    (@jp6 <=> @jp6).should == 0
  end
  
  it "should return 0 for equivalent join points with no context" do
    (@jp1nc <=>@jp2nc).should == 0
    (@jp6nc <=>@jp7nc).should == 0
  end
  
  it "should return 0 for equivalent join points with equivalent contexts" do
    (@jp1 <=> @jp2).should == 0
    (@jp6 <=> @jp7).should == 0
  end
  
  it "should return +1 for join points that are equivalent except for the context, where the first join point has a context and the second has an 'empty' context" do
    (@jp1 <=> @jp2nc).should == 1
    (@jp6 <=> @jp7nc).should == 1
  end
  
  it "should return -1 for join points that are equivalent except for the context, where the second join point has a context and the first has an 'empty' context" do
    (@jp1nc <=> @jp2).should == -1
    (@jp6nc <=> @jp6).should == -1
  end
  
  it "should sort by type name first" do
  end
end

describe JoinPoint, "#type_or_object" do
  it "should return the type if the object is nil" do
    jp = JoinPoint.new :type => String, :method_name => :split
    jp.type_or_object.should eql(String)
  end

  it "should return the object if the type is nil" do
    jp = JoinPoint.new :object => String.new, :method_name => :split
    jp.type_or_object.should eql("")
  end
end

describe JoinPoint, "#exists?" do
  it "should return false if the join point represents a non-existent join point for an instance method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :foo
    jp.exists?.should be_false
  end

  it "should return false if the join point represents a non-existent join point for a class method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :foo, :class_method => true
    jp.exists?.should be_false
  end

  it "should return true if the join point represents a real join point for a public instance method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :public_instance_m
    jp.exists?.should be_true
  end

  it "should return true if the join point represents a real join point for a protected instance method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :protected_instance_m
    jp.exists?.should be_true
  end

  it "should return true if the join point represents a real join point for a private instance method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :private_instance_m
    jp.exists?.should be_true
  end

  it "should return true if the join point represents a real join point for a public class method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :public_class_m, :class_method => true
    jp.exists?.should be_true
  end

  it "should return true if the join point represents a real join point for a private class method in the runtime environment" do
    jp = JoinPoint.new :type => ProtectionExample, :method_name => :private_class_m, :class_method => true
    jp.exists?.should be_true
  end

  class ProtectionExample2
    def public_instance_m; end
    protected
    def protected_instance_m; end
    private
    def private_instance_m; end
    def self.public_class_m; end
    def self.private_class_m; end
    private_class_method :private_class_m
  end
  
end

describe JoinPoint::Context, "#initialize" do
  it "should initialize :advice_kind to Advice::UNKNOWN_ADVICE_KIND if not specified." do
    context = JoinPoint::Context.new 
    context.advice_kind.should equal(Advice::UNKNOWN_ADVICE_KIND)
  end

  it "should initialize :advised_object to equal a NilObject if not specified." do
    context = JoinPoint::Context.new 
    context.advised_object.should eql(Aquarium::Utils::NilObject.new)
  end

  it "should initialize :parameters to [] if not specified." do
    context = JoinPoint::Context.new
    context.parameters.should eql([])
  end

  it "should accept a :returned_value argument." do
    expect { JoinPoint::Context.new :advice_kind => :before, :advised_object => "object", :parameters => [","], :returned_value => ["12", "34"]}.not_to raise_error
  end

  it "should accept a :raised_exception argument." do
    expect { JoinPoint::Context.new :advice_kind => :before, :advised_object => "object", :parameters => [","], :raised_exception => NameError.new}.not_to raise_error
  end
  
end

describe JoinPoint::Context, "#target_object" do
  it "should be a synonym for #advised_object." do
    object = "12,34"
    jp  = JoinPoint.new :type => String, :method_name => :split
    jp.context.advised_object = @object
    jp.context.target_object.should == jp.context.advised_object
  end
end

def do_common_eql_setup
  @object = "12,34"
  @object2 = "12,34,56"
  @jp_with_context1 = JoinPoint.new :type => String, :method_name => :split
  @jp_with_context2 = JoinPoint.new :type => String, :method_name => :split
  @jp_with_context2b = JoinPoint.new :type => String, :method_name => :split
  @jp_with_context2c = JoinPoint.new :type => String, :method_name => :split
  @jp_with_context2d = JoinPoint.new :type => String, :method_name => :split
  @jp_with_context1.context.advice_kind = :before
  @jp_with_context1.context.advised_object = @object
  @jp_with_context1.context.parameters = [","]
  @jp_with_context1.context.returned_value = ["12", "34"]
  @jp_with_context2.context.advice_kind = :before
  @jp_with_context2.context.advised_object = @object
  @jp_with_context2.context.parameters = [","]
  @jp_with_context2.context.returned_value = ["12", "34"]
  @jp_with_context2b.context.advice_kind = :after
  @jp_with_context2b.context.advised_object = @object
  @jp_with_context2b.context.parameters = [","]
  @jp_with_context2b.context.returned_value = ["12", "34"]
  @jp_with_context2c.context.advice_kind = :before
  @jp_with_context2c.context.advised_object = @object2
  @jp_with_context2c.context.parameters = [","]
  @jp_with_context2c.context.returned_value = ["12", "34"]
  @jp_with_context2d.context.advice_kind = :before
  @jp_with_context2d.context.advised_object = @object
  @jp_with_context2d.context.parameters = ["2"]
  @jp_with_context2d.context.returned_value = ["1",  ",34"]
end

describe JoinPoint::Context, "#eql?" do
  before :each do
    do_common_eql_setup
  end
  
  it "should return true for identical contexts." do
    @jp_with_context1.context.should eql(@jp_with_context2.context)
  end
  
  it "should return false for different contexts." do
    @jp_with_context1.context.should_not eql(@jp_with_context2b.context)
    @jp_with_context1.context.should_not eql(@jp_with_context2c.context)
    @jp_with_context1.context.should_not eql(@jp_with_context2d.context)
  end
  
  it "should return false if two equal but different objects are specified." do
    jp_with_diff_object = JoinPoint.new :type => String, :method_name => :split
    jp_with_diff_object.context.advised_object = "12,34"
    @jp_with_context1.context.should_not eql(jp_with_diff_object.context)
  end
end

describe JoinPoint::Context, "#==" do
  before :each do
    do_common_eql_setup
  end
  
  it "should return true for identical contexts." do
    @jp_with_context1.context.should == @jp_with_context2.context
  end
  
  it "should return false for different contexts." do
    @jp_with_context1.context.should_not == @jp_with_context2b.context
    @jp_with_context1.context.should_not == @jp_with_context2c.context
    @jp_with_context1.context.should_not == @jp_with_context2d.context
  end
  
  it "should return false if two equal but different objects are specified." do
    jp_with_diff_object = JoinPoint.new :type => String, :method_name => :split
    jp_with_diff_object.context.advised_object = "12,34"
    @jp_with_context1.context.should_not == jp_with_diff_object.context
  end
end
