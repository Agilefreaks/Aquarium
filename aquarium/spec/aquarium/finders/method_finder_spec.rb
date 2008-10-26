require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/finders/method_finder'

# :stopdoc:
class Base
  def mbase1
  end
  def mbase2
  end
end

module M
  def mmodule1
  end
  def mmodule2
  end
  def self.cmmodule1
  end
end

module M2
  include M
  def mmodule3
  end
  def mmodule4
  end
  def self.cmmodule3
  end
end

class Derived < Base
  include M
  def mbase1
  end
  def mderived1
  end
  def mmodule1
  end
  def mmodule2b
  end
end

class Derived2 < Base
  include M2
  def mbase1
  end
  def mderived1
  end
  def mmodule1
  end
  def mmodule2b
  end
  def mmodule3
  end
  def mmodule4b
  end
end

# :startdoc:

def before_method_finder_spec
  @test_classes = [
    ClassWithPublicInstanceMethod, 
    ClassWithProtectedInstanceMethod, 
    ClassWithPrivateInstanceMethod, 
    ClassWithPublicClassMethod, 
    ClassWithPrivateClassMethod]
  @pub = ClassWithPublicInstanceMethod.new
  @pro = ClassWithProtectedInstanceMethod.new
  @pri = ClassWithPrivateInstanceMethod.new
  @cpub = ClassWithPublicClassMethod.new
  @cpri = ClassWithPrivateClassMethod.new
  @test_objects = [@pub, @pro, @pri, @cpub, @cpri]

  @other_methods_expected = []
  @empty_set = Set.new
end

describe Aquarium::Finders::MethodFinder, "#find (synonymous input parameters)" do
  before(:each) do
    @logger_stream = StringIO.new
    before_method_finder_spec
  end
  
  Aquarium::Finders::MethodFinder::CANONICAL_OPTIONS["types"].each do |key|
    it "should accept :#{key} as a synonym for :types." do
      expected = Aquarium::Finders::MethodFinder.new.find :types     => Derived, :methods => [/^mbase/, /^mmodule/]
      actual   = Aquarium::Finders::MethodFinder.new.find key.intern => Derived, :methods => [/^mbase/, /^mmodule/]
      actual.should == expected
    end
  end
  
  Aquarium::Finders::MethodFinder::CANONICAL_OPTIONS["objects"].each do |key|
    it "should accept :#{key} as a synonym for :objects." do
      child = Derived.new
      expected = Aquarium::Finders::MethodFinder.new.find :objects   => child, :methods => [/^mbase/, /^mmodule/]
      actual   = Aquarium::Finders::MethodFinder.new.find key.intern => child, :methods => [/^mbase/, /^mmodule/]
      actual.should == expected
    end
  end
  
  Aquarium::Finders::MethodFinder::CANONICAL_OPTIONS["methods"].each do |key|
    it "should accept :#{key} as a synonym for :methods." do
      expected = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods   => [/^mbase/, /^mmodule/]
      actual   = Aquarium::Finders::MethodFinder.new.find :types => Derived, key.intern => [/^mbase/, /^mmodule/]
      actual.should == expected
    end
  end
  
  Aquarium::Finders::MethodFinder::CANONICAL_OPTIONS["method_options"].each do |key|
    it "should accept :#{key} as a synonym for :method_options." do
      expected = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mder/, /^mmod/], :method_options => [:exclude_ancestor_methods], :logger_stream => @logger_stream
      actual   = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mder/, /^mmod/], key.intern => [:exclude_ancestor_methods], :logger_stream => @logger_stream
      actual.should == expected
    end
  end

  it "should warn that :options as a synonym for :method_options is deprecated." do
    expected = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mder/, /^mmod/], :options => [:exclude_ancestor_methods], :logger_stream => @logger_stream
    @logger_stream.to_s.grep(/WARN.*deprecated/).should_not be_nil
  end
  
end
  
