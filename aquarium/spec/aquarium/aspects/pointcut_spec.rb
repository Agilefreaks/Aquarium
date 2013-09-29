require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils/type_utils_sample_nested_types'
require 'aquarium/utils/invalid_options'
require 'aquarium/extensions/hash'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/pointcut'
require 'aquarium/utils'

include Aquarium::Aspects

def before_exclude_spec
  @jp11  = JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method11
  @jp12  = JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method12
  @jp13  = JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method13
  @jp21  = JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method21
  @jp22  = JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method22
  @jp23  = JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method23
  @jp31  = JoinPoint.new :type   => ExcludeTestThree, :method_name => :method31
  @jp32  = JoinPoint.new :type   => ExcludeTestThree, :method_name => :method32
  @jp33  = JoinPoint.new :type   => ExcludeTestThree, :method_name => :method33
  @et1 = ExcludeTestOne.new
  @et2 = ExcludeTestTwo.new
  @et3 = ExcludeTestThree.new
  @ojp11 = JoinPoint.new :object => @et1, :method_name => :method11
  @ojp12 = JoinPoint.new :object => @et1, :method_name => :method12
  @ojp13 = JoinPoint.new :object => @et1, :method_name => :method13
  @ojp21 = JoinPoint.new :object => @et2, :method_name => :method21
  @ojp22 = JoinPoint.new :object => @et2, :method_name => :method22
  @ojp23 = JoinPoint.new :object => @et2, :method_name => :method23
  @ojp31 = JoinPoint.new :object => @et3, :method_name => :method31
  @ojp32 = JoinPoint.new :object => @et3, :method_name => :method32
  @ojp33 = JoinPoint.new :object => @et3, :method_name => :method33
  @all_type_jps   = [@jp11,  @jp12,  @jp13,  @jp21,  @jp22,  @jp23,  @jp31,  @jp32,  @jp33]
  @all_object_jps = [@ojp11, @ojp12, @ojp13, @ojp21, @ojp22, @ojp23, @ojp31, @ojp32, @ojp33]
  @all_jps = @all_type_jps + @all_object_jps
end

def before_pointcut_class_spec
  @example_classes_without_public_instance_method = 
  [ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod, ClassWithPublicClassMethod, ClassWithPrivateClassMethod]
  @example_classes = ([ClassWithPublicInstanceMethod] + @example_classes_without_public_instance_method)
  @pub_jp   = JoinPoint.new :type => ClassWithPublicInstanceMethod,    :method_name => :public_instance_test_method
  @pro_jp   = JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method_name => :protected_instance_test_method
  @pri_jp   = JoinPoint.new :type => ClassWithPrivateInstanceMethod,   :method_name => :private_instance_test_method
  @cpub_jp  = JoinPoint.new :type => ClassWithPublicClassMethod,       :method_name => :public_class_test_method, :class_method => true
  @cpri_jp  = JoinPoint.new :type => ClassWithPrivateClassMethod,      :method_name => :private_class_test_method, :class_method => true
  @apro_jp  = JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method_name => :all
  @apri_jp  = JoinPoint.new :type => ClassWithPrivateInstanceMethod,   :method_name => :all
  @acpub_jp = JoinPoint.new :type => ClassWithPublicClassMethod,       :method_name => :all
  @acpri_jp = JoinPoint.new :type => ClassWithPrivateClassMethod,      :method_name => :all
  @cdcimpub_jp = JoinPoint.new :type => ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod, :method_name => :public_instance_class_derived_from_class_including_module_test_method
  @expected_classes_matched_jps = Set.new [@pub_jp]
  @expected_classes_not_matched_jps = Set.new [@apro_jp, @apri_jp, @acpub_jp, @acpri_jp]
end

def before_pointcut_module_spec
  @example_modules_with_public_instance_method = [
    ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod,
    ClassIncludingModuleWithPublicInstanceMethod,
    ModuleIncludingModuleWithPublicInstanceMethod, 
    ModuleWithPublicInstanceMethod]    
  @example_modules_without_public_instance_method = [
    ClassIncludingModuleWithProtectedInstanceMethod, 
    ClassIncludingModuleWithPrivateInstanceMethod, 
    ClassIncludingModuleWithPublicClassMethod, 
    ClassIncludingModuleWithPrivateClassMethod,
    ModuleWithProtectedInstanceMethod, 
    ModuleWithPrivateInstanceMethod, 
    ModuleWithPublicClassMethod, 
    ModuleWithPrivateClassMethod]
  @example_modules = (@example_modules_with_public_instance_method + @example_modules_without_public_instance_method)
  @mimpub_jp = JoinPoint.new :type => ModuleIncludingModuleWithPublicInstanceMethod, :method_name => :public_instance_module_including_module_test_method
  @mpub_jp   = JoinPoint.new :type => ModuleWithPublicInstanceMethod,    :method_name => :public_instance_module_test_method
  @mpro_jp   = JoinPoint.new :type => ModuleWithProtectedInstanceMethod, :method_name => :protected_instance_module_test_method
  @mpri_jp   = JoinPoint.new :type => ModuleWithPrivateInstanceMethod,   :method_name => :private_instance_module_test_method
  @cmpub_jp  = JoinPoint.new :type => ModuleWithPublicClassMethod,       :method_name => :public_class_module_test_method, :class_method => true
  @cmpri_jp  = JoinPoint.new :type => ModuleWithPrivateClassMethod,      :method_name => :private_class_module_test_method, :class_method => true
  @ampro_jp  = JoinPoint.new :type => ModuleWithProtectedInstanceMethod, :method_name => :all
  @ampri_jp  = JoinPoint.new :type => ModuleWithPrivateInstanceMethod,   :method_name => :all
  @acmpub_jp = JoinPoint.new :type => ModuleWithPublicClassMethod,       :method_name => :all
  @acmpri_jp = JoinPoint.new :type => ModuleWithPrivateClassMethod,      :method_name => :all
  @cdcimpub_jp = JoinPoint.new :type => ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod, :method_name => :public_instance_class_derived_from_class_including_module_test_method
  @cimpub_jp   = JoinPoint.new :type => ClassIncludingModuleWithPublicInstanceMethod,    :method_name => :public_instance_class_including_module_test_method
  @cimpro_jp   = JoinPoint.new :type => ClassIncludingModuleWithProtectedInstanceMethod, :method_name => :protected_instance_class_including_module_test_method
  @cimpri_jp   = JoinPoint.new :type => ClassIncludingModuleWithPrivateInstanceMethod,   :method_name => :private_instance_class_including_module_test_method
  @ccimpub_jp  = JoinPoint.new :type => ClassIncludingModuleWithPublicClassMethod,       :method_name => :public_class_class_including_module_test_method, :class_method => true
  @ccimpri_jp  = JoinPoint.new :type => ClassIncludingModuleWithPrivateClassMethod,      :method_name => :private_class_class_including_module_test_method, :class_method => true
  @acimpro_jp  = JoinPoint.new :type => ClassIncludingModuleWithProtectedInstanceMethod, :method_name => :all
  @acimpri_jp  = JoinPoint.new :type => ClassIncludingModuleWithPrivateInstanceMethod,   :method_name => :all
  @accimpub_jp = JoinPoint.new :type => ClassIncludingModuleWithPublicClassMethod,       :method_name => :all
  @accimpri_jp = JoinPoint.new :type => ClassIncludingModuleWithPrivateClassMethod,      :method_name => :all
  @expected_modules_matched_jps = Set.new [@mimpub_jp, @mpub_jp, @cdcimpub_jp, @cimpub_jp]
  @expected_modules_not_matched_jps = Set.new [@ampro_jp, @ampri_jp, @acmpub_jp, @acmpri_jp, @acimpro_jp, @acimpri_jp, @accimpub_jp, @accimpri_jp]
end

def ignored_join_point jp
  # Ignore any type ambiguities introduced by Ruby 1.9.X.
  # Igore types introduced by RSpec, other Aquarium types, 
  # and the "pretty printer" module (which Rake uses?)
  jp.target_type.name =~ /^(Basic)?Object/ or 
  jp.target_type.name =~ /^R?Spec/ or 
  jp.target_type.name =~ /^Aquarium::(Aspects|Extras|Utils|PointcutFinderTestClasses)/ or 
  jp.target_type.name =~ /^PP/ or
  jp.target_type.name =~ /InstanceExecHelper/
end

