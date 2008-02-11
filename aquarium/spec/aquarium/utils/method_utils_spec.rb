require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils/method_utils'

describe Aquarium::Utils::MethodUtils, ".method_args_to_hash" do

  it "should return an empty hash for no arguments." do
    Aquarium::Utils::MethodUtils.method_args_to_hash().should == {}
  end
  
  it "should return an empty hash for a nil argument." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(nil).should == {}
  end
  
  it "should return a hash with the input arguments as keys and nil for each value, if no block is given and the last argument is not a hash." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:a, :b).should == {:a => nil, :b => nil}
  end
    
  it "should return a hash with the input arguments as keys and the block result for each value, if a block is given and the last argument is not a hash." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:a, :b){|key| key.to_s}.should == {:a => 'a', :b => 'b'}
  end
    
  it "should return the input hash if the input arguments consist of a single hash." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:a =>'a', :b => 'b'){|key| key.to_s}.should == {:a => 'a', :b => 'b'}
  end
    
  it "should return the input hash if the input arguments consist of a single hash, ignoring a given block." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:a =>'a', :b => 'b'){|key| key.to_s+key.to_s}.should == {:a => 'a', :b => 'b'}
  end
    
  it "should treat a hash that is not at the end of the argument list as a non-hash argument." do
    hash_arg = {:a =>'a', :b => 'b'}
    h = Aquarium::Utils::MethodUtils.method_args_to_hash(hash_arg, :c){|key| "foo"}
    h.size.should == 2
    h[hash_arg].should == "foo"
    h[:c].should == "foo"
  end
    
  it "should return a hash containing an input hash at the end of the input arguments." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:x, :y, :a =>'a', :b => 'b').should == {:a => 'a', :b => 'b', :x => nil, :y => nil}
  end
    
  it "should ignore whether or not the trailing input hash is wrapped in {}." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:x, :y, {:a =>'a', :b => 'b'}).should == {:a => 'a', :b => 'b', :x => nil, :y => nil}
  end
    
  it "should return a hash with the non-hash arguments mapped to key-value pairs with value specified by the input block (or null) and the input unchanged." do
    Aquarium::Utils::MethodUtils.method_args_to_hash(:x, :y, :a =>'a', :b => 'b'){|a| a.to_s.capitalize}.should == {:a => 'a', :b => 'b', :x => 'X', :y => 'Y'}
  end    
end

class MethodUtilsSpecProtectionExample
  def public_instance_m; end
  protected
  def protected_instance_m; end
  private
  def private_instance_m; end
  def self.public_class_m; end
  def self.private_class_m; end
  private_class_method :private_class_m
end
class MethodUtilsSpecProtectionExample2 < MethodUtilsSpecProtectionExample
end