describe Aquarium::Finders::MethodFinder, "#find (invalid input parameters)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should raise if unrecognized option specified." do
    lambda { Aquarium::Finders::MethodFinder.new.find :tpye => "x", :ojbect => "y", :mehtod => "foo"}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should raise if options include :singleton and :class, :public, :protected, or :private." do
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :method_options => [:singleton, :class] }.should     raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :method_options => [:singleton, :public] }.should    raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :method_options => [:singleton, :protected] }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :method_options => [:singleton, :private] }.should   raise_error(Aquarium::Utils::InvalidOptions)
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (input parameters that yield empty results)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should return empty FinderResult#matched and FinderResult#not_matched hashes by default." do
    actual = Aquarium::Finders::MethodFinder.new.find
    actual.matched.should == {}
    actual.not_matched.should == {}
  end

  it "should return empty FinderResult#matched and FinderResult#not_matched hashes if no types are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [], :methods => /instance_test_method/
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should return empty FinderResult#matched and FinderResult#not_matched hashes if no objects are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [], :methods => /instance_test_method/
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified types if no methods are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod
    actual.matched.should == {}
    actual.not_matched.should == {ClassWithPublicInstanceMethod => @empty_set}
  end
end

describe Aquarium::Finders::MethodFinder, "#find (input parameters specify no methods)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified objects if no methods are specified." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => pub
    actual.matched.should == {}
    actual.not_matched.should == {pub => @empty_set}
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified types if an empty methods list is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => []
    actual.matched.should == {}
    actual.not_matched.should == {ClassWithPublicInstanceMethod => @empty_set}
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified objects if an empty methods list is specified." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :methods => []
    actual.matched.should == {}
    actual.not_matched.should == {pub => @empty_set}
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified types if an empty method name is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => ""
    actual.matched.should == {}
    actual.not_matched.should == {ClassWithPublicInstanceMethod => Set.new([""])}
  end
  
  it "should return an empty FinderResult#matched hash and a FinderResult#not_matched hash with the specified objects if an empty method name is specified." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => pub, :methods => ""
    actual.matched.should == {}
    actual.not_matched.should == {pub => Set.new([""])}
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (input parameters specify method regular expressions that match nothing)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should find no methods when searching with one type and with a regexp matching no methods." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /no_matching_method/
    actual.matched.should == {}
    actual.not_matched[ClassWithPublicInstanceMethod].should == Set.new([/no_matching_method/])
  end
  
  it "should find no methods when searching with one object and with a regexp matching no methods." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :methods => /no_matching_method/
    actual.matched.should == {}
    actual.not_matched[pub].should == Set.new([/no_matching_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (input parameters specify method names that match nothing)" do
  before(:each) do
    before_method_finder_spec
  end
    
  it "should find no methods when searching with a type and with a literal name matching no methods." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => "no_matching_method"
    actual.matched.should == {}
    actual.not_matched[ClassWithPublicInstanceMethod].should == Set.new(["no_matching_method"])
  end
  
  it "should find no methods when searching with one object and with a literal name matching no methods." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :methods => "no_matching_method"
    actual.matched.should == {}
    actual.not_matched[pub].should == Set.new(["no_matching_method"])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (behavior for derived classes)" do
  before(:each) do
    before_method_finder_spec
  end
    
  it "should find base and derived methods in the specified class, by default." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mbase/, /^mmodule/]
    actual.matched.size.should == 1
    actual.matched[Derived].should == Set.new([:mbase1, :mbase2, :mmodule1, :mmodule2, :mmodule2b])
  end
   
  it "should find base and derived methods in the specified object, by default." do
    child = Derived.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => child, :methods => [/^mbase/, /^mderived/, /^mmodule/]
    actual.matched.size.should == 1
    actual.matched[child].should == Set.new([:mbase1, :mbase2, :mderived1, :mmodule1, :mmodule2, :mmodule2b])
  end
   
  it "should only find Derived methods for a type when ancestor methods are excluded, which also excludes method overrides." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mder/, /^mmod/], :method_options => [:exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[Derived].should == Set.new([:mderived1, :mmodule2b])
  end

  it "should only find Derived methods for an object when ancestor methods are excluded, which also excludes method overrides." do
    child = Derived.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => child, :methods => [/^mder/, /^mmodule/], :method_options => [:exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[child].should == Set.new([:mderived1, :mmodule2b])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (behavior for included modules)" do
  before(:each) do
    before_method_finder_spec
  end
    
  it "should find included and defined methods in the specified modules, by default." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => [M, M2], :methods => /^mmodule/
    actual.matched.size.should == 2
    actual.matched[M].should  == Set.new([:mmodule1, :mmodule2])
    actual.matched[M2].should == Set.new([:mmodule1, :mmodule2, :mmodule3, :mmodule4])
  end
   
  it "should find included and overridden methods in classes that include the specified modules, by default." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [Derived, Derived2], :methods => /^mmodule/
    actual.matched.size.should == 2
    actual.matched[Derived].should  == Set.new([:mmodule1, :mmodule2, :mmodule2b])
    actual.matched[Derived2].should == Set.new([:mmodule1, :mmodule2, :mmodule2b, :mmodule3, :mmodule4, :mmodule4b])
  end
   
  it "should find included and overridden methods in instances of classes that include the specified modules, by default." do
    child  = Derived.new
    child2 = Derived2.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [child, child2], :methods => /^mmodule/
    actual.matched.size.should == 2
    actual.matched[child].should  == Set.new([:mmodule1, :mmodule2, :mmodule2b])
    actual.matched[child2].should == Set.new([:mmodule1, :mmodule2, :mmodule2b, :mmodule3, :mmodule4, :mmodule4b])
  end
   
  it "should only find defined methods for a module when ancestor methods are excluded, which also excludes method overrides." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => [M, M2], :methods => /^mmod/, :method_options => [:exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[M].should  == Set.new([:mmodule1, :mmodule2])
    actual.matched[M2].should == Set.new([:mmodule3, :mmodule4])
  end

  it "should not find any methods from included modules in classes when ancestor methods are excluded, which also excludes method overrides." do
    child  = Derived.new
    child2 = Derived2.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [child, child2], :methods => /^mmodule/, :method_options => [:exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[child].should  == Set.new([:mmodule2b])
    actual.matched[child2].should == Set.new([:mmodule2b, :mmodule4b])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (searching for class methods)" do
  before(:each) do
    before_method_finder_spec
    @expected_ClassWithPUblicClassMethod = Set.new(ClassWithPublicClassMethod.public_methods.reject{|m| m =~ /^__/}.sort.map{|m| m.intern})
    @expected_ClassWithPrivateClassMethod = Set.new(ClassWithPrivateClassMethod.public_methods.reject{|m| m =~ /^__/}.sort.map{|m| m.intern})
  end
  
  it "should find all class methods specified by regular expression for types when :class is used." do
    # NOTE: The list of methods defined by Kernel is different for MRI and JRuby!
    expected = {}
    expected[Kernel] = [:respond_to?]
    expected[Kernel] += [:chomp!, :chop!] unless Object.const_defined?('JRUBY_VERSION')
    [Object, Module, Class].each do |clazz|
      expected[clazz] = [:respond_to?]
    end
    class_array = [Kernel, Module, Object, Class]
    actual = Aquarium::Finders::MethodFinder.new.find :types => class_array, :methods => [/^resp.*\?$/, /^ch.*\!$/], :method_options => :class
    class_array.each do |c|
      actual.matched[c].should == Set.new(expected[c])
    end
  end
  
  it "should ignore any methods that start with double underscores '__' by default when searching with the :all method specification and the :class option." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all, :method_options => :class
    actual.matched.size.should == 2
    actual.not_matched.size.should == 0
    actual.matched[ClassWithPublicClassMethod].should == @expected_ClassWithPUblicClassMethod
    actual.matched[ClassWithPrivateClassMethod].should == @expected_ClassWithPrivateClassMethod 
  end
  
  it "should find any methods that start with double underscores '__' with the :include_system_methods option." do
    class WithUnderScores
      def self.__foo__; end
    end
    actual = Aquarium::Finders::MethodFinder.new.find :types => [WithUnderScores], :methods => :all, :method_options => [:class, :include_system_methods]
    actual.matched[WithUnderScores].include?(:__foo__).should be_true
  end
  
  it "should find all public class methods in types when searching with the :all method specification and the :class option." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all, :method_options => :class
    actual.matched.size.should == 2
    actual.not_matched.size.should == 0
    actual.matched[ClassWithPublicClassMethod].should == @expected_ClassWithPUblicClassMethod
    actual.matched[ClassWithPrivateClassMethod].should == @expected_ClassWithPrivateClassMethod 
  end
  
  it "should accept :all_methods as a synonym for :all." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all_methods, :method_options => :class
    actual.matched.size.should == 2
    actual.not_matched.size.should == 0
    actual.matched[ClassWithPublicClassMethod].should == @expected_ClassWithPUblicClassMethod
    actual.matched[ClassWithPrivateClassMethod].should == @expected_ClassWithPrivateClassMethod 
  end
  
  it "should find all public class methods in types, but not ancestors, when searching with the :all method specification and the :class and :exclude_ancestor_methods options." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all, :method_options => [:class, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.not_matched.size.should == 1
    actual.matched[ClassWithPublicClassMethod].should == Set.new([:public_class_test_method])
    actual.not_matched[ClassWithPrivateClassMethod].should == Set.new([:all])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (searching for class methods defined in modules)" do
  before(:each) do
    before_method_finder_spec
  end

  def do_class_methods_for_modules method_spec, options_spec
    actual = Aquarium::Finders::MethodFinder.new.find :type => [M, M2], :methods => method_spec, :method_options => options_spec
    actual.matched.size.should == 2
    actual.matched[M].should  == Set.new([:cmmodule1])
    actual.matched[M2].should == Set.new([:cmmodule3])
  end
  
  it "should find all class methods specified by regular expression for modules when :class is used." do
    do_class_methods_for_modules /^cmmodule/, [:class]
  end
  
  it "should find all class methods specified by name for modules when :class is used." do
    do_class_methods_for_modules [:cmmodule1, :cmmodule3], [:class]
  end
  
  it "should not find class methods defined in included modules, because they do not become class methods in the including module." do
    do_class_methods_for_modules /^cmmodule/, [:class]
  end
  
  it "should not find class methods defined in included modules, if ancestor methods are excluded explicitly." do
    do_class_methods_for_modules /^cmmodule/, [:class, :exclude_ancestor_methods]
  end
  
  it "should find all public class methods in types when searching with the :all method specification and the :class option." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => [M, M2], :methods => :all, :method_options => [:class]
    actual.matched.size.should == 2
    actual.matched[M].should  == Set.new(M.public_methods.reject{|m| m =~ /^__/}.sort.map{|m| m.intern})
    actual.matched[M2].should == Set.new(M2.public_methods.reject{|m| m =~ /^__/}.sort.map{|m| m.intern})
  end
  
  it "should not find any module-defined class methods in classes that include the modules." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [Derived, Derived2], :methods => /^cmmodule/, :method_options => [:class]
    actual.matched.size.should == 0
  end
   
  it "should not find any module-defined class methods in instances of classes that include the modules." do
    child  = Derived.new
    child2 = Derived2.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [child, child2], :methods => /^cmmodule/, :method_options => [:class]
    actual.matched.size.should == 0
  end
end

describe Aquarium::Finders::MethodFinder, "#find (searching for instance methods)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should ignore any methods that start with double underscores '__' by default when searching with the :all method specification and the :class option." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod], :methods => :all
    actual.matched.size.should == 3
    [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod].each do |c|
      actual.matched[c].each {|m| m.to_s.match('^__').should be_nil}
    end
  end
  
  it "should find any methods that start with double underscores '__' with the :include_system_methods option." do
    class WithUnderScores
      def __foo__; end
    end
    actual = Aquarium::Finders::MethodFinder.new.find :types => [WithUnderScores], :methods => :all, :method_options => [:include_system_methods]
    actual.matched[WithUnderScores].include?(:__foo__).should be_true
  end
  
  it "should find all public instance methods in classes when searching with the :all method specification." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod], :methods => :all
    actual.matched.size.should == 3
    [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod].each do |c|
      actual.matched[c].should == Set.new(c.public_instance_methods.reject{|m| m =~ /^__/}.sort.map {|m| m.intern})
    end
  end
  
  it "should find all public instance methods in modules when searching with the :all method specification." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [M, M2], :methods => :all
    actual.matched.size.should == 2
    actual.matched[M].should  == Set.new([:mmodule1, :mmodule2])
    actual.matched[M2].should == Set.new([:mmodule1, :mmodule2, :mmodule3, :mmodule4])
  end
  
  it "should find all public instance methods in objects when searching with the :all method specification." do
    pub = ClassWithPublicInstanceMethod.new
    pro = ClassWithProtectedInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub, pro, pri], :methods => :all
    actual.matched.size.should == 3
    [pub, pro, pri].each do |c|
      actual.matched[c].should == Set.new(c.public_methods.reject{|m| m =~ /^__/}.sort.map {|m| m.intern})
    end
  end
  
  it "should find the module-defined public instance methods in when searching a class with the :all method specification." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [Derived, Derived2], :methods => :all
    actual.matched.size.should == 2
    [:mmodule1, :mmodule2].each {|m| actual.matched[Derived].should include(m)}
    [:mmodule1, :mmodule2, :mmodule3, :mmodule4].each {|m| actual.matched[Derived2].should include(m)}
  end
  
  it "should find the module-defined public instance methods in when searching an instance of a class with the :all method specification." do
    child  = Derived.new
    child2 = Derived2.new
    actual = Aquarium::Finders::MethodFinder.new.find :types => [child, child2], :methods => :all
    actual.matched.size.should == 2
    [:mmodule1, :mmodule2].each {|m| actual.matched[child].should include(m)}
    [:mmodule1, :mmodule2, :mmodule3, :mmodule4].each {|m| actual.matched[child2].should include(m)}
  end
  
  it "should find only one instance method for a type when searching with a regexp matching one method." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    actual2 = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /instance_test/
    actual2.matched.size.should == 1
    actual2.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    actual3 = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /test_method/
    actual3.matched.size.should == 1
    actual3.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for an object when searching with a regexp matching one method." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one class when searching with a one-class array and with a regexp matching one method." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod], :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one object when searching with a one-object array and with a regexp matching one method." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub], :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one class when searching with a one-class array and with a single-regexp array matching one method." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod], :methods => [/instance_test_method/]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one object when searching with a one-object array and with a single-regexp array matching one method." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub], :methods => [/instance_test_method/]
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one class when searching with a one-class array and with the method's literal name." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod], :methods => "public_instance_test_method"
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one object when searching with a one-object array and with the method's literal name." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub], :methods => "public_instance_test_method"
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one class when searching with a one-class array and with the method's literal name in a single-element array." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod], :methods => ["public_instance_test_method"]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should find only one instance method for one object when searching with a one-object array and with the method's literal name in a single-element array." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub], :methods => ["public_instance_test_method"]
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should find an instance method for each class when searching with a two-class array and with the methods' literal names." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod, ClassWithPublicInstanceMethod2], :methods => ["public_instance_test_method", "public_instance_test_method2"]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should  == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPublicInstanceMethod2].should == Set.new([:public_instance_test_method2])
  end

  it "should find an instance method for each object when searching with a two-object array and with the methods' literal names." do
    pub  = ClassWithPublicInstanceMethod
    pub2 = ClassWithPublicInstanceMethod2.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub, pub2], :methods => ["public_instance_test_method", "public_instance_test_method2"]
    actual.matched.size.should == 2
    actual.matched[pub].should  == Set.new([:public_instance_test_method])
    actual.matched[pub2].should == Set.new([:public_instance_test_method2])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (format of results)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should return found methods for a type as symbols." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should return found methods for an object as symbols." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :methods => :all)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should accept :all for the methods argument and find all methods for a type subject to the method options." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPublicInstanceMethod, :method => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should accept :all for the methods argument and find all methods for an object subject to the method options." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :method => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should ignore other method arguments if :all is present." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPublicInstanceMethod, :method => [:all, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :method => [:all, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should ignore other method arguments if :all_methods is present." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPublicInstanceMethod, :method => [:all_methods, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :method => [:all, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should report [:all] as the not_matched value when :all is the method argument and no methods match, e.g., for :exclude_ancestor_methods." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPrivateInstanceMethod, :method => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched[ClassWithPrivateInstanceMethod].should == Set.new([:all])
    pri = ClassWithPrivateInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pri, :method => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched[pri].should == Set.new([:all])
  end
end
  
class ExcludeMethodTester
  def method1; end
  def method2; end
  def method3; end
end
  
describe Aquarium::Finders::MethodFinder, "#find for types (using :exclude_methods)" do
  it "should return an empty result for classes if :exclude_methods => :all specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_methods => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched.size.should == 0
  end
  it "should return an empty result for modules if :exclude_methods => :all specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => M2, :methods => :all, :exclude_methods => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched.size.should == 0
  end
  it "should return an empty result for classes including modules if :exclude_methods => :all specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived2, :methods => :all, :exclude_methods => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched.size.should == 0
  end
  
  it "should remove excluded methods from the result for classes where a single excluded methods is specified by name." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_method => :method1, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ExcludeMethodTester].size.should == 2
    actual.matched[ExcludeMethodTester].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  it "should remove excluded methods from the result for modules where a single excluded methods is specified by name." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => M, :methods => :all, :exclude_method => :mmodule1
    actual.matched.size.should == 1
    actual.matched[M].size.should == 1
    actual.matched[M].should == Set.new([:mmodule2])
    actual.not_matched.size.should == 0
  end
  it "should remove excluded methods from the result for classes that include modules where a single excluded methods is specified by name." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => :all, :exclude_method => :mmodule1
    actual.matched.size.should == 1
    actual.matched[Derived].should_not include(:mmodule1)
  end
  
  it "should remove excluded methods from the result where the excluded methods are specified by an array of names." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_methods => [:method1, :method2], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ExcludeMethodTester].size.should == 1
    actual.matched[ExcludeMethodTester].should == Set.new([:method3])
    actual.not_matched.size.should == 0
  end
  
  it "should remove excluded methods from the result where the excluded methods are specified by regular expression." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_methods => /meth.*1$/, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ExcludeMethodTester].size.should == 2
    actual.matched[ExcludeMethodTester].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  
  it "should support :exclude_method as a synonym." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_method => :method1, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ExcludeMethodTester].size.should == 2
    actual.matched[ExcludeMethodTester].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  
  it "should not add the excluded methods to the #not_matched results." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ExcludeMethodTester, :methods => :all, :exclude_methods => /meth.*1$/, :method_options => :exclude_ancestor_methods
    actual.not_matched.size.should == 0
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find for objects (using :exclude_methods)" do
  it "should return an empty result for instances of classes if :exclude_methods => :all specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :object => ExcludeMethodTester.new, :methods => :all, :exclude_methods => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched.size.should == 0
  end
  it "should return an empty result for for instances of classes that include modules if :exclude_methods => :all specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :object => Derived2.new, :methods => :all, :exclude_methods => :all, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched.size.should == 0
  end
  
  it "should remove excluded methods from the result where a single excluded methods is specified by name." do
    emt = ExcludeMethodTester.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => emt, :methods => :all, :exclude_method => :method1, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[emt].size.should == 2
    actual.matched[emt].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  
  it "should remove excluded methods from the result where the excluded methods are specified by an array of names." do
    emt = ExcludeMethodTester.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => emt, :methods => :all, :exclude_methods => [:method1, :method2], :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[emt].size.should == 1
    actual.matched[emt].should == Set.new([:method3])
    actual.not_matched.size.should == 0
  end
  
  it "should remove excluded methods from the result where the excluded methods are specified by regular expression." do
    emt = ExcludeMethodTester.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => emt, :methods => :all, :exclude_methods => /meth.*1$/, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[emt].size.should == 2
    actual.matched[emt].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  
  it "should support :exclude_method as a synonym." do
    emt = ExcludeMethodTester.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => emt, :methods => :all, :exclude_method => :method1, :method_options => :exclude_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[emt].size.should == 2
    actual.matched[emt].should == Set.new([:method2, :method3])
    actual.not_matched.size.should == 0
  end
  
  it "should not add the excluded methods to the #not_matched results." do
    actual = Aquarium::Finders::MethodFinder.new.find :object => ExcludeMethodTester.new, :methods => :all, :exclude_methods => /meth.*1$/, :method_options => :exclude_ancestor_methods
    actual.not_matched.size.should == 0
  end