describe Pointcut, "methods" do
  include Aquarium::TypeUtilsStub
  
  before :all do
    stub_type_utils_descendents
  end
  after :all do
    unstub_type_utils_descendents
  end
    
  describe Pointcut, ".new (invalid arguments)" do
    it "should raise if an unknown argument is specified" do
      expect { Pointcut.new :foo => :bar }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (empty)" do
    it "should match no join points by default." do
      pc = Pointcut.new
      pc.should be_empty
    end

    it "should match no join points if nil is the only argument specified." do
      pc = Pointcut.new nil
      pc.should be_empty
    end

    it "should match no join points if types = [] specified." do
      pc = Pointcut.new :types => []
      pc.should be_empty
    end
  
    it "should match no join points if types = nil specified." do
      pc = Pointcut.new :types => nil
      pc.should be_empty
    end
  
    it "should match no join points if objects = [] specified." do
      pc = Pointcut.new :objects => []
      pc.should be_empty
    end
  
    it "should match no join points if objects = nil specified." do
      pc = Pointcut.new :objects => nil
      pc.should be_empty
    end
  
    it "should match no join points if join_points = nil specified." do
      pc = Pointcut.new :join_points => nil
      pc.should be_empty
    end
  
    it "should match no join points if join_points = [] specified." do
      pc = Pointcut.new :join_points => []
      pc.should be_empty
    end
  end

  describe Pointcut, ".new  (classes specified using regular expressions)" do
    before(:each) do
      before_pointcut_class_spec
    end

    it "should match multiple classes using regular expressions that cover the full class names." do
      pc = Pointcut.new :types => /\AClass(?!IncludingModule).*Method\Z/, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == (@expected_classes_matched_jps + [@cdcimpub_jp])
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end

    it "should match clases using regular expressions that only cover partial class names." do
      pc = Pointcut.new :types => /lass(?!IncludingModule).*Pro.*Inst.*Met/, :method_options => [:public, :protected, :exclude_ancestor_methods]
      pc.join_points_matched.should == Set.new([@pro_jp])
      pc.join_points_not_matched.size.should == 0
    end
  end

  describe Pointcut, ".new (classes specified using names)" do
    before(:each) do
      before_pointcut_class_spec
    end

    it "should match multiple classes using names." do
      pc = Pointcut.new :types => @example_classes.map {|t| t.to_s}, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end
  
    it "should match multiple classes using classes themselves." do
      pc = Pointcut.new :types => @example_classes, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end
  
    it "should match :all public instance methods for classes by default." do
      pc = Pointcut.new :types => @example_classes, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end

    it "should match all public instance methods for classes if :methods => :all specified." do
      pc = Pointcut.new :types => @example_classes, :methods => :all, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end

    it "should match all public instance methods for classes if :methods => :all_methods specified." do
      pc = Pointcut.new :types => @example_classes, :methods => :all_methods, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end

    it "should support MethodFinder's :exclude_ancestor_methods option when using classes." do
      pc = Pointcut.new :types => @example_classes, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == @expected_classes_matched_jps
      pc.join_points_not_matched.should == @expected_classes_not_matched_jps
    end

    Pointcut::CANONICAL_OPTIONS["types"].each do |key|
      it "should accept :#{key} as a synonym for :types." do
        pc = Pointcut.new key.intern => @example_classes, :method_options => :exclude_ancestor_methods
        pc.join_points_matched.should == @expected_classes_matched_jps
        pc.join_points_not_matched.should == @expected_classes_not_matched_jps
      end
    end
  end

  describe Pointcut, ".new (modules specified using regular expressions)" do
    it "should match multiple types using regular expressions that cover the full module names." do
      pc = Pointcut.new :types => /\AModule.*Method\Z/, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 2
      pc.join_points_matched.each do |jp| 
        [ModuleIncludingModuleWithPublicInstanceMethod, ModuleWithPublicInstanceMethod].should include(jp.target_type)
      end
      pc.join_points_not_matched.size.should == 4
      pc.join_points_not_matched.each do |jp|
        [ModuleWithPrivateInstanceMethod, ModuleWithProtectedInstanceMethod, 
          ModuleWithPublicClassMethod, ModuleWithPrivateClassMethod].should include(jp.target_type)
      end
    end
  end

  describe Pointcut, ".new (modules specified using names)" do
    def do_module type_spec
      pc = Pointcut.new :types => type_spec, :method_options => :exclude_ancestor_methods 
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each do |jp| 
        jp.target_type.should == ModuleWithPublicInstanceMethod
        jp.method_name.should == :public_instance_module_test_method
      end
      pc.join_points_not_matched.size.should == 1
      pc.join_points_not_matched.each do |jp| 
        jp.target_type.should == ModuleWithPublicClassMethod
        jp.method_name.should == :all
      end
    end
  
    it "should match multiple types using module names." do
      do_module ["ModuleWithPublicInstanceMethod", "ModuleWithPublicClassMethod"]
    end
  
    it "should match multiple types using module-name regular expressions." do
      do_module /^ModuleWithPublic.*Method/
    end
  
    it "should match multiple types using modules themselves." do
      do_module [ModuleWithPublicInstanceMethod, ModuleWithPublicClassMethod]
    end
  
    it "should match :all public instance methods for modules by default." do
      do_module [ModuleWithPublicInstanceMethod, ModuleWithPublicClassMethod]
    end

    it "should support MethodFinder's :exclude_ancestor_methods option when using modules." do
      do_module [ModuleWithPublicInstanceMethod, ModuleWithPublicClassMethod]
    end
  end

  describe Pointcut, ".new (types and their ancestors and descendents)" do
    before(:each) do
      before_pointcut_module_spec
    end

    it "should match classes specified and their ancestor and descendent modules and classes." do
      pc = Pointcut.new :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, :types_and_descendents => /^Class(Including|DerivedFrom).*Method/, :methods => :all, :method_options => :exclude_ancestor_methods
      expected_types = @example_modules_with_public_instance_method + [Kernel, Module]
      pc.join_points_matched.each do |jp|
        next if ignored_join_point(jp)
        expected_types.should include(jp.target_type)
      end
      not_expected_types = @expected_modules_not_matched_jps.map {|jp| jp.target_type}
      pc.join_points_not_matched.each do |jp|
        next if ignored_join_point(jp)
        not_expected_types.should include(jp.target_type)
      end
    end

    it "should match modules specified, their ancestor and descendent modules, and including classes." do
      pc = Pointcut.new :types_and_ancestors => /^Module.*Method/, :types_and_descendents => /^Module.*Method/, :methods => :all, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == (@expected_modules_matched_jps + [@mimpub_jp])
      pc.join_points_not_matched.should == @expected_modules_not_matched_jps
    end
    
    Aspect::CANONICAL_OPTIONS["types_and_ancestors"].reject{|key| key.eql?("types_and_ancestors")}.each do |key|
      it "should accept :#{key} as a synonym for :types_and_ancestors." do
        expect {Pointcut.new key.intern => /^Module.*Method/, :methods => :all, :noop => true}.not_to raise_error
      end
    end
  
    Aspect::CANONICAL_OPTIONS["types_and_descendents"].reject{|key| key.eql?("types_and_descendents")}.each do |key|
      it "should accept :#{key} as a synonym for :types_and_descendents." do
        expect {Pointcut.new key.intern => /^Module.*Method/, :methods => :all, :noop => true}.not_to raise_error
      end
    end
  end
  
  describe Pointcut, ".new (types and their nested types)" do
    before(:each) do
      before_pointcut_module_spec
    end

    it "should match types specified and their nested types." do
      pc = Pointcut.new :types_and_nested_types => Aquarium::NestedTestTypes, :methods => :all, :method_options => :exclude_ancestor_methods
      expected_types = Aquarium::NestedTestTypes.nested_in_NestedTestTypes[Aquarium::NestedTestTypes]
      pc.join_points_matched.size.should == expected_types.size
      pc.join_points_matched.each do |jp|
        expected_types.should include(jp.target_type)
      end
      pc.join_points_not_matched.size.should == 0
    end

    Aspect::CANONICAL_OPTIONS["types_and_nested_types"].reject{|key| key.eql?("types_and_nested_types")}.each do |key|
      it "should accept :#{key} as a synonym for :types_and_nested_types." do
        expect {Pointcut.new key.intern => /^Module.*Method/, :methods => :all, :noop => true}.not_to raise_error
      end
    end
  end
  
  describe Pointcut, ".new (objects specified)" do
    before(:each) do
      before_pointcut_class_spec
    end

    it "should match :all public instance methods for objects by default." do
      pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :objects => [pub, pro], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new([JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
      pc.join_points_not_matched.should == Set.new([JoinPoint.new(:object => pro, :method_name => :all)])
    end
  
    it "should support MethodFinder's :exclude_ancestor_methods option when using objects." do
      pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :objects => [pub, pro], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new([JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
      pc.join_points_not_matched.should == Set.new([JoinPoint.new(:object => pro, :method_name => :all)])
    end
  
    it "should match all possible methods on the specified objects." do
      pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :objects => [pub, pro], :methods => :all, :method_options => [:public, :protected, :exclude_ancestor_methods]
      pc.join_points_matched.size.should == 2
      pc.join_points_not_matched.size.should == 0
      pc.join_points_matched.should == Set.new([
          JoinPoint.new(:object => pro, :method_name => :protected_instance_test_method),
          JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
    end  
  
    Aspect::CANONICAL_OPTIONS["objects"].reject{|key| key.eql?("objects")}.each do |key|
      it "should accept :#{key} as a synonym for :objects." do
        pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
        pc = Pointcut.new key.intern => [pub, pro], :methods => :all, :method_options => [:public, :protected, :exclude_ancestor_methods]
        pc.join_points_matched.size.should == 2
        pc.join_points_not_matched.size.should == 0
        pc.join_points_matched.should == Set.new([
            JoinPoint.new(:object => pro, :method_name => :protected_instance_test_method),
            JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
      end  
    end
  
    it "does confuse strings specified with :objects as type names." do
      string = "mystring"
      expect { Pointcut.new :object => string, :methods => :capitalize }.to raise_error(NameError)
    end  
  
    it "does confuse symbols specified with :objects as type names." do
      symbol = :mystring
      expect { Pointcut.new :object => symbol, :methods => :capitalize }.to raise_error(NameError)
    end  
  end

  describe Pointcut, ".new (default_objects specified)" do
    it "should use the :default_objects if specified and no other :join_point, :type, or :object is given." do
      object1 = ClassWithPublicInstanceMethod.new
      pc = Pointcut.new :default_objects => object1, :method => :public_instance_test_method
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each {|jp| jp.type_or_object.should == object1}
    end

    it "should ignore the :default_objects if at least one other :object is given and the :default_objects are objects." do
      object1 = ClassWithPublicInstanceMethod.new
      object2 = ClassWithPublicInstanceMethod.new
      pc = Pointcut.new :default_objects => object1, :object => object2, :method => :public_instance_test_method
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each {|jp| jp.type_or_object.should == object2}
    end

    it "should ignore the :default_objects if at least one other :object is given and the :default_objects are types." do
      object = ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :default_objects => ClassWithPublicInstanceMethod, :object => object, :method => /_instance_test_method/, :method_options => [:public, :protected, :exclude_ancestor_methods]
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each {|jp| jp.type_or_object.should_not == ClassWithPublicInstanceMethod}
    end

    it "should ignore the :default_objects if at least one :join_point is given and the :default_objects are objects." do
      join_point = JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method => :protected_instance_test_method
      object = ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :default_objects => object, :join_point => join_point, :method => /_instance_test_method/, :method_options => [:public, :protected, :exclude_ancestor_methods]
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each {|jp| jp.type_or_object.should_not == ClassWithPublicInstanceMethod}
    end

    it "should ignore the :default_objects if at least one :pointcut is given and the :default_objects are types." do
      join_point = JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method => :protected_instance_test_method
      object = ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :default_objects => ClassWithPublicInstanceMethod, :join_point => join_point, :method => /_instance_test_method/, :method_options => [:public, :protected, :exclude_ancestor_methods]
      pc.join_points_matched.size.should == 1
      pc.join_points_matched.each {|jp| jp.type_or_object.should_not == ClassWithPublicInstanceMethod}
    end

    [:type, :type_and_descendents, :type_and_ancestors].each do |type_key|
      it "should ignore the :default_objects if at least one :#{type_key} is given and the :default_objects are objects." do
        object = ClassWithPublicInstanceMethod.new
        pc = Pointcut.new :default_objects => object, type_key => ClassWithProtectedInstanceMethod, :method => /_instance_test_method/, :method_options => [:public, :protected, :exclude_ancestor_methods]
        pc.join_points_matched.size.should == 1
        pc.join_points_matched.each {|jp| jp.type_or_object.should_not == ClassWithPublicInstanceMethod}
      end

      it "should ignore the :default_objects if at least one :#{type_key} is given and the :default_objects are types." do
        pc = Pointcut.new :default_objects => ClassWithPublicInstanceMethod, type_key => ClassWithProtectedInstanceMethod, :method => /_instance_test_method/, :method_options => [:public, :protected, :exclude_ancestor_methods]
        pc.join_points_matched.size.should == 1
        pc.join_points_matched.each {|jp| jp.type_or_object.should_not == ClassWithPublicInstanceMethod}
      end
    end

    Aspect::CANONICAL_OPTIONS["default_objects"].each do |key|
      it "should accept :#{key} as a synonym for :default_objects." do
        pc = Pointcut.new key.intern => ClassWithPublicInstanceMethod.new, :method => :public_instance_test_method
      end
    end
  end

  describe Pointcut, ".new (:exclude_types => types specified)" do
    before(:each) do
      before_exclude_spec
    end
  
    it "should remove from a list of explicitly-specified types the set of explicitly-specified excluded types." do
      pc = Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from a list of explicitly-specified types the set of excluded types specified by regular expression." do
      pc = Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_types => /Two$/, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from a list of explicitly-specified types the set of excluded types specified by name." do
      pc = Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the types specified by regular expression the explicitly-specified excluded types." do
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the types specified by regular expression the excluded types specified by regular expression." do
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_type => /Two$/, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the types specified by regular expression the excluded types specified by name." do
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the join points corresponding to the excluded types, specified by name." do
      pc = Pointcut.new :join_points => @all_type_jps, :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove the specified join points corresponding to the excluded types, specified by regular expression." do
      pc = Pointcut.new :join_points => @all_type_jps, :exclude_type => /Exclude.*Two/, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 2
      actual.should include(ExcludeTestOne)
      actual.should include(ExcludeTestThree)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should not add excluded types to the #not_matched results." do
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      pc.join_points_not_matched.size.should == 0
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_types"].reject{|key| key.eql?("exclude_types")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_types." do
        pc = Pointcut.new :types => /ExcludeTest/, key.intern => [ExcludeTestTwo, ExcludeTestThree], :method_options => :exclude_ancestor_methods
        actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
        actual.size.should == 1
        actual.should include(ExcludeTestOne)
        pc.join_points_not_matched.size.should == 0
      end
    end  
  end

  describe Pointcut, ".new (exclude types and their descendents and ancestors)" do
    before(:each) do
      before_pointcut_module_spec
    end

    def check_module_ancestors pc
      expected_types = [
        ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod, 
        ClassIncludingModuleWithPublicInstanceMethod,
        Kernel]
      found_types = {}
      pc.join_points_matched.each do |jp|
        next if ignored_join_point(jp)
        expected_types.should include(jp.target_type)
        found_types[jp.target_type] = true
      end
      found_types.size.should == 3
      not_expected_types = @expected_modules_not_matched_jps.map {|jp| jp.target_type}
      pc.join_points_not_matched.each do |jp|
        next if ignored_join_point(jp)
        not_expected_types.should include(jp.target_type)
      end
    end
  
    it "should exclude modules specified and their included modules when excluding ancestors." do
      pc = Pointcut.new :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_ancestors => ModuleIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_module_ancestors pc
    end
    it "should exclude join_points whose types match an excluded ancestor modules." do
      pc = Pointcut.new :join_point => @mimpub_jp, :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_ancestors => ModuleIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_module_ancestors pc
    end

    def check_module_descendents pc
      expected_types = [Kernel]
      found_types = {}
      pc.join_points_matched.each do |jp|
        next if ignored_join_point(jp)
        expected_types.should include(jp.target_type)
        found_types[jp.target_type] = true
      end
      found_types.size.should == 1
      not_expected_types = @expected_modules_not_matched_jps.map {|jp| jp.target_type}
      pc.join_points_not_matched.each do |jp|
        next if ignored_join_point(jp)
        not_expected_types.should include(jp.target_type)
      end
    end
  
    it "should exclude modules specified and their including modules and classes when excluding descendents." do
      pc = Pointcut.new :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_descendents => ModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_module_descendents pc
    end
    it "should exclude join_points whose types match an excluded descendent modules." do
      pc = Pointcut.new :join_point => @mpub_jp, :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_descendents => ModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_module_descendents pc
    end

    def check_class_ancestors pc
      expected_types = [ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod, ModuleIncludingModuleWithPublicInstanceMethod]
      found_types = {}
      pc.join_points_matched.each do |jp|
        next if ignored_join_point(jp)
        expected_types.should include(jp.target_type)
        found_types[jp.target_type] = true
      end
      found_types.size.should == 2
      not_expected_types = @expected_modules_not_matched_jps.map {|jp| jp.target_type}
      pc.join_points_not_matched.each do |jp|
        next if ignored_join_point(jp)
        not_expected_types.should include(jp.target_type)
      end
    end
  
    it "should exclude classes specified and their included modules and ancestor classes when excluding ancestors." do
      pc = Pointcut.new :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_ancestors => ClassIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_class_ancestors pc
    end
    it "should exclude join_points whose types match an excluded ancestor classes." do
      pc = Pointcut.new :join_point => @cimpub_jp, :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_ancestors => ClassIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_class_ancestors pc
    end
  
    def check_class_descendents pc
      expected_types = [Kernel, ModuleIncludingModuleWithPublicInstanceMethod, ModuleWithPublicInstanceMethod]
      found_types = {}
      pc.join_points_matched.each do |jp|
        next if ignored_join_point(jp)
        expected_types.should include(jp.target_type)
        found_types[jp.target_type] = true
      end
      found_types.size.should == 3
      not_expected_types = @expected_modules_not_matched_jps.map {|jp| jp.target_type}
      pc.join_points_not_matched.each do |jp|
        next if ignored_join_point(jp)
        not_expected_types.should include(jp.target_type)
      end
    end
  
    it "should exclude classes specified and their including modules and descendent classes when excluding descendents." do
      pc = Pointcut.new :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_descendents => ClassIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_class_descendents pc
    end
    it "should exclude join_points whose types match an excluded descendent types." do
      pc = Pointcut.new :join_point => @cimpub_jp, :types_and_ancestors => /^Class(Including|DerivedFrom).*Method/, 
      :exclude_types_and_descendents => ClassIncludingModuleWithPublicInstanceMethod, :methods => :all, :method_options => :exclude_ancestor_methods
      check_class_descendents pc
    end

    Aspect::CANONICAL_OPTIONS["exclude_types_and_descendents"].reject{|key| key.eql?("exclude_types_and_descendents")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_descendents." do
        expect {Pointcut.new :types => /ExcludeTest/, key.intern => [ExcludeTestTwo, ExcludeTestThree], :method_options => :exclude_ancestor_methods, :noop => true}.not_to raise_error
      end
    end  

    Aspect::CANONICAL_OPTIONS["exclude_types_and_ancestors"].reject{|key| key.eql?("exclude_types_and_ancestors")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_types_and_ancestors." do
        expect {Pointcut.new :types => /ExcludeTest/, key.intern => [ExcludeTestTwo, ExcludeTestThree], :method_options => :exclude_ancestor_methods, :noop => true}.not_to raise_error
      end
    end  
  end
  
  describe Pointcut, ".new (:exclude_objects => objects specified)" do
    before(:each) do
      @e11 = ExcludeTestOne.new  
      @e12 = ExcludeTestOne.new  
      @e21 = ExcludeTestTwo.new  
      @e22 = ExcludeTestTwo.new  
      @e31 = ExcludeTestThree.new  
      @e32 = ExcludeTestThree.new  
      @objects = [@e11, @e12, @e21, @e22, @e31, @e32]
    end
  
    it "should remove from the matched objects the excluded objects." do
      pc = Pointcut.new :objects => @objects, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      actual.size.should == 4
      [@e11, @e12, @e21, @e32].each {|e| actual.should include(e)}
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove the specified join points corresponding to the excluded objects." do
      jps11 = JoinPoint.new :object => @e11, :method => :method11
      jps21 = JoinPoint.new :object => @e21, :method => :method21
      jps22 = JoinPoint.new :object => @e22, :method => :method22
      jps31 = JoinPoint.new :object => @e31, :method => :method31
      jps = [jps11, jps21, jps22, jps31]
      pc = Pointcut.new :join_points => jps, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 2
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      [@e11, @e21].each {|e| actual.should include(e)}
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should not add excluded objects to the #not_matched results." do
      pc = Pointcut.new :objects => @objects, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
      actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
      pc.join_points_not_matched.size.should == 0
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_objects"].reject{|key| key.eql?("exclude_objects")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_objects." do
        pc = Pointcut.new :objects => @objects, key.intern => @e22, :method_options => :exclude_ancestor_methods
        actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
        actual.size.should == 5
        [@e11, @e12, @e21, @e31, @e32].each {|e| actual.should include(e)}
        pc.join_points_not_matched.size.should == 0
      end
    end
  end

  describe Pointcut, ".new (:exclude_join_points => join_points specified)" do
    before(:each) do
      before_exclude_spec
    end

    it "should remove from a list of explicitly-specified join points the set of explicitly-specified excluded join points." do
      excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
      expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
      pc = Pointcut.new :join_points => @all_jps, :exclude_join_points => excluded
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the list of generated, type-based join points the set of explicitly-specified excluded join points." do
      excluded = [@jp11, @jp22, @jp33]
      expected = [@jp12, @jp13, @jp21, @jp23, @jp31, @jp32]
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_join_points => excluded, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end

    it "should remove from the list of generated, object-based join points the set of explicitly-specified excluded join points." do
      excluded = [@ojp12, @ojp23, @ojp31]  
      expected = [@ojp11, @ojp13, @ojp21, @ojp22, @ojp32, @ojp33]
      pc = Pointcut.new :objects => [@et1, @et2, @et3], :exclude_join_points => excluded, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should not add excluded types to the #not_matched results." do
      excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
      pc = Pointcut.new :join_points => @all_jps, :exclude_join_points => excluded
      pc.join_points_not_matched.size.should == 0
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_join_points"].reject{|key| key.eql?("exclude_join_points")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_join_points." do
        excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
        expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
        pc = Pointcut.new :join_points => @all_jps, key.intern => excluded
        pc.join_points_matched.should == Set.new(expected)
        pc.join_points_not_matched.size.should == 0
      end
    end
  end

  describe Pointcut, ".new (:exclude_pointcuts => pointcuts specified)" do
    before(:each) do
      before_exclude_spec
    end

    it "should remove from a list of explicitly-specified join points the set of explicitly-specified excluded pointcuts." do
      excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
      excluded = Pointcut.new :join_points => excluded_jps
      expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
      pc = Pointcut.new :join_points => @all_jps, :exclude_pointcuts => excluded
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the list of generated, type-based join points the set of explicitly-specified excluded pointcuts." do
      excluded_jps = [@jp11, @jp22, @jp33]
      excluded = Pointcut.new :join_points => excluded_jps
      expected = [@jp12, @jp13, @jp21, @jp23, @jp31, @jp32]
      pc = Pointcut.new :types => /ExcludeTest/, :exclude_pointcuts => excluded, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove from the list of generated, object-based join points the set of explicitly-specified excluded pointcuts." do
      excluded_jps = [@ojp12, @ojp23, @ojp31]  
      excluded = Pointcut.new :join_points => excluded_jps
      expected = [@ojp11, @ojp13, @ojp21, @ojp22, @ojp32, @ojp33]
      pc = Pointcut.new :objects => [@et1, @et2, @et3], :exclude_pointcuts => excluded, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.should == Set.new(expected)
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should not add excluded types to the #not_matched results." do
      excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
      excluded = Pointcut.new :join_points => excluded_jps
      pc = Pointcut.new :join_points => @all_jps, :exclude_pointcuts => excluded
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should result in an empty pointcut if the join points in the :exclude_pointcuts are a superset of the matched join points." do
      excluded = Pointcut.new :join_points => @all_jps
      pc = Pointcut.new :join_points => @all_jps, :exclude_pointcut => excluded
      pc.join_points_matched.size.should == 0
      pc.join_points_not_matched.size.should == 0
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_pointcuts"].reject{|key| key.eql?("exclude_pointcuts")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_pointcuts." do
        excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
        excluded = Pointcut.new :join_points => excluded_jps
        expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
        pc = Pointcut.new :join_points => @all_jps, key.intern => excluded
        pc.join_points_matched.should == Set.new(expected)
        pc.join_points_not_matched.size.should == 0
      end
    end
  end

  describe Pointcut, ".new (:method_options synonyms)" do
    before(:each) do
      before_pointcut_class_spec
    end

    Aspect::CANONICAL_OPTIONS["method_options"].reject{|key| key.eql?("method_options")}.each do |key|
      it "should accept :#{key} as a synonym for :method_options." do
        pc = Pointcut.new :types => ClassWithPublicInstanceMethod, key.intern => [:public, :instance, :exclude_ancestor_methods]
        pc.join_points_matched.should be_eql(Set.new([@pub_jp]))
        pc.join_points_not_matched.size.should == 0
      end
    end  
  end

  describe Pointcut, ".new (types or objects specified with public instance methods)" do
    before(:each) do
      before_pointcut_class_spec
    end

    it "should support MethodFinder's :public and :instance options for the specified types." do
      pc = Pointcut.new :types => ClassWithPublicInstanceMethod, :method_options => [:public, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([@pub_jp]))
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should support MethodFinder's :public and :instance options for the specified objects." do
      pub = ClassWithPublicInstanceMethod.new
      pc = Pointcut.new :objects => pub, :method_options => [:public, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)]))
      pc.join_points_not_matched.size.should == 0
    end
  end

  describe Pointcut, ".new (types or objects specified with protected instance methods)" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should support MethodFinder's :protected and :instance options for the specified types." do
      pc = Pointcut.new :types => ClassWithProtectedInstanceMethod, :method_options => [:protected, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([@pro_jp]))
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should support MethodFinder's :protected and :instance options for the specified objects." do
      pro = ClassWithProtectedInstanceMethod.new
      pc = Pointcut.new :objects => pro, :method_options => [:protected, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([JoinPoint.new(:object => pro, :method_name => :protected_instance_test_method)]))
      pc.join_points_not_matched.size.should == 0
    end
  end

  describe Pointcut, ".new (types or objects specified with private instance methods)" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should support MethodFinder's :private and :instance options for the specified types." do
      pc = Pointcut.new :types => ClassWithPrivateInstanceMethod, :method_options => [:private, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([@pri_jp]))
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should support MethodFinder's :private and :instance options for the specified objects." do
      pro = ClassWithPrivateInstanceMethod.new
      pc = Pointcut.new :objects => pro, :method_options => [:private, :instance, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([JoinPoint.new(:object => pro, :method_name => :private_instance_test_method)]))
      pc.join_points_not_matched.size.should == 0
    end
  end

  describe Pointcut, ".new (types or objects specified with public class methods)" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should support MethodFinder's :public and :class options for the specified types." do
      pc = Pointcut.new :types => ClassWithPublicClassMethod, :method_options => [:public, :class, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([@cpub_jp]))
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should support MethodFinder's :public and :class options for the specified objects, which will return no methods." do
      pub = ClassWithPublicInstanceMethod.new
      pc = Pointcut.new :objects => pub, :method_options => [:public, :class, :exclude_ancestor_methods]
      pc.join_points_matched.size.should == 0
      pc.join_points_not_matched.size.should == 1
      pc.join_points_not_matched.should be_eql(Set.new([JoinPoint.new(:object => pub, :method_name => :all, :class_method => true)]))
    end
  end

  describe Pointcut, ".new (types or objects specified with private class methods)" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should support MethodFinder's :private and :class options for the specified types." do
      pc = Pointcut.new :types => ClassWithPrivateClassMethod, :method_options => [:private, :class, :exclude_ancestor_methods]
      pc.join_points_matched.should be_eql(Set.new([@cpri_jp]))
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should support MethodFinder's :private and :class options for the specified objects, which will return no methods." do
      pri = ClassWithPrivateInstanceMethod.new
      pc = Pointcut.new :objects => pri, :method_options => [:private, :class, :exclude_ancestor_methods]
      pc.join_points_not_matched.should be_eql(Set.new([JoinPoint.new(:object => pri, :method_name => :all, :class_method => true)]))
      pc.join_points_not_matched.size.should == 1
    end
  end

  describe Pointcut, ".new (types or objects specified with method regular expressions)" do
    before(:each) do
      before_pointcut_class_spec
      @jp_rwe = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r   = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
      @object_of_ClassWithAttribs = ClassWithAttribs.new
      @jp_rwe_o = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r_o   = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
    end
  
    it "should match on public method readers and writers for type names by default." do
      pc = Pointcut.new :types => "ClassWithAttribs", :methods => [/^attr/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public method readers and writers for types by default." do
      pc = Pointcut.new :types => ClassWithAttribs, :methods => [/^attr/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public method readers and writers for objects by default." do
      pc = Pointcut.new :object => @object_of_ClassWithAttribs, :methods => [/^attr/]
      pc.join_points_matched.should == @expected_for_objects
    end
  end

  describe Pointcut, ".new (synonyms of :methods)" do
    before(:each) do
      before_pointcut_class_spec
      @jp_rwe = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r   = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
      @object_of_ClassWithAttribs = ClassWithAttribs.new
      @jp_rwe_o = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r_o   = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
    end
  
    Aspect::CANONICAL_OPTIONS["methods"].reject{|key| key.eql?("methods")}.each do |key|
      it "should accept :#{key} as a synonym for :methods." do
        pc = Pointcut.new :types => "ClassWithAttribs", key.intern => [/^attr/]
        pc.join_points_matched.should == @expected_for_types
      end
    end  
  end

  describe Pointcut, ".new (:exclude_methods => methods specified)" do
    before(:each) do
      before_exclude_spec
    end
  
    it "should remove type-specified JoinPoints matching the excluded methods specified by name." do
      pc = Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 7
      pc.join_points_matched.should == Set.new([@jp12, @jp13, @jp21, @jp22, @jp31, @jp32, @jp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove type-specified JoinPoints matching the excluded methods specified by regular expression." do
      pc = Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 5
      pc.join_points_matched.should == Set.new([@jp12, @jp22, @jp31, @jp32, @jp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove object-specified JoinPoints matching the excluded methods specified by name." do
      pc = Pointcut.new :objects => [@et1, @et2, @et3], :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 7
      pc.join_points_matched.should == Set.new([@ojp12, @ojp13, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove object-specified JoinPoints matching the excluded methods specified by regular expression." do
      pc = Pointcut.new :objects => [@et1, @et2, @et3], :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 5
      pc.join_points_matched.should == Set.new([@ojp12, @ojp22, @ojp31, @ojp32, @ojp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove join-point-specified JoinPoints matching the excluded methods specified by name." do
      pc = Pointcut.new :join_points => @all_jps, :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 14
      pc.join_points_matched.should == Set.new([@jp12, @jp13, @jp21, @jp22, @jp31, @jp32, @jp33, @ojp12, @ojp13, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    it "should remove join-point-specified JoinPoints matching the excluded methods specified by regular expression." do
      pc = Pointcut.new :join_points => @all_jps, :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
      pc.join_points_matched.size.should == 10
      pc.join_points_matched.should == Set.new([@jp12, @jp22, @jp31, @jp32, @jp33, @ojp12, @ojp22, @ojp31, @ojp32, @ojp33])
      pc.join_points_not_matched.size.should == 0
    end
  
    Aspect::CANONICAL_OPTIONS["exclude_methods"].reject{|key| key.eql?("exclude_methods")}.each do |key|
      it "should accept :#{key} as a synonym for :exclude_methods." do
        pc = Pointcut.new :join_points => @all_jps, key.intern => /method[12][13]/, :method_options => :exclude_ancestor_methods
        pc.join_points_matched.size.should == 10
        pc.join_points_matched.should == Set.new([@jp12, @jp22, @jp31, @jp32, @jp33, @ojp12, @ojp22, @ojp31, @ojp32, @ojp33])
        pc.join_points_not_matched.size.should == 0
      end
    end
  end
  
  describe Pointcut, ".new (types or objects specified with attribute regular expressions)" do
    before(:each) do
      before_pointcut_class_spec
      @jp_rwe = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r   = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
      @object_of_ClassWithAttribs = ClassWithAttribs.new
      @jp_rwe_o = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r_o   = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
    end
  
    it "should match on public attribute readers and writers for type names by default." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/]
      pc.join_points_matched.size.should == 4
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public attribute readers and writers for types by default." do
      pc = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public attribute readers and writers for objects by default." do
      pc = Pointcut.new :object => @object_of_ClassWithAttribs, :attributes => [/^attr/]
      pc.join_points_matched.should == @expected_for_objects
    end
  
    it "should match attribute specifications for types that are prefixed with @." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^@attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match attribute specifications for objects that are prefixed with @." do
      pc = Pointcut.new :object => @object_of_ClassWithAttribs, :attributes => [/^@attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_objects
    end
  
    it "should match attribute specifications that are regular expressions of symbols." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match attribute specifications for objects that are regular expressions of symbols." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match public attribute readers and writers for types when both the :readers and :writers options are specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:readers, :writers]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match public attribute readers and writers for objects when both the :readers and :writers options are specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:readers, :writers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match public attribute readers for types only when the :readers option is specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:readers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match public attribute readers for objects only when the :readers option is specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:readers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match public attribute writers for types only when the :writers option is specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:writers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match public attribute writers for objects only when the :writers option is specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:writers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute writers for types whether or not the attributes specification ends with an equal sign." do
      pc = Pointcut.new :types => "ClassWithAttribs", 
        :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:writers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
      pc2 = Pointcut.new :types => "ClassWithAttribs", 
        :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:writers]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute writers for objects whether or not the attributes specification ends with an equal sign." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:writers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
      pc2 = Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:writers]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute readers for types when the :readers option is specified even if the attributes specification ends with an equal sign!" do
      pc = Pointcut.new :types => "ClassWithAttribs", 
        :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
      pc2 = Pointcut.new :types => "ClassWithAttribs", 
        :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match attribute readers for objects when the :readers option is specified even if the attributes specification ends with an equal sign!" do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
      pc2 = Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:readers]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
    end  
  end

  describe Pointcut, ".new (types or objects specified with :accessing regular expressions)" do
    before(:each) do
      before_pointcut_class_spec
      @jp_rwe = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r   = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
      @object_of_ClassWithAttribs = ClassWithAttribs.new
      @jp_rwe_o = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r_o   = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
    end
  
    it "should match on public attribute readers and writers for type names by default." do
      pc = Pointcut.new :types => "ClassWithAttribs", :accessing => [/^attr/]
      pc.join_points_matched.size.should == 4
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public attribute readers and writers for types by default." do
      pc = Pointcut.new :types => ClassWithAttribs, :accessing => [/^attr/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match on public attribute readers and writers for objects by default." do
      pc = Pointcut.new :object => @object_of_ClassWithAttribs, :accessing => [/^attr/]
      pc.join_points_matched.should == @expected_for_objects
    end
  
    it "should match attribute specifications for types that are prefixed with @." do
      pc = Pointcut.new :types => "ClassWithAttribs", :accessing => [/^@attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match attribute specifications for objects that are prefixed with @." do
      pc = Pointcut.new :object => @object_of_ClassWithAttribs, :accessing => [/^@attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_objects
    end
  
    it "should match attribute specifications that are regular expressions of symbols." do
      pc = Pointcut.new :types => "ClassWithAttribs", :accessing => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match attribute specifications for objects that are regular expressions of symbols." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :accessing => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  end
  
  describe Pointcut, ".new (types or objects specified with reading and/or writing regular expressions)" do
    before(:each) do
      before_pointcut_class_spec
      @jp_rwe = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we  = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r   = JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
      @object_of_ClassWithAttribs = ClassWithAttribs.new
      @jp_rwe_o = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
      @jp_rw_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
      @jp_we_o  = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
      @jp_r_o   = JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
      @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
    end
  
    it "should only allow :reading and :writing options together if they specify the same attributes." do
      expect {Pointcut.new :types => "ClassWithAttribs", :reading => [/^attrRW_ClassWithAttribs/], :writing => [/^attr.*ClassWithAttribs/]}.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should match public attribute readers and writers for types when both the :reading and :writing options are specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :reading => [/^attr.*ClassWithAttribs/], :writing => [/^attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match public attribute readers and writers for types when both the :reading and :changing options are specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :reading => [/^attr.*ClassWithAttribs/], :changing => [/^attr.*ClassWithAttribs/]
      pc.join_points_matched.should == @expected_for_types
    end
  
    it "should match public attribute readers and writers for objects when both the :reading and :writing options are specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :reading => [/^attr.*ClassWithAttribs/], :writing => [/^attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match public attribute readers for types only when the :reading option is specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :reading => [/^attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match public attribute readers for objects only when the :reading option is specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :reading => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match public attribute writers for types only when the :writing option is specified." do
      pc = Pointcut.new :types => "ClassWithAttribs", :writing => [/^attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match public attribute writers for objects only when the :writing option is specified." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :writing => [/^:attr.*ClassWithAttribs/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute writers for types whether or not the attributes specification ends with an equal sign." do
      pc = Pointcut.new :types => "ClassWithAttribs", :writing => [/^attr[RW]+_ClassWithAttribs=/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
      pc2 = Pointcut.new :types => "ClassWithAttribs", :writing => [/^attr[RW]+_ClassWithAttribs/]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute writers for objects whether or not the attributes specification ends with an equal sign." do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :writing => [/^attr[RW]+_ClassWithAttribs=/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
      pc2 = Pointcut.new :object => object, :writing => [/^attr[RW]+_ClassWithAttribs/]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
        JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    end
  
    it "should match attribute readers for types when the :reading option is specified even if the attributes specification ends with an equal sign!" do
      pc = Pointcut.new :types => "ClassWithAttribs", :reading => [/^attr[RW]+_ClassWithAttribs=/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
      pc2 = Pointcut.new :types => "ClassWithAttribs", :reading => [/^attr[RW]+_ClassWithAttribs=/]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
    end
  
    it "should match attribute readers for objects when the :reading option is specified even if the attributes specification ends with an equal sign!" do
      object = ClassWithAttribs.new
      pc = Pointcut.new :object => object, :reading => [/^attr[RW]+_ClassWithAttribs=/]
      pc.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
      pc2 = Pointcut.new :object => object, :reading => [/^attr[RW]+_ClassWithAttribs/]
      pc2.join_points_matched.should == Set.new([
        JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
        JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
    end  
  end

  describe Pointcut, ".new (join points specified)" do
    before(:each) do
      before_pointcut_class_spec
      @anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
      @expected_matched = [@pub_jp, @pro_jp, @pri_jp, @cpub_jp, @cpri_jp,
          JoinPoint.new(:object => @anClassWithPublicInstanceMethod, :method => :public_instance_test_method)]
      @expected_not_matched = [
        JoinPoint.new(:type   => ClassWithPublicInstanceMethod,    :method => :foo),
        JoinPoint.new(:object => @anClassWithPublicInstanceMethod, :method => :foo)]
    end

    it "should return matches only for existing join points." do
      pc = Pointcut.new :join_points => (@expected_matched + @expected_not_matched)
      pc.join_points_matched.should == Set.new(@expected_matched)
    end

    it "should return non-matches for non-existing join points." do
      pc = Pointcut.new :join_points => (@expected_matched + @expected_not_matched)
      pc.join_points_not_matched.should == Set.new(@expected_not_matched)
    end

    it "should ignore :methods and :method_options for the join points specified." do
      pc = Pointcut.new :join_points => (@expected_matched + @expected_not_matched),
        :methods => :kind_of?, :method_options => [:class]
      pc.join_points_matched.should == Set.new(@expected_matched)
      pc.join_points_not_matched.should == Set.new(@expected_not_matched)
    end

    it "should ignore :attributes and :attribute_options for the join points specified." do
      pc = Pointcut.new :join_points => (@expected_matched + @expected_not_matched),
        :attributes => :name, :attribute_options => [:readers]
      pc.join_points_matched.should == Set.new(@expected_matched)
      pc.join_points_not_matched.should == Set.new(@expected_not_matched)
    end

    it "should ignore :accessing, :reading, and :writing for the join points specified." do
      pc = Pointcut.new :join_points => (@expected_matched + @expected_not_matched),
        :accessing => :name, :reading => :name, :writing => :name
      pc.join_points_matched.should == Set.new(@expected_matched)
      pc.join_points_not_matched.should == Set.new(@expected_not_matched)
    end
  end

  class ClassWithFunkyMethodNames
    def huh?; true; end
    def yes!; true; end
    def x= other; false; end
    def == other; false; end
    def =~ other; false; end
  end
  
  describe Pointcut, ".new (methods that end in non-alphanumeric characters)" do
    before(:each) do
      @funky = ClassWithFunkyMethodNames.new
    end  

    {'?' => :huh?, '!' => :yes!, '=' => :x=}.each do |char, method|
      it "should match instance methods for types when searching for names that end with a '#{char}' character." do
        pc = Pointcut.new :types => ClassWithFunkyMethodNames, :method => method, :method_options => [:exclude_ancestor_methods]
        expected_jp = JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end

      it "should match instance methods for objects when searching for names that end with a '#{char}' character." do
        pc = Pointcut.new :object => @funky, :method => method, :method_options => [:exclude_ancestor_methods]
        expected_jp = JoinPoint.new :object => @funky, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end

      it "should match instance methods for types when searching for names that end with a '#{char}' character, using a regular expressions." do
        pc = Pointcut.new :types => ClassWithFunkyMethodNames, :methods => /#{Regexp.escape(char)}$/, :method_options => [:exclude_ancestor_methods]
        expected_jp = JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end

      it "should match instance methods for object when searching for names that end with a '#{char}' character, using a regular expressions." do
        pc = Pointcut.new :object => @funky, :methods => /#{Regexp.escape(char)}$/, :method_options => [:exclude_ancestor_methods]
        expected_jp = JoinPoint.new :object => @funky, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end
    end

    {'=' => :==, '~' => :=~}.each do |char, method|
      it "should match the #{method} instance method for types, if you don't suppress ancestor methods, even if the method is defined in the class!" do
        pc = Pointcut.new :types => ClassWithFunkyMethodNames, :method => method, :method_options => [:instance]
        expected_jp = JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end
  
      it "should match the #{method} instance method for objects, if you don't suppress ancestor methods, even if the method is defined in the class!" do
        pc = Pointcut.new :object => @funky, :method => method, :method_options => [:instance]
        expected_jp = JoinPoint.new :object => @funky, :method_name => method
        pc.join_points_matched.should == Set.new([expected_jp])
      end

      it "should match the #{method} instance method for types when using a regular expressions, if you don't suppress ancestor methods, even if the method is defined in the class!" do
        pc = Pointcut.new :types => ClassWithFunkyMethodNames, :methods => /#{Regexp.escape(char)}$/, :method_options => [:instance]
        pc.join_points_matched.any? {|jp| jp.method_name == method}.should be_true
      end

      it "should match the #{method} instance method for objects when using a regular expressions, if you don't suppress ancestor methods, even if the method is defined in the class!" do
        pc = Pointcut.new :object => @funky, :methods => /#{Regexp.escape(char)}$/, :method_options => [:instance]
        pc.join_points_matched.any? {|jp| jp.method_name == method}.should be_true
      end
    end
  end
  
  describe Pointcut, ".new (:attributes => :all option not yet supported)" do
    it "should raise if :all is used for types (not yet supported)." do
      expect { Pointcut.new :types => "ClassWithAttribs", :attributes => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should raise if :all is used for objects (not yet supported)." do
      expect { Pointcut.new :object => ClassWithAttribs.new, :attributes => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (:accessing => :all option not yet supported)" do
    it "should raise if :all is used for types (not yet supported)." do
      expect { Pointcut.new :types => "ClassWithAttribs", :accessing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should raise if :all is used for objects (not yet supported)." do
      expect { Pointcut.new :object => ClassWithAttribs.new, :accessing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (:changing => :all option not yet supported)" do
    it "should raise if :all is used for types (not yet supported)." do
      expect { Pointcut.new :types => "ClassWithAttribs", :changing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should raise if :all is used for objects (not yet supported)." do
      expect { Pointcut.new :object => ClassWithAttribs.new, :changing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (:reading => :all option not yet supported)" do
    it "should raise if :all is used for types (not yet supported)." do
      expect { Pointcut.new :types => "ClassWithAttribs", :reading => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should raise if :all is used for objects (not yet supported)." do
      expect { Pointcut.new :object => ClassWithAttribs.new, :reading => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (:writing => :all option not yet supported)" do
    it "should raise if :all is used for types (not yet supported)." do
      expect { Pointcut.new :types => "ClassWithAttribs", :writing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  
    it "should raise if :all is used for objects (not yet supported)." do
      expect { Pointcut.new :object => ClassWithAttribs.new, :writing => :all }.to raise_error(Aquarium::Utils::InvalidOptions)
    end
  end

  describe Pointcut, ".new (singletons specified)" do
  
    before(:each) do
      class Empty; end

      @objectWithSingletonMethod = Empty.new
      class << @objectWithSingletonMethod
        def a_singleton_method
        end
      end
    
      class NotQuiteEmpty
      end
      class << NotQuiteEmpty
        def a_class_singleton_method
        end
      end
      @notQuiteEmpty = NotQuiteEmpty.new
    end  

    it "should find instance-level singleton method joinpoints for objects when :singleton is specified." do
      pc = Pointcut.new :objects => [@notQuiteEmpty, @objectWithSingletonMethod], :methods => :all, :method_options => [:singleton]
      pc.join_points_matched.should == Set.new([JoinPoint.new(:object => @objectWithSingletonMethod, :method_name => :a_singleton_method)])
      pc.join_points_not_matched.should == Set.new([JoinPoint.new(:object => @notQuiteEmpty, :method_name => :all)])
    end    
  
    it "should find type-level singleton methods for types when :singleton is specified." do
      pc = Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :exclude_ancestor_methods]
      pc.join_points_matched.should == Set.new([JoinPoint.new(:type => NotQuiteEmpty, :method_name => :a_class_singleton_method)])
      pc.join_points_not_matched.should == Set.new([JoinPoint.new(:type => Empty, :method_name => :all)])
    end
  
    it "should raise when specifying method options :singleton with :class, :public, :protected, or :private." do
      expect { Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :class]}.to     raise_error(Aquarium::Utils::InvalidOptions)
      expect { Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :public]}.to    raise_error(Aquarium::Utils::InvalidOptions)
      expect { Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :protected]}.to raise_error(Aquarium::Utils::InvalidOptions)
      expect { Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :private]}.to    raise_error(Aquarium::Utils::InvalidOptions)
    end    
  end
  
  describe Pointcut, "#empty?" do
    it "should be true if there are no matched and no unmatched join points." do
      pc = Pointcut.new
      pc.join_points_matched.size.should == 0
      pc.join_points_not_matched.size.should == 0
      pc.should be_empty
    end
  
    it "should be false if there are matched join points." do
      pc = Pointcut.new :types => [ClassWithAttribs], :methods => [/^attr/]
      pc.join_points_matched.size.should > 0
      pc.join_points_not_matched.size.should == 0
      pc.should_not be_empty
    end
  
    it "should be false if there are unmatched join points." do
      pc = Pointcut.new :types => [String], :methods => [/^attr/]
      pc.join_points_matched.size.should == 0
      pc.join_points_not_matched.size.should > 0
      pc.should_not be_empty
    end
  end

  describe Pointcut, "#eql?" do  
    it "should return true for the same Pointcut object." do
      pc = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc.should be_eql(pc)
      pc1 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
      pc1.should be_eql(pc1)
    end
  
    it "should return true for Pointcuts that specify the same types and methods." do
      pc1 = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc2 = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc1.should be_eql(pc2)
    end
  
    it "should return false if the matched types are different." do
      pc1 = Pointcut.new  :types => /ClassWithPublicMethod/
      pc2 = Pointcut.new  :types => /Class.*Method/
      pc1.should_not eql(pc2)
    end
  
    it "should return false for Pointcuts that specify different types, even if no methods match." do
      pc1 = Pointcut.new  :types => /ClassWithPublicMethod/, :methods => /foobar/
      pc2 = Pointcut.new  :types => /Class.*Method/        , :methods => /foobar/
      pc1.should_not eql(pc2)
    end
  
    it "should return false for Pointcuts that specify different methods." do
      pc1 = Pointcut.new  :types => /ClassWithPublicMethod/, :methods =>/^private/
      pc2 = Pointcut.new  :types => /ClassWithPublicMethod/, :methods =>/^public/
      pc1.should_not eql(pc2)
    end
  
    it "should return false for Pointcuts that specify equivalent objects that are not the same object." do
      pc1 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
      pc2 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
      pc1.should_not eql(pc2)
    end
  
    it "should return false for Pointcuts that specify equivalent objects that are not the same object, even if no methods match." do
      pc1 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /foobar/
      pc2 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /foobar/
      pc1.should_not eql(pc2)
    end
  
    it "should return false if the matched objects are different objects." do
      pc1 = Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
      pc2 = Pointcut.new  :object => ClassWithPrivateClassMethod.new, :methods => /_test_method$/
      pc1.should_not eql(pc2)
    end

    it "should return true if the matched objects are the same object." do
      object = ClassWithPublicClassMethod.new
      pc1 = Pointcut.new  :object => object, :methods => /_test_method$/
      pc2 = Pointcut.new  :object => object, :methods => /_test_method$/
      pc1.should eql(pc2)
    end

    it "should return false if the not_matched types are different." do
      pc1 = Pointcut.new  :types => :UnknownFoo
      pc2 = Pointcut.new  :types => :UnknownBar
      pc1.should_not eql(pc2)
    end

    it "should return false if the matched methods for the same types are different." do
      pc1 = Pointcut.new  :types => /Class.*Method/, :methods => /public.*_test_method$/
      pc2 = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc1.should_not == pc2
    end

    it "should return false if the matched methods for the same objects are different." do
      pub = ClassWithPublicInstanceMethod.new
      pri = ClassWithPrivateInstanceMethod.new
      pc1 = Pointcut.new  :objects => [pub, pri], :methods => /public.*_test_method$/
      pc2 = Pointcut.new  :objects => [pub, pri], :methods => /_test_method$/
      pc1.should_not == pc2
    end

    it "should return false if the not_matched methods for the same types are different." do
      pc1 = Pointcut.new  :types => /Class.*Method/, :methods => /foo/
      pc2 = Pointcut.new  :types => /Class.*Method/, :methods => /bar/
      pc1.should_not == pc2
    end

    it "should return false if the not_matched methods for the same objects are different." do
      pub = ClassWithPublicInstanceMethod.new
      pri = ClassWithPrivateInstanceMethod.new
      pc1 = Pointcut.new  :objects => [pub, pri], :methods => /foo/
      pc2 = Pointcut.new  :objects => [pub, pri], :methods => /bar/
      pc1.should_not == pc2
    end

    it "should return false if the matched attributes for the same types are different." do
      pc1 = Pointcut.new  :types => /Class.*Method/, :attributes => /attrRW/
      pc2 = Pointcut.new  :types => /Class.*Method/, :attributes => /attrR/
      pc1.should_not == pc2
    end

    it "should return false if the matched attributes for the same objects are different." do
      pub = ClassWithPublicInstanceMethod.new
      pri = ClassWithPrivateInstanceMethod.new
      pc1 = Pointcut.new  :objects => [pub, pri], :attributes => /attrRW/
      pc2 = Pointcut.new  :objects => [pub, pri], :attributes => /attrR/
      pc1.should_not == pc2
    end

    it "should return false if the not_matched attributes for the same types are different." do
      pc1 = Pointcut.new  :types => /Class.*Method/, :attributes => /foo/
      pc2 = Pointcut.new  :types => /Class.*Method/, :attributes => /bar/
      pc1.should_not == pc2
    end

    it "should return false if the not_matched attributes for the same objects are different." do
      pub = ClassWithPublicInstanceMethod.new
      pri = ClassWithPrivateInstanceMethod.new
      pc1 = Pointcut.new  :objects => [pub, pri], :attributes => /foo/
      pc2 = Pointcut.new  :objects => [pub, pri], :attributes => /bar/
      pc1.should_not == pc2
    end
  end

  describe "Pointcut#eql?" do
    it "should be an alias for #==" do
      pc1 = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc2 = Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
      pc3 = Pointcut.new  :objects => [ClassWithPublicInstanceMethod.new, ClassWithPublicInstanceMethod.new]
      
      pc1.should be_eql(pc1)
      pc1.should be_eql(pc2)
      pc1.should_not eql(pc3)
      pc2.should_not eql(pc3)
    end
  end

  describe Pointcut, "#candidate_types" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should return only candidate matching types when the input types exist." do
      pc = Pointcut.new :types => @example_classes 
      pc.candidate_types.matched_keys.sort {|x,y| x.to_s <=> y.to_s}.should == @example_classes.sort {|x,y| x.to_s <=> y.to_s}
      pc.candidate_types.not_matched_keys.should == []
    end

    it "should return only candidate matching types when the input type names correspond to existing types." do
      pc = Pointcut.new :types => @example_classes.map {|t| t.to_s}
      pc.candidate_types.matched_keys.sort {|x,y| x.to_s <=> y.to_s}.should == @example_classes.sort {|x,y| x.to_s <=> y.to_s}
      pc.candidate_types.not_matched_keys.should == []
    end

    it "should return only candidate non-matching types when the input types do not exist." do
      pc = Pointcut.new :types => 'NonExistentClass'
      pc.candidate_types.matched_keys.should == []
      pc.candidate_types.not_matched_keys.should == ['NonExistentClass']
    end

    it "should return no candidate matching or non-matching types when only objects are input." do
      pc = Pointcut.new :objects => @example_classes.map {|t| t.new}
      pc.candidate_types.matched_keys.should == []
      pc.candidate_types.not_matched_keys.should == []
    end
  end

  describe Pointcut, "#candidate_objects" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should return only candidate matching objects when the input are objects." do
      example_objs = @example_classes.map {|t| t.new}
      pc = Pointcut.new :objects => example_objs
      example_objs.each do |obj|
        pc.candidate_objects.matched[obj].should_not be(nil?)
      end
      pc.candidate_objects.not_matched_keys.should == []
    end
  end

  describe Pointcut, "#candidate_join_points" do
    before(:each) do
      before_pointcut_class_spec
    end
  
    it "should return only candidate non-matching join points for the input join points that do not exist." do
      anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
      example_jps = [
        JoinPoint.new(:type   => ClassWithPublicInstanceMethod,   :method => :foo),
        JoinPoint.new(:object => anClassWithPublicInstanceMethod, :method => :foo)]
      pc = Pointcut.new :join_points => example_jps
      pc.candidate_join_points.matched.size.should == 0
      pc.candidate_join_points.not_matched[example_jps[0]].should_not be_nil
      pc.candidate_join_points.not_matched[example_jps[1]].should_not be_nil
    end
  
    it "should return only candidate matching join points for the input join points that do exist." do
      anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
      example_jps = [
        JoinPoint.new(:type   => ClassWithPublicInstanceMethod,   :method => :public_instance_test_method),
        JoinPoint.new(:object => anClassWithPublicInstanceMethod, :method => :public_instance_test_method)]
      pc = Pointcut.new :join_points => example_jps
      pc.candidate_join_points.matched.size.should == 2
      pc.candidate_join_points.matched[example_jps[0]].should_not be_nil
      pc.candidate_join_points.matched[example_jps[1]].should_not be_nil
      pc.candidate_join_points.not_matched.size.should == 0
    end
  end

  describe Pointcut, "#specification" do
    before(:each) do
      before_pointcut_class_spec
    end

    it "should return ':attribute_options => []', by default, if no arguments are given." do
      pc = Pointcut.new
      pc.specification[:attribute_options].should eql(Set.new)
    end

    it "should return the input :types and :type arguments combined into an array keyed by :types." do
      pc = Pointcut.new :types => @example_classes, :type => String
      pc.specification[:types].should eql(Set.new(@example_classes + [String]))
    end
  
    it "should return the input :objects and :object arguments combined into an array keyed by :objects." do
      example_objs = @example_classes.map {|t| t.new}
      s1234 = "1234"
      pc = Pointcut.new :objects => example_objs, :object => s1234
      pc.specification[:objects].should eql(Set.new(example_objs + [s1234]))
    end

    it "should return the input :methods and :method arguments combined into an array keyed by :methods." do
      pc = Pointcut.new :types => @example_classes, :methods => /^get/, :method => "dup"
      pc.specification[:types].should eql(Set.new(@example_classes))
      pc.specification[:methods].should eql(Set.new([/^get/, "dup"]))
    end
  
    it "should return the input :method_options verbatim." do
      pc = Pointcut.new :types => @example_classes, :methods => /^get/, :method => "dup", :method_options => [:instance, :public]
      pc.specification[:method_options].should eql(Set.new([:instance, :public]))
    end
  
    it "should return the input :attributes and :attribute arguments combined into an array keyed by :attributes." do
      pc = Pointcut.new :types => @example_classes, :attributes => /^state/, :attribute => "name"
      pc.specification[:attributes].should eql(Set.new([/^state/, "name"]))
    end
  
    it "should return the input :attributes, :attribute and :attribute_options arguments, verbatim." do
      pc = Pointcut.new :types => @example_classes, :attributes => /^state/, :attribute => "name", :attribute_options => :reader
      pc.specification[:attributes].should eql(Set.new([/^state/, "name"]))
      pc.specification[:attribute_options].should eql(Set.new([:reader]))
    end
  end
end