describe Aquarium::Utils::MethodUtils, ".visibility" do
  it "should return :public for public class methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_class_m).should == :public
  end
  it "should return :public for public class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_class_m, :class_method_only).should == :public
  end
  it "should return nil for public class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_class_m, :instance_method_only).should be_nil
  end

  it "should return :public for public instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_instance_m).should == :public
  end
  it "should return nil for public instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_instance_m, :class_method_only).should be_nil
  end
  it "should return :public for public instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :public_instance_m, :instance_method_only).should == :public
  end

  it "should return nil for public class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_class_m).should be_nil
  end
  it "should return nil for public class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_class_m, :class_method_only).should be_nil
  end
  it "should return nil for public class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_class_m, :instance_method_only).should be_nil
  end

  it "should return :public for public instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_instance_m).should == :public    
  end
  it "should return nil for public instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_instance_m, :class_method_only).should be_nil
  end
  it "should return :public for public instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :public_instance_m, :instance_method_only).should == :public    
  end
  
  it "should return :protected for protected instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :protected_instance_m).should == :protected
  end
  it "should return nil for protected instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :protected_instance_m, :class_method_only).should be_nil
  end
  it "should return :protected for protected instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :protected_instance_m, :instance_method_only).should == :protected
  end

  it "should return :protected for protected instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :protected_instance_m).should == :protected    
  end
  it "should return nil for protected instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :protected_instance_m, :class_method_only).should be_nil
  end
  it "should return :protected for protected instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :protected_instance_m, :instance_method_only).should == :protected
  end
  
  it "should return :private for private class methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_class_m).should == :private #expected_private
  end
  it "should return :private for private class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_class_m, :class_method_only).should == :private #expected_private
  end
  it "should return nil for private class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_class_m, :instance_method_only).should be_nil
  end

  it "should return :private for private instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_instance_m).should == :private
  end
  it "should return nil for private instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_instance_m, :class_method_only).should be_nil
  end
  it "should return :private for private instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample, :private_instance_m, :instance_method_only).should == :private
  end

  it "should return nil for private class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_class_m).should be_nil
  end
  it "should return nil for private class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_class_m, :class_method_only).should be_nil
  end
  it "should return nil for private class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_class_m, :instance_method_only).should be_nil
  end

  it "should return :private for private instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_instance_m).should == :private    
  end
  it "should return nil for private instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_instance_m, :class_method_only).should be_nil
  end
  it "should return :private for private instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :private_instance_m, :instance_method_only).should == :private    
  end
  
  it "should ignore whether the exclude_ancestors flag is true or false for class methods when running under MRI" do
    unless Object.const_defined?('JRUBY_VERSION')
      Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :public_class_m,  :class_method_only, false).should == :public
      Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :private_class_m, :class_method_only, false).should == :private
    end
  end
  it "should NOT ignore whether the exclude_ancestors flag is true or false for class methods when running under JRuby" do
    if Object.const_defined?('JRUBY_VERSION')
      Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :public_class_m,  :class_method_only, false).should == nil
      Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :private_class_m, :class_method_only, false).should == nil
    end
  end
  
  it "should return nil for public instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :public_instance_m, :instance_method_only, false).should == nil
  end
  it "should return nil for protected instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :protected_instance_m, :instance_method_only, false).should == nil
  end
  it "should return nil for private instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample2, :private_instance_m, :instance_method_only, false).should == nil
  end
    
  it "should return nil for an unknown method" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :nonexistent_method).should be_nil    
  end
  it "should return nil for an unknown method when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :nonexistent_method, :class_method_only).should be_nil    
  end
  it "should return nil for an unknown method when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(MethodUtilsSpecProtectionExample.new, :nonexistent_method, :instance_method_only).should be_nil    
  end
end

describe Aquarium::Utils::MethodUtils, ".has_method" do
  it "should return true for public class methods on a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_class_m).should be_true
  end
  it "should return true for public class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_class_m, :class_method_only).should be_true
  end
  it "should return false for public class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_class_m, :instance_method_only).should be_false
  end

  it "should return true for public instance methods on a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_instance_m).should be_true
  end
  it "should return false for public instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_instance_m, :class_method_only).should be_false
  end
  it "should return true for public instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :public_instance_m, :instance_method_only).should be_true
  end

  it "should return false for public class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_class_m).should be_false
  end
  it "should return false for public class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_class_m, :class_method_only).should be_false
  end
  it "should return false for public class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_class_m, :instance_method_only).should be_false
  end

  it "should return true for public instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_instance_m).should be_true    
  end
  it "should return false for public instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_instance_m, :class_method_only).should be_false
  end
  it "should return true for public instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :public_instance_m, :instance_method_only).should be_true    
  end
  
  it "should return true for protected instance methods on a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :protected_instance_m).should be_true
  end
  it "should return false for protected instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :protected_instance_m, :class_method_only).should be_false
  end
  it "should return true for protected instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :protected_instance_m, :instance_method_only).should be_true
  end

  it "should return true for protected instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :protected_instance_m).should be_true    
  end
  it "should return false for protected instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :protected_instance_m, :class_method_only).should be_false
  end
  it "should return true for protected instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :protected_instance_m, :instance_method_only).should be_true
  end
  
  it "should return true for private class methods on a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_class_m).should be_true #expected_private
  end
  it "should return true for private class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_class_m, :class_method_only).should be_true 
  end
  it "should return false for private class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_class_m, :instance_method_only).should be_false
  end

  it "should return true for private instance methods on a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_instance_m).should be_true
  end
  it "should return false for private instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_instance_m, :class_method_only).should be_false
  end
  it "should return true for private instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample, :private_instance_m, :instance_method_only).should be_true
  end

  it "should return false for private class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_class_m).should be_false
  end
  it "should return false for private class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_class_m, :class_method_only).should be_false
  end
  it "should return false for private class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_class_m, :instance_method_only).should be_false
  end

  it "should return true for private instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_instance_m).should be_true    
  end
  it "should return false for private instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_instance_m, :class_method_only).should be_false
  end
  it "should return true for private instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :private_instance_m, :instance_method_only).should be_true    
  end
  
  not_string, true_or_false, ruby_name = Object.const_defined?('JRUBY_VERSION') ? ['NOT ', false, 'JRuby'] : ['', true, 'MRI'] 
  it "should #{not_string}ignore whether the exclude_ancestors flag is true or false for class methods when running under #{ruby_name}" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample2, :public_class_m,  :class_method_only, false).should == true_or_false
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample2, :private_class_m, :class_method_only, false).should == true_or_false
  end
  
  it "should return false for public instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample2, :public_instance_m, :instance_method_only, false).should be_false
  end
  it "should return false for protected instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample2, :protected_instance_m, :instance_method_only, false).should be_false
  end
  it "should return false for private instance methods on a subclass when the exclude_ancestors flag is false" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample2, :private_instance_m, :instance_method_only, false).should be_false
  end
    
  it "should return false for an unknown method" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :nonexistent_method).should be_false    
  end
  it "should return false for an unknown method when only class methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :nonexistent_method, :class_method_only).should be_false    
  end
  it "should return false for an unknown method when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.has_method(MethodUtilsSpecProtectionExample.new, :nonexistent_method, :instance_method_only).should be_false    
  end