end
  

describe Aquarium::Finders::MethodFinder, "#find (using :method_options => :exclude_ancestor_methods)" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should suppress ancestor methods for classes when :exclude_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end
  it "should suppress ancestor methods for objects when :exclude_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end

  it "should suppress ancestor methods for modules when :exclude_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => M2, :methods => /^mmodule/, :method_options => [:instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[M2].should == Set.new([:mmodule3, :mmodule4])
    actual.not_matched.size.should == 0
  end
  it "should suppress ancestor methods for classes including modules when :exclude_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [Derived, Derived2], :methods => /^mmodule/, :method_options => [:instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[Derived].should  == Set.new([:mmodule2b])
    actual.matched[Derived2].should == Set.new([:mmodule2b, :mmodule4b])
    actual.not_matched.size.should == 0
  end
  it "should suppress ancestor methods for instances of classes including modules when :exclude_ancestor_methods is specified." do
    child  = Derived.new
    child2 = Derived2.new
    actual = Aquarium::Finders::MethodFinder.new.find :types => [child, child2], :methods => /^mmodule/, :method_options => [:instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[child].should  == Set.new([:mmodule2b])
    actual.matched[child2].should == Set.new([:mmodule2b, :mmodule4b])
    actual.not_matched.size.should == 0
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find only public instance methods for types when :public, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find only public instance methods for objects when :public, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:protected, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find only protected instance methods when :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:protected, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should      == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find only protected instance methods for objects when :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:protected, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:private, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find only private instance methods when :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPrivateInstanceMethod].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find only private instance methods for objects when :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :class])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find only public class methods for types when :public, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :class, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicClassMethod].should == Set.new([:public_class_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find no public class methods for objects when :public, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :class, :exclude_ancestor_methods]
    actual.matched.size.should == 0
    actual.not_matched.size.should == 5
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:private, :class])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find only private class methods for types when :private, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:private, :class, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPrivateClassMethod].should == Set.new([:private_class_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
  end

  it "should find no private class methods for objects when :private, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:private, :class, :exclude_ancestor_methods]
    actual.matched.size.should == 0
    actual.not_matched.size.should == 5
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :protected, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find public and protected instance methods for types when :public, :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :protected, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find public and protected instance methods for objects when :public, :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :protected, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :;private, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find public and private instance methods when :public, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should  == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPrivateInstanceMethod].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find public and private instance methods for objects when :public, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:protected, :private, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find protected and private instance methods when :protected, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:protected, :private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.matched[ClassWithPrivateInstanceMethod].should   == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPublicInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should      == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find protected and private instance methods for objects when :protected, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:protected, :private, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :class, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find public class and instance methods for types when :public, :class, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :class, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should  == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPublicClassMethod].should     == Set.new([:public_class_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPrivateInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should       == Set.new([/test_method/])
  end

  it "should find only public instance methods for objects even when :class is specified along with :public and :instance." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :class, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should  == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:public, :protected, :class, :instance])" do
  before(:each) do
    before_method_finder_spec
  end

  it "should find public and protected instance methods when :public, :protected, :class, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :method_options => [:public, :protected, :class, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 3
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPublicClassMethod].should       == Set.new([:public_class_test_method])
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 2
    actual.not_matched[ClassWithPrivateInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find only public and protected instance methods for objects even when :class is specified along with :public, :protected, :class, and :instance." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :method_options => [:public, :protected, :class, :instance, :exclude_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should  == Set.new([:public_instance_test_method])
    actual.matched[@pro].should  == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end

describe Aquarium::Finders::MethodFinder, "#find (using :method_options => [:include_system_methods])" do
  before(:each) do
    before_method_finder_spec
  end
  
  it "should find instance methods otherwise excluded by the MethodFinder::IGNORED_SYSTEM_METHODS list of regex's" do
    class WithIgnored
      def __foo__; end
    end
    actual = Aquarium::Finders::MethodFinder.new.find :class => WithIgnored, :methods => :all, :method_options => [:include_system_methods, :exclude_ancestor_methods]
    actual.matched[WithIgnored].should include(:__foo__)    
  end

  it "should find class methods otherwise excluded by the MethodFinder::IGNORED_SYSTEM_METHODS list of regex's" do
    class WithSelfIgnored
      def self.__self_foo__; end
    end
    actual = Aquarium::Finders::MethodFinder.new.find :class => WithSelfIgnored, :methods => :all, :method_options => [:include_system_methods, :class, :exclude_ancestor_methods]
    actual.matched[WithSelfIgnored].should include(:__self_foo__)        
  end
end

describe "Aquarium::Finders::MethodFinder#find (looking for singleton methods)" do
  before(:each) do
    class Empty
    end

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

  it "should find instance-level singleton methods for objects when :singleton is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [@notQuiteEmpty, @objectWithSingletonMethod], :methods => :all, :method_options => [:singleton]
    actual.matched.size.should == 1
    actual.matched[@objectWithSingletonMethod].should  == Set.new([:a_singleton_method])
    actual.not_matched.size.should == 1
    actual.not_matched[@notQuiteEmpty].should  == Set.new([:all])
  end    

  it "should find type-level singleton methods for types when :singleton is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :exclude_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[NotQuiteEmpty].should  == Set.new([:a_class_singleton_method])
    actual.not_matched.size.should == 1
    actual.not_matched[Empty].should  == Set.new([:all])
  end
end

describe "Aquarium::Finders::MethodFinder#find (looking for methods that end in non-alphanumeric characters)" do
  class ClassWithFunkyMethodNames
    def huh?; true; end
    def yes!; true; end
    def == other; false; end
    def =~ other; false; end
  end
  
  before(:each) do
    @funky = ClassWithFunkyMethodNames.new
  end  
  
  {'?' => :huh?, '!' => :yes!, '=' => :==, '~' => :=~}.each do |char, method|
    it "should find instance methods for types when searching for names that end with a '#{char}' character using the method's name." do
      actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithFunkyMethodNames, :methods => method
      actual.matched.size.should == 1
      actual.matched[ClassWithFunkyMethodNames].should  == Set.new([method])
      actual.not_matched.size.should == 0
    end    

    it "should find instance methods for types when searching for names that end with a '#{char}' character using a regular expression." do
      actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithFunkyMethodNames, :methods => /#{Regexp.escape(char)}$/
      actual.matched.size.should >= 1
      actual.matched[ClassWithFunkyMethodNames].should  include(method)
      actual.not_matched.size.should == 0
    end    

    it "should find instance methods for objects when searching for names that end with a '#{char}' character using the method's name." do
      actual = Aquarium::Finders::MethodFinder.new.find :object => @funky, :methods => method
      actual.matched.size.should == 1
      actual.matched[@funky].should  == Set.new([method])
      actual.not_matched.size.should == 0
    end    

    it "should find instance methods for objects when searching for names that end with a '#{char}' character using a regular expression." do
      actual = Aquarium::Finders::MethodFinder.new.find :object => @funky, :methods => /#{Regexp.escape(char)}$/
      actual.matched.size.should >= 1
      actual.matched[@funky].should  include(method)
      actual.not_matched.size.should == 0
    end    
  end  
end

  
describe "Aquarium::Finders::MethodFinder.is_recognized_method_option" do

  it "should be true for :public, :private, :protected, :instance, :class, and :exclude_ancestor_methods as strings or symbols." do
    %w[public private protected instance class exclude_ancestor_methods].each do |s|
      Aquarium::Finders::MethodFinder.is_recognized_method_option(s).should == true
      Aquarium::Finders::MethodFinder.is_recognized_method_option(s.to_sym).should == true
    end
  end  

  it "should be false for unknown options." do
    %w[public2 wierd unknown string].each do |s|
      Aquarium::Finders::MethodFinder.is_recognized_method_option(s).should == false
      Aquarium::Finders::MethodFinder.is_recognized_method_option(s.to_sym).should == false
    end
  end
end
 