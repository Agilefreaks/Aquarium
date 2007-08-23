require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'

require 'aquarium/extensions/hash'
require 'aquarium/aspects/join_point'

class Dummy
  def eql?; false; end
  def count; 0; end
end

describe Aquarium::Aspects::JoinPoint, "#initialize with invalid parameters" do
  
  it "should require either a :type or an :object parameter when creating." do
    lambda { Aquarium::Aspects::JoinPoint.new :method_name => :count }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::JoinPoint.new :type => String, :object => "", :method_name => :count }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should require a :method_name parameter when creating." do
    lambda { Aquarium::Aspects::JoinPoint.new :type => String }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should except :method as a synonym for the :method_name parameter." do
    lambda { Aquarium::Aspects::JoinPoint.new :type => String, :method => :split }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
end
  
describe Aquarium::Aspects::JoinPoint, "#initialize with invalid parameters" do
  it "should assume the :method_name refers to an instance method, by default." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split
    jp.is_instance_method?.should be_true
  end
  
  it "should treat the :method_name as refering to an instance method if :is_instance_method is specified as true." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_instance_method => true
    jp.is_instance_method?.should be_true
  end
  
  it "should treat the :method_name as refering to a class method if :is_instance_method is specified as false." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_instance_method => false
    jp.is_instance_method?.should be_false
  end

  it "should treat the :method_name as refering to an instance method if :is_class_method is specified as false." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_class_method => false
    jp.is_instance_method?.should be_true
  end
  
  it "should treat the :method_name as refering to a class method if :is_class_method is specified as true." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_class_method => true
    jp.is_instance_method?.should be_false
  end
  
  it "should treat give precedence to :is_instance_method if appears with :is_class_method." do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_instance_method => false, :is_class_method => true
    jp.is_instance_method?.should be_false
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method => :split, :is_instance_method => true, :is_class_method => false
    jp.is_instance_method?.should be_true
  end
end
  
describe Aquarium::Aspects::JoinPoint, "#dup" do
  it "should duplicate the fields in the join point." do
    jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :count
    jp2 = jp.dup
    jp2.should eql(jp)
  end
end

describe Aquarium::Aspects::JoinPoint, "#eql?" do
  setup do
    @jp1 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp2 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp3 = Aquarium::Aspects::JoinPoint.new :type => Array, :method_name => :size
    @jp4 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
    @jp5 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
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

describe Aquarium::Aspects::JoinPoint, "#==" do
  setup do
    @jp1 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp2 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp3 = Aquarium::Aspects::JoinPoint.new :type => Array, :method_name => :size
    @jp4 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
    @jp5 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
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

describe Aquarium::Aspects::JoinPoint, "#<=>" do
  setup do
    @jp1 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp2 = Aquarium::Aspects::JoinPoint.new :type => Dummy, :method_name => :count
    @jp3 = Aquarium::Aspects::JoinPoint.new :type => Array, :method_name => :size
    @jp4 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
    @jp5 = Aquarium::Aspects::JoinPoint.new :object => [],  :method_name => :size
  end
  
  it "should sort return 0 for the same join points" do
    (@jp1.<=>@jp1).should == 0
  end
  
  it "should sort return 0 for equivalent join points" do
    (@jp1.<=>@jp2).should == 0
  end
  
  it "should sort by type name first" do
  end
end

describe Aquarium::Aspects::JoinPoint, "#make_current_context_join_point when the Aquarium::Aspects::JoinPoint::Context object is nil" do
  it "should return a new join_point that contains the non-context information of the advised_object plus a new Aquarium::Aspects::JoinPoint::Context with the specified context information." do
    jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
    jp.context.should be_nil
    object = "12,34"
    jp_with_context = jp.make_current_context_join_point :advice_kind => :before, :advised_object => object, :parameters => [","], :returned_value => ["12", "34"]
    jp_with_context.object_id.should_not == jp.object_id
    jp.context.should be_nil
    jp_with_context.context.should_not be_nil
    jp_with_context.context.advice_kind.should       == :before
    jp_with_context.context.advised_object.should    == object
    jp_with_context.context.parameters.should        == [","]
    jp_with_context.context.returned_value.should    == ["12", "34"]
    jp_with_context.context.raised_exception.should be_nil
  end
