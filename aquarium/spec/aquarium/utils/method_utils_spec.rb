require File.dirname(__FILE__) + '/../spec_helper.rb'
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

describe Aquarium::Utils::MethodUtils, ".visibility" do
  class ProtectionExample
    def public_instance_method; end
    protected
    def protected_instance_method; end
    private
    def private_instance_method; end
    class << self; self; end.class_eval do
      public
      def public_class_method; end
      private
      def private_class_method; end
    end    
  end
  
  it "should return :public for public class methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_class_method).should == :public
  end
  it "should return :public for public class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_class_method, :class_method_only).should == :public
  end
  it "should return nil for public class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_class_method, :instance_method_only).should == nil
  end

  it "should return :public for public instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_instance_method).should == :public
  end
  it "should return nil for public instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_instance_method, :class_method_only).should == nil
  end
  it "should return :public for public instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :public_instance_method, :instance_method_only).should == :public
  end

  it "should return nil for public class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_class_method).should == nil
  end
  it "should return nil for public class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_class_method, :class_method_only).should == nil
  end
  it "should return nil for public class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_class_method, :instance_method_only).should == nil
  end

  it "should return :public for public instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_instance_method).should == :public    
  end
  it "should return nil for public instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_instance_method, :class_method_only).should == nil
  end
  it "should return :public for public instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :public_instance_method, :instance_method_only).should == :public    
  end
  
  it "should return :protected for protected instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :protected_instance_method).should == :protected
  end
  it "should return nil for protected instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :protected_instance_method, :class_method_only).should == nil
  end
  it "should return :protected for protected instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :protected_instance_method, :instance_method_only).should == :protected
  end

  it "should return :protected for protected instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :protected_instance_method).should == :protected    
  end
  it "should return nil for protected instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :protected_instance_method, :class_method_only).should == nil
  end
  it "should return :protected for protected instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :protected_instance_method, :instance_method_only).should == :protected
  end
  
  it "should return :private for private class methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_class_method).should == :private
  end
  it "should return :private for private class methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_class_method, :class_method_only).should == :private
  end
  it "should return nil for private class methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_class_method, :instance_method_only).should == nil
  end

  it "should return :private for private instance methods on a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_instance_method).should == :private
  end
  it "should return nil for private instance methods on a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_instance_method, :class_method_only).should == nil
  end
  it "should return :private for private instance methods on a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample, :private_instance_method, :instance_method_only).should == :private
  end

  it "should return nil for private class methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_class_method).should == nil
  end
  it "should return nil for private class methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_class_method, :class_method_only).should == nil
  end
  it "should return nil for private class methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_class_method, :instance_method_only).should == nil
  end

  it "should return :private for private instance methods on an instance of a class" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_instance_method).should == :private    
  end
  it "should return nil for private instance methods on an instance of a class when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_instance_method, :class_method_only).should == nil
  end
  it "should return :private for private instance methods on an instance of a class when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :private_instance_method, :instance_method_only).should == :private    
  end
  
  it "should return nil for an unknown method" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :nonexistent_method).should == nil    
  end
  it "should return nil for an unknown method when only class methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :nonexistent_method, :class_method_only).should == nil    
  end
  it "should return nil for an unknown method when only instance methods are specified" do
    Aquarium::Utils::MethodUtils.visibility(ProtectionExample.new, :nonexistent_method, :instance_method_only).should == nil    
  end
end