require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
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
end

class Derived < Base
  include M
  def mbase1
  end
  def mderived1
  end
  def mmodule1
  end
  def mmodule3
  end
end

# :startdoc:

def before_method_finder_specbefore
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
    before_method_finder_specbefore
  end
  
  it "should accept options :types and :type, which are synonymous." do
    expected = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mbase/, /^mmodule/]
    actual   = Aquarium::Finders::MethodFinder.new.find :type  => Derived, :methods => [/^mbase/, /^mmodule/]
    actual.should == expected
  end

  it "should accept options :objects and :object, which are synonymous." do
    child = Derived.new
    expected = Aquarium::Finders::MethodFinder.new.find :objects => child, :methods => [/^mbase/, /^mmodule/]
    actual   = Aquarium::Finders::MethodFinder.new.find :object  => child, :methods => [/^mbase/, /^mmodule/]
    actual.should == expected
  end

  it "should accept options :methods and :method, which are synonymous." do
    expected = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mbase/, /^mmodule/]
    actual   = Aquarium::Finders::MethodFinder.new.find :types => Derived, :method  => [/^mbase/, /^mmodule/]
    actual.should == expected
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (invalid input parameters)" do
  before(:each) do
    before_method_finder_specbefore
  end
  
  it "should raise if unrecognized option specified." do
    lambda { Aquarium::Finders::MethodFinder.new.find :tpye => "x", :ojbect => "y", :mehtod => "foo"}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should raise if options include :singleton and :class, :public, :protected, or :private." do
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :options => [:singleton, :class] }.should     raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :options => [:singleton, :public] }.should    raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :options => [:singleton, :protected] }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Finders::MethodFinder.new.find :type => String, :method => "foo", :options => [:singleton, :private] }.should   raise_error(Aquarium::Utils::InvalidOptions)
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (input parameters that yield empty results)" do
  before(:each) do
    before_method_finder_specbefore
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
    before_method_finder_specbefore
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
    before_method_finder_specbefore
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
    before_method_finder_specbefore
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
    before_method_finder_specbefore
  end
    
  it "should find Base and Derived methods in the specified class, by default." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mbase/, /^mmodule/]
    actual.matched.size.should == 1
    actual.matched[Derived].should == Set.new([:mbase1, :mbase2, :mmodule1, :mmodule2, :mmodule3])
  end
   
  it "should find Base and Derived methods in the specified object, by default." do
    child = Derived.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => child, :methods => [/^mbase/, /^mderived/, /^mmodule/]
    actual.matched.size.should == 1
    actual.matched[child].should == Set.new([:mbase1, :mbase2, :mderived1, :mmodule1, :mmodule2, :mmodule3])
  end
   
  it "should find Derived methods only for a type when ancestor methods are suppressed, which also suppresses method overrides." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => Derived, :methods => [/^mder/, /^mmod/], :options => [:suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[Derived].should == Set.new([:mderived1, :mmodule3])
  end

  it "should find Derived methods only for an object when ancestor methods are suppressed, which also suppresses method overrides." do
    child = Derived.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => child, :methods => [/^mder/, /^mmodule/], :options => [:suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[child].should == Set.new([:mderived1, :mmodule3])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (searching for class methods)" do
  before(:each) do
    before_method_finder_specbefore
  end
  
  it "should find all class methods matching a regular expression for types when :class is used." do
    # Have to add some rspec methods to the expected lists!
    expected = {}
    expected[Kernel] = [:chomp!, :chop!, :respond_to?]
    [Object, Module, Class].each do |clazz|
      expected[clazz] = [:respond_to?]
    end
    class_array = [Kernel, Module, Object, Class]
    actual = Aquarium::Finders::MethodFinder.new.find :types => class_array, :methods => [/^resp.*\?$/, /^ch.*\!$/], :options => :class
    class_array.each do |c|
      actual.matched[c].should == Set.new(expected[c])
    end
  end
  
  it "should find all public class methods in types when searching with the :all method specification and the :class option." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all, :options => :class
    actual.matched.size.should == 2
    actual.not_matched.size.should == 0
    actual.matched[ClassWithPublicClassMethod].should == Set.new(ClassWithPublicClassMethod.public_methods.sort.map{|m| m.intern})
    actual.matched[ClassWithPrivateClassMethod].should == Set.new(ClassWithPrivateClassMethod.public_methods.sort.map{|m| m.intern})
  end
  
  it "should find all public class methods in types, but not ancestors, when searching with the :all method specification and the :class and :suppress_ancestor_methods options." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicClassMethod, ClassWithPrivateClassMethod], :methods => :all, :options => [:class, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.not_matched.size.should == 1
    actual.matched[ClassWithPublicClassMethod].should == Set.new([:public_class_test_method])
    actual.not_matched[ClassWithPrivateClassMethod].should == Set.new([:all])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (searching for instance methods)" do
  before(:each) do
    before_method_finder_specbefore
  end
  
  it "should find all public instance methods in types when searching with the :all method specification." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod], :methods => :all
    actual.matched.size.should == 3
    [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod].each do |c|
      actual.matched[c].should == Set.new(c.public_instance_methods.sort.map {|m| m.intern})
    end
  end
  
  it "should find all public instance methods in objects when searching with the :all method specification." do
    pub = ClassWithPublicInstanceMethod.new
    pro = ClassWithProtectedInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [pub, pro, pri], :methods => :all
    actual.matched.size.should == 3
    [pub, pro, pri].each do |c|
      actual.matched[c].should == Set.new(c.public_methods.sort.map {|m| m.intern})
    end
  end
  
  it "should find only one instance method for a type when searching with a regexp matching one method." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPublicInstanceMethod, :methods => /instance_test_method/
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
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
    before_method_finder_specbefore
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
    before_method_finder_specbefore
  end
  
  it "should accept :all for the methods argument and find all methods for a type subject to the method options." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPublicInstanceMethod, :method => :all, :options => :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
  end
  
  it "should accept :all for the methods argument and find all methods for an object subject to the method options." do
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :method => :all, :options => :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should ignore other method arguments if :all is present." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPublicInstanceMethod, :method => [:all, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :options => :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pub, :method => [:all, :none, /.*foo.*/], :methods =>[/.*bar.*/, /^baz/], :options => :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
  end
  
  it "should report [:all] as the not_matched value when :all is the method argument and no methods match, e.g., for :suppress_ancestor_methods." do
    actual = Aquarium::Finders::MethodFinder.new.find :type => ClassWithPrivateInstanceMethod, :method => :all, :options => :suppress_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched[ClassWithPrivateInstanceMethod].should == Set.new([:all])
    pri = ClassWithPrivateInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find :object => pri, :method => :all, :options => :suppress_ancestor_methods
    actual.matched.size.should == 0
    actual.not_matched[pri].should == Set.new([:all])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => :suppress_ancestor_methods)" do
  before(:each) do
    before_method_finder_specbefore
  end
  
  it "should suppress ancestor methods for types when :suppress_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should suppress ancestor methods for objects when :suppress_ancestor_methods is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find only public instance methods for types when :public, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find only public instance methods for objects when :public, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:protected, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find only protected instance methods when :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:protected, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should      == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find only protected instance methods for objects when :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:protected, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:private, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find only private instance methods when :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPrivateInstanceMethod].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find only private instance methods for objects when :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :class])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find only public class methods for types when :public, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :class, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicClassMethod].should == Set.new([:public_class_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find no public class methods for objects when :public, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :class, :suppress_ancestor_methods]
    actual.matched.size.should == 0
    actual.not_matched.size.should == 5
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:private, :class])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find only private class methods for types when :private, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:private, :class, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[ClassWithPrivateClassMethod].should == Set.new([:private_class_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[ClassWithPublicInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
  end

  it "should find no private class methods for objects when :private, and :class are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:private, :class, :suppress_ancestor_methods]
    actual.matched.size.should == 0
    actual.not_matched.size.should == 5
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :protected, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find public and protected instance methods for types when :public, :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :protected, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPrivateInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find public and protected instance methods for objects when :public, :protected, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :protected, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :;private, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find public and private instance methods when :public, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should  == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPrivateInstanceMethod].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithProtectedInstanceMethod].should == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should       == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should      == Set.new([/test_method/])
  end

  it "should find public and private instance methods for objects when :public, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should == Set.new([:public_instance_test_method])
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:protected, :private, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find protected and private instance methods when :protected, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:protected, :private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.matched[ClassWithPrivateInstanceMethod].should   == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPublicInstanceMethod].should   == Set.new([/test_method/])
    actual.not_matched[ClassWithPublicClassMethod].should      == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find protected and private instance methods for objects when :protected, :private, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:protected, :private, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pro].should == Set.new([:protected_instance_test_method])
    actual.matched[@pri].should == Set.new([:private_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pub].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :class, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find public class and instance methods for types when :public, :class, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :class, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[ClassWithPublicInstanceMethod].should  == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPublicClassMethod].should     == Set.new([:public_class_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[ClassWithPrivateInstanceMethod].should    == Set.new([/test_method/])
    actual.not_matched[ClassWithProtectedInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should       == Set.new([/test_method/])
  end

  it "should find only public instance methods for objects even when :class is specified along with :public and :instance." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :class, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 1
    actual.matched[@pub].should  == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 4
    actual.not_matched[@pro].should  == Set.new([/test_method/])
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
  end
end
  
describe Aquarium::Finders::MethodFinder, "#find (using :options => [:public, :protected, :class, :instance])" do
  before(:each) do
    before_method_finder_specbefore
  end

  it "should find public and protected instance methods when :public, :protected, :class, and :instance are specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => @test_classes, :methods => /test_method/, :options => [:public, :protected, :class, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 3
    actual.matched[ClassWithPublicInstanceMethod].should    == Set.new([:public_instance_test_method])
    actual.matched[ClassWithPublicClassMethod].should       == Set.new([:public_class_test_method])
    actual.matched[ClassWithProtectedInstanceMethod].should == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 2
    actual.not_matched[ClassWithPrivateInstanceMethod].should  == Set.new([/test_method/])
    actual.not_matched[ClassWithPrivateClassMethod].should     == Set.new([/test_method/])
  end

  it "should find only public and protected instance methods for objects even when :class is specified along with :public, :protected, :class, and :instance." do
    actual = Aquarium::Finders::MethodFinder.new.find :objects => @test_objects, :methods => /test_method/, :options => [:public, :protected, :class, :instance, :suppress_ancestor_methods]
    actual.matched.size.should == 2
    actual.matched[@pub].should  == Set.new([:public_instance_test_method])
    actual.matched[@pro].should  == Set.new([:protected_instance_test_method])
    actual.not_matched.size.should == 3
    actual.not_matched[@pri].should  == Set.new([/test_method/])
    actual.not_matched[@cpub].should == Set.new([/test_method/])
    actual.not_matched[@cpri].should == Set.new([/test_method/])
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
    actual = Aquarium::Finders::MethodFinder.new.find :objects => [@notQuiteEmpty, @objectWithSingletonMethod], :methods => :all, :options => [:singleton]
    actual.matched.size.should == 1
    actual.matched[@objectWithSingletonMethod].should  == Set.new([:a_singleton_method])
    actual.not_matched.size.should == 1
    actual.not_matched[@notQuiteEmpty].should  == Set.new([:all])
  end    

  it "should find type-level singleton methods for types when :singleton is specified." do
    actual = Aquarium::Finders::MethodFinder.new.find :types => [NotQuiteEmpty, Empty], :methods => :all, :options => [:singleton, :suppress_ancestor_methods]
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

describe "Aquarium::Finders::MethodFinder#find_all_by" do
  it "should accept :all for the methods argument." do
    actual = Aquarium::Finders::MethodFinder.new.find_all_by ClassWithPublicInstanceMethod, :all, :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[ClassWithPublicInstanceMethod].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 0
    pub = ClassWithPublicInstanceMethod.new
    actual = Aquarium::Finders::MethodFinder.new.find_all_by pub, :all, :suppress_ancestor_methods
    actual.matched.size.should == 1
    actual.matched[pub].should == Set.new([:public_instance_test_method])
    actual.not_matched.size.should == 0
  end
  
  it "should behave like Aquarium::Finders::MethodFinder#find with an explicit parameter list rather than a hash." do
    expected = Aquarium::Finders::MethodFinder.new.find :types => ClassWithPrivateInstanceMethod, 
      :methods => /test_method/, :options => [:private, :instance, :suppress_ancestor_methods]
    actual = Aquarium::Finders::MethodFinder.new.find_all_by ClassWithPrivateInstanceMethod, 
      /test_method/, :private, :instance, :suppress_ancestor_methods
    actual.should == expected

    expected = Aquarium::Finders::MethodFinder.new.find :objects => @pub, 
      :methods => /test_method/, :options => [:private, :instance, :suppress_ancestor_methods]
    actual = Aquarium::Finders::MethodFinder.new.find_all_by @pub, 
      /test_method/, :private, :instance, :suppress_ancestor_methods
    actual.should == expected

    expected = Aquarium::Finders::MethodFinder.new.find :types => [ClassWithPublicInstanceMethod, ClassWithPrivateInstanceMethod], 
      :methods => ["foo", /test_method/], :options => [:instance, :suppress_ancestor_methods]
    actual = Aquarium::Finders::MethodFinder.new.find_all_by [ClassWithPublicInstanceMethod, ClassWithPrivateInstanceMethod],
      ["foo", /test_method/], :instance, :suppress_ancestor_methods
    actual.should == expected

    expected = Aquarium::Finders::MethodFinder.new.find :objects => [@pub, @pri], 
      :methods => ["foo", /test_method/], :options => [:instance, :suppress_ancestor_methods]
    actual = Aquarium::Finders::MethodFinder.new.find_all_by [@pub, @pri],
      ["foo", /test_method/], :instance, :suppress_ancestor_methods
    actual.should == expected
  end
end
  
describe "Aquarium::Finders::MethodFinder.is_recognized_method_option" do

  it "should be true for :public, :private, :protected, :instance, :class, and :suppress_ancestor_methods as strings or symbols." do
    %w[public private protected instance class suppress_ancestor_methods].each do |s|
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
 