end

describe Aquarium::Aspects::JoinPoint, "#make_current_context_join_point when the Aquarium::Aspects::JoinPoint::Context object is not nil" do
  it "should return a new join_point that contains the non-context information of the advised_object plus an updated Aquarium::Aspects::JoinPoint::Context with the specified context information." do
    jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
    object = "12,34"
    jp.context = Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :advised_object => object, :parameters => [","], :returned_value => ["12", "34"]
    exception = RuntimeError.new
    jp_after = jp.make_current_context_join_point :advice_kind => :after, :returned_value => ["12", "34", "56"], :raised_exception => exception
    jp_after.object_id.should_not == jp.object_id
    jp_after.context.should_not eql(jp.context)
    jp.context.advice_kind.should       == :before
    jp.context.advised_object.should    == object
    jp.context.parameters.should        == [","]
    jp.context.returned_value.should    == ["12", "34"]
    jp.context.raised_exception.should be_nil
    jp_after.context.advice_kind.should       == :after
    jp_after.context.advised_object.should    == object
    jp_after.context.parameters.should        == [","]
    jp_after.context.returned_value.should    == ["12", "34", "56"]
    jp_after.context.raised_exception.should  == exception
  end
end

describe Aquarium::Aspects::JoinPoint, "#type_or_object" do
  it "should return the type if the object is nil" do
    jp = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
    jp.type_or_object.should eql(String)
  end

  it "should return the object if the type is nil" do
    jp = Aquarium::Aspects::JoinPoint.new :object => String.new, :method_name => :split
    jp.type_or_object.should eql("")
  end
end

describe Aquarium::Aspects::JoinPoint::Context, "#initialize" do
  it "should require :advice_kind, :advised_object and :parameters arguments." do
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advised_object => "object", :parameters => [","]}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :parameters => [","]}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :advised_object => "object"}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :advised_object => "object", :parameters => [","]}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should accept a :returned_value argument." do
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :advised_object => "object", :parameters => [","], :returned_value => ["12", "34"]}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should accept a :raised_exception argument." do
    lambda { Aquarium::Aspects::JoinPoint::Context.new :advice_kind => :before, :advised_object => "object", :parameters => [","], :raised_exception => NameError.new}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  
end

describe Aquarium::Aspects::JoinPoint::Context, "#target_object" do
  it "should be a synonym for #advised_object." do
    @object = "12,34"
    @jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
    @jp_with_context = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
    @jp_with_context.context.target_object.should == @jp_with_context.context.advised_object
  end
end

describe Aquarium::Aspects::JoinPoint::Context, "#target_object=" do
  it "should be a synonym for #advised_object=." do
    @object = "12,34"
    @object2 = "12,34,56"
    @jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
    @jp_with_context = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
    @jp_with_context.context.target_object = @object2
    @jp_with_context.context.target_object.should == @object2
    @jp_with_context.context.advised_object.should == @object2
  end
end

def do_common_eql_setup
  @object = "12,34"
  @object2 = "12,34,56"
  @jp  = Aquarium::Aspects::JoinPoint.new :type => String, :method_name => :split
  @jp_with_context1  = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
  @jp_with_context2  = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
  @jp_with_context2b = @jp.make_current_context_join_point :advice_kind => :after,  :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
  @jp_with_context2c = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object2, :parameters => [","], :returned_value => ["12", "34"]
  @jp_with_context2d = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => ["2"], :returned_value => ["1",  ",34"]
end

describe Aquarium::Aspects::JoinPoint::Context, "#eql?" do
  setup do
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
    @jp_with_context1   = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
    jp_with_diff_object = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => "12,34",  :parameters => [","], :returned_value => ["12", "34"]
    @jp_with_context1.context.should_not eql(jp_with_diff_object.context)
  end
end

describe Aquarium::Aspects::JoinPoint::Context, "#==" do
  setup do
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
    @jp_with_context1   = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => @object,  :parameters => [","], :returned_value => ["12", "34"]
    jp_with_diff_object = @jp.make_current_context_join_point :advice_kind => :before, :advised_object => "12,34",  :parameters => [","], :returned_value => ["12", "34"]
    @jp_with_context1.context.should_not == jp_with_diff_object.context
  end
end