end

module DefinerModule1
  def m1; end
end
module DefinerModule2
  def m2; end
end
class DefinerClass1
  include DefinerModule1
  def c1; end
end
class DefinerClass2 < DefinerClass1
  include DefinerModule2
  def c2; end
end
class DefinerClass2b < DefinerClass1
  include DefinerModule2
end

describe Aquarium::Utils::MethodUtils, ".definer" do
  it "should return the type that defines the method, when given a type" do
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b, :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b, :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b, :m2).should == DefinerModule2
    Aquarium::Utils::MethodUtils.definer(DefinerClass2,  :c2).should == DefinerClass2
    Aquarium::Utils::MethodUtils.definer(DefinerClass2,  :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2,  :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2,  :m2).should == DefinerModule2
    Aquarium::Utils::MethodUtils.definer(DefinerClass1,  :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass1,  :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(DefinerModule2, :m2).should == DefinerModule2
    Aquarium::Utils::MethodUtils.definer(DefinerModule1, :m1).should == DefinerModule1
  end
  
  it "should return the type that defines the method, when given an object" do
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b.new, :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b.new, :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b.new, :m2).should == DefinerModule2
    Aquarium::Utils::MethodUtils.definer(DefinerClass2.new,  :c2).should == DefinerClass2
    Aquarium::Utils::MethodUtils.definer(DefinerClass2.new,  :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2.new,  :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(DefinerClass2.new,  :m2).should == DefinerModule2
    Aquarium::Utils::MethodUtils.definer(DefinerClass1.new,  :c1).should == DefinerClass1
    Aquarium::Utils::MethodUtils.definer(DefinerClass1.new,  :m1).should == DefinerModule1
  end
  
  it "should return the eigenclass/singleton of an object when the method is defined on the object" do
    dc = DefinerClass2.new
    eigen = (class << dc; self; end)
    def dc.dc1; end
    Aquarium::Utils::MethodUtils.definer(dc, :dc1).should == eigen
  end

  it "should return the class of an object when the method is defined on the type or ancestor type, even if the eigenclass has been used to define an instance-only type" do
    dc = DefinerClass2.new
    eigen = (class << dc; self; end)
    def dc.dc2; end
    Aquarium::Utils::MethodUtils.definer(dc, :c2).should == DefinerClass2
    Aquarium::Utils::MethodUtils.definer(dc, :m1).should == DefinerModule1
    Aquarium::Utils::MethodUtils.definer(dc, :m2).should == DefinerModule2
  end

  it "should return nil if the specified method is defined by a subtype of the specified type" do
    Aquarium::Utils::MethodUtils.definer(DefinerClass1,  :c2).should be_nil
    Aquarium::Utils::MethodUtils.definer(DefinerModule1, :c2).should be_nil
    Aquarium::Utils::MethodUtils.definer(DefinerModule2, :c2).should be_nil
  end

  it "should return nil if the specified method is defined by a subtype of the specified object's type" do
    Aquarium::Utils::MethodUtils.definer(DefinerClass1.new,  :c2).should be_nil
    Aquarium::Utils::MethodUtils.definer(DefinerClass2b.new, :c2).should be_nil
  end

  it "should return nil if nil is specified for the type or object" do
    Aquarium::Utils::MethodUtils.definer(nil, :ignored).should be_nil
  end

  it "should return nil if nil is specified for the method" do
    Aquarium::Utils::MethodUtils.definer(DefinerModule1,    nil).should be_nil
    Aquarium::Utils::MethodUtils.definer(DefinerClass1,     nil).should be_nil
    Aquarium::Utils::MethodUtils.definer(DefinerClass1.new, nil).should be_nil
  end
end