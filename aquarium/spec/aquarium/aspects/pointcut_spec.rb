require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/invalid_options'
require 'aquarium/extensions/hash'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/pointcut'
require 'aquarium/utils'

def before_exclude_spec
  @jp11  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method11
  @jp12  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method12
  @jp13  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestOne,   :method_name => :method13
  @jp21  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method21
  @jp22  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method22
  @jp23  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestTwo,   :method_name => :method23
  @jp31  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestThree, :method_name => :method31
  @jp32  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestThree, :method_name => :method32
  @jp33  = Aquarium::Aspects::JoinPoint.new :type   => ExcludeTestThree, :method_name => :method33
  @et1 = ExcludeTestOne.new
  @et2 = ExcludeTestTwo.new
  @et3 = ExcludeTestThree.new
  @ojp11 = Aquarium::Aspects::JoinPoint.new :object => @et1, :method_name => :method11
  @ojp12 = Aquarium::Aspects::JoinPoint.new :object => @et1, :method_name => :method12
  @ojp13 = Aquarium::Aspects::JoinPoint.new :object => @et1, :method_name => :method13
  @ojp21 = Aquarium::Aspects::JoinPoint.new :object => @et2, :method_name => :method21
  @ojp22 = Aquarium::Aspects::JoinPoint.new :object => @et2, :method_name => :method22
  @ojp23 = Aquarium::Aspects::JoinPoint.new :object => @et2, :method_name => :method23
  @ojp31 = Aquarium::Aspects::JoinPoint.new :object => @et3, :method_name => :method31
  @ojp32 = Aquarium::Aspects::JoinPoint.new :object => @et3, :method_name => :method32
  @ojp33 = Aquarium::Aspects::JoinPoint.new :object => @et3, :method_name => :method33
  @all_type_jps   = [@jp11,  @jp12,  @jp13,  @jp21,  @jp22,  @jp23,  @jp31,  @jp32,  @jp33]
  @all_object_jps = [@ojp11, @ojp12, @ojp13, @ojp21, @ojp22, @ojp23, @ojp31, @ojp32, @ojp33]
  @all_jps = @all_type_jps + @all_object_jps
end

def before_pointcut_spec
  @example_types_without_public_instance_method = 
  [ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod, ClassWithPublicClassMethod, ClassWithPrivateClassMethod]
  @example_types = ([ClassWithPublicInstanceMethod] + @example_types_without_public_instance_method)
  @pub_jp   = Aquarium::Aspects::JoinPoint.new :type => ClassWithPublicInstanceMethod,    :method_name => :public_instance_test_method
  @pro_jp   = Aquarium::Aspects::JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method_name => :protected_instance_test_method
  @pri_jp   = Aquarium::Aspects::JoinPoint.new :type => ClassWithPrivateInstanceMethod,   :method_name => :private_instance_test_method
  @cpub_jp  = Aquarium::Aspects::JoinPoint.new :type => ClassWithPublicClassMethod,       :method_name => :public_class_test_method, :class_method => true
  @cpri_jp  = Aquarium::Aspects::JoinPoint.new :type => ClassWithPrivateClassMethod,      :method_name => :private_class_test_method, :class_method => true
  @apro_jp  = Aquarium::Aspects::JoinPoint.new :type => ClassWithProtectedInstanceMethod, :method_name => :all
  @apri_jp  = Aquarium::Aspects::JoinPoint.new :type => ClassWithPrivateInstanceMethod,   :method_name => :all
  @acpub_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithPublicClassMethod,       :method_name => :all
  @acpri_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithPrivateClassMethod,      :method_name => :all
  @expected_matched_jps = Set.new [@pub_jp]
  @expected_not_matched_jps = Set.new [@apro_jp, @apri_jp, @acpub_jp, @acpri_jp]
end

describe Aquarium::Aspects::Pointcut, ".new (invalid arguments)" do
  it "should raise if an unknown argument is specified" do
    lambda { Aquarium::Aspects::Pointcut.new :foo => :bar }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Aquarium::Aspects::Pointcut, ".new (empty)" do
  it "should match no join points by default." do
    pc = Aquarium::Aspects::Pointcut.new
    pc.should be_empty
  end

  it "should match no join points if nil is the only argument specified." do
    pc = Aquarium::Aspects::Pointcut.new nil
    pc.should be_empty
  end

  it "should match no join points if types = [] specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => []
    pc.should be_empty
  end
  
  it "should match no join points if types = nil specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => nil
    pc.should be_empty
  end
  
  it "should match no join points if objects = [] specified." do
    pc = Aquarium::Aspects::Pointcut.new :objects => []
    pc.should be_empty
  end
  
  it "should match no join points if objects = nil specified." do
    pc = Aquarium::Aspects::Pointcut.new :objects => nil
    pc.should be_empty
  end
  
  it "should match no join points if join_points = nil specified." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => nil
    pc.should be_empty
  end
  
  it "should match no join points if join_points = [] specified." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => []
    pc.should be_empty
  end
end

describe Aquarium::Aspects::Pointcut, "#empty?" do
  it "should be true if there are no matched and no unmatched join points." do
    pc = Aquarium::Aspects::Pointcut.new
    pc.join_points_matched.size.should == 0
    pc.join_points_not_matched.size.should == 0
    pc.should be_empty
  end
  
  it "should be false if there are matched join points." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ClassWithAttribs], :methods => [/^attr/]
    pc.join_points_matched.size.should > 0
    pc.join_points_not_matched.size.should == 0
    pc.should_not be_empty
  end
  
  it "should be false if there are unmatched join points." do
    pc = Aquarium::Aspects::Pointcut.new :types => [String], :methods => [/^attr/]
    pc.join_points_matched.size.should == 0
    pc.join_points_not_matched.size.should > 0
    pc.should_not be_empty
  end
end

describe Aquarium::Aspects::Pointcut, " (types specified using regular expressions)" do
  before(:each) do
    before_pointcut_spec
  end

  it "should match multiple types using regular expressions that cover the full class names." do
    pc = Aquarium::Aspects::Pointcut.new :types => /Class.*Method\Z/, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end

  it "should match types using regular expressions that only cover partial class names." do
    pc = Aquarium::Aspects::Pointcut.new :types => /lass.*Pro.*Inst.*Met/, :method_options => [:public, :protected, :exclude_ancestor_methods]
    pc.join_points_matched.should == Set.new([@pro_jp])
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (types specified using names)" do
  before(:each) do
    before_pointcut_spec
  end

  it "should match multiple types using names." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types.map {|t| t.to_s}, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end
  
  it "should match multiple types using types themselves." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end
  
  it "should match :all public instance methods for types by default." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end

  it "should support MethodFinder's :exclude_ancestor_methods option when using types." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end
end

describe Aquarium::Aspects::Pointcut, " (types and their descendents)" do
  before(:each) do
    before_pointcut_spec
  end

  it "should match the types specified and their descendents." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types.map {|t| t.to_s}, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == @expected_matched_jps
    pc.join_points_not_matched.should == @expected_not_matched_jps
  end
end
  
describe Aquarium::Aspects::Pointcut, " (objects specified)" do
  before(:each) do
    before_pointcut_spec
  end

  it "should match :all public instance methods for objects by default." do
    pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => [pub, pro], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
    pc.join_points_not_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => pro, :method_name => :all)])
  end
  
  it "should support MethodFinder's :exclude_ancestor_methods option when using objects." do
    pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => [pub, pro], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
    pc.join_points_not_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => pro, :method_name => :all)])
  end
  
  it "should match all possible methods on the specified objects." do
    pub, pro = ClassWithPublicInstanceMethod.new, ClassWithProtectedInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => [pub, pro], :methods => :all, :method_options => [:public, :protected, :exclude_ancestor_methods]
    pc.join_points_matched.size.should == 2
    pc.join_points_not_matched.size.should == 0
    pc.join_points_matched.should == Set.new([
        Aquarium::Aspects::JoinPoint.new(:object => pro, :method_name => :protected_instance_test_method),
        Aquarium::Aspects::JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)])
  end  
  
  it "does confuse strings specified with :objects as type names." do
    string = "mystring"
    lambda { Aquarium::Aspects::Pointcut.new :object => string, :methods => :capitalize }.should raise_error(NameError)
  end  
  
  it "does confuse symbols specified with :objects as type names." do
    symbol = :mystring
    lambda { Aquarium::Aspects::Pointcut.new :object => symbol, :methods => :capitalize }.should raise_error(NameError)
  end  
end

describe Aquarium::Aspects::Pointcut, " (:exclude_types => types specified)" do
  before(:each) do
    before_exclude_spec
  end
  
  it "should remove from a list of explicitly-specified types the set of explicitly-specified excluded types." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from a list of explicitly-specified types the set of excluded types specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_types => /Two$/, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from a list of explicitly-specified types the set of excluded types specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the types specified by regular expression the explicitly-specified excluded types." do
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the types specified by regular expression the excluded types specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_type => /Two$/, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the types specified by regular expression the excluded types specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the join points corresponding to the excluded types, specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_type_jps, :exclude_type => "ExcludeTestTwo", :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove the specified join points corresponding to the excluded types, specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_type_jps, :exclude_type => /Exclude.*Two/, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 2
    actual.should include(ExcludeTestOne)
    actual.should include(ExcludeTestThree)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should not add excluded types to the #not_matched results." do
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_type => ExcludeTestTwo, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should be a synonym for :exclude_type." do
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_types => [ExcludeTestTwo, ExcludeTestThree], :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 1
    actual.should include(ExcludeTestOne)
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (:exclude_objects => objects specified)" do
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
    pc = Aquarium::Aspects::Pointcut.new :objects => @objects, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 4
    [@e11, @e12, @e21, @e32].each {|e| actual.should include(e)}
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove the specified join points corresponding to the excluded objects." do
    jps11 = Aquarium::Aspects::JoinPoint.new :object => @e11, :method => :method11
    jps21 = Aquarium::Aspects::JoinPoint.new :object => @e21, :method => :method21
    jps22 = Aquarium::Aspects::JoinPoint.new :object => @e22, :method => :method22
    jps31 = Aquarium::Aspects::JoinPoint.new :object => @e31, :method => :method31
    jps = [jps11, jps21, jps22, jps31]
    pc = Aquarium::Aspects::Pointcut.new :join_points => jps, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 2
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    [@e11, @e21].each {|e| actual.should include(e)}
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should not add excluded objects to the #not_matched results." do
    pc = Aquarium::Aspects::Pointcut.new :objects => @objects, :exclude_objects => [@e22, @e31], :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should be a synonym for :exclude_object." do
    pc = Aquarium::Aspects::Pointcut.new :objects => @objects, :exclude_object => @e22, :method_options => :exclude_ancestor_methods
    actual = pc.join_points_matched.collect {|jp| jp.type_or_object}.uniq
    actual.size.should == 5
    [@e11, @e12, @e21, @e31, @e32].each {|e| actual.should include(e)}
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (:exclude_join_points => join_points specified)" do
  before(:each) do
    before_exclude_spec
  end

  it "should remove from a list of explicitly-specified join points the set of explicitly-specified excluded join points." do
    excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_join_points => excluded
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the list of generated, type-based join points the set of explicitly-specified excluded join points." do
    excluded = [@jp11, @jp22, @jp33]
    expected = [@jp12, @jp13, @jp21, @jp23, @jp31, @jp32]
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_join_points => excluded, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end

  it "should remove from the list of generated, object-based join points the set of explicitly-specified excluded join points." do
    excluded = [@ojp12, @ojp23, @ojp31]  
    expected = [@ojp11, @ojp13, @ojp21, @ojp22, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :objects => [@et1, @et2, @et3], :exclude_join_points => excluded, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should not add excluded types to the #not_matched results." do
    excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_join_points => excluded
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should be a synonym for :exclude_join_point." do
    excluded = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_join_point => excluded
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
end


describe Aquarium::Aspects::Pointcut, " (:exclude_pointcuts => pointcuts specified)" do
  before(:each) do
    before_exclude_spec
  end

  it "should remove from a list of explicitly-specified join points the set of explicitly-specified excluded pointcuts." do
    excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    excluded = Aquarium::Aspects::Pointcut.new :join_points => excluded_jps
    expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_pointcuts => excluded
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the list of generated, type-based join points the set of explicitly-specified excluded pointcuts." do
    excluded_jps = [@jp11, @jp22, @jp33]
    excluded = Aquarium::Aspects::Pointcut.new :join_points => excluded_jps
    expected = [@jp12, @jp13, @jp21, @jp23, @jp31, @jp32]
    pc = Aquarium::Aspects::Pointcut.new :types => /ExcludeTest/, :exclude_pointcuts => excluded, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove from the list of generated, object-based join points the set of explicitly-specified excluded pointcuts." do
    excluded_jps = [@ojp12, @ojp23, @ojp31]  
    excluded = Aquarium::Aspects::Pointcut.new :join_points => excluded_jps
    expected = [@ojp11, @ojp13, @ojp21, @ojp22, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :objects => [@et1, @et2, @et3], :exclude_pointcuts => excluded, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should not add excluded types to the #not_matched results." do
    excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    excluded = Aquarium::Aspects::Pointcut.new :join_points => excluded_jps
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_pointcuts => excluded
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should result in an empty pointcut if the join points in the :exclude_pointcuts are a superset of the matched join points." do
    excluded = Aquarium::Aspects::Pointcut.new :join_points => @all_jps
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_pointcut => excluded
    pc.join_points_matched.size.should == 0
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should be a synonym for :exclude_pointcut." do
    excluded_jps = [@jp12, @jp33, @ojp11, @ojp13, @ojp23]
    excluded = Aquarium::Aspects::Pointcut.new :join_points => excluded_jps
    expected = [@jp11, @jp13, @jp21, @jp22, @jp23, @jp31, @jp32, @ojp12, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33]
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_pointcut => excluded
    pc.join_points_matched.should == Set.new(expected)
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with public instance methods)" do
  before(:each) do
    before_pointcut_spec
  end

  it "should support MethodFinder's :public and :instance options for the specified types." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithPublicInstanceMethod, :method_options => [:public, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([@pub_jp]))
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should support MethodFinder's :public and :instance options for the specified objects." do
    pub = ClassWithPublicInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => pub, :method_options => [:public, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([Aquarium::Aspects::JoinPoint.new(:object => pub, :method_name => :public_instance_test_method)]))
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with protected instance methods)" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should support MethodFinder's :protected and :instance options for the specified types." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithProtectedInstanceMethod, :method_options => [:protected, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([@pro_jp]))
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should support MethodFinder's :protected and :instance options for the specified objects." do
    pro = ClassWithProtectedInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => pro, :method_options => [:protected, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([Aquarium::Aspects::JoinPoint.new(:object => pro, :method_name => :protected_instance_test_method)]))
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with private instance methods)" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should support MethodFinder's :private and :instance options for the specified types." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithPrivateInstanceMethod, :method_options => [:private, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([@pri_jp]))
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should support MethodFinder's :private and :instance options for the specified objects." do
    pro = ClassWithPrivateInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => pro, :method_options => [:private, :instance, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([Aquarium::Aspects::JoinPoint.new(:object => pro, :method_name => :private_instance_test_method)]))
    pc.join_points_not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with public class methods)" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should support MethodFinder's :public and :class options for the specified types." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithPublicClassMethod, :method_options => [:public, :class, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([@cpub_jp]))
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should support MethodFinder's :public and :class options for the specified objects, which will return no methods." do
    pub = ClassWithPublicInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => pub, :method_options => [:public, :class, :exclude_ancestor_methods]
    pc.join_points_matched.size.should == 0
    pc.join_points_not_matched.size.should == 1
    pc.join_points_not_matched.should be_eql(Set.new([Aquarium::Aspects::JoinPoint.new(:object => pub, :method_name => :all, :class_method => true)]))
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with private class methods)" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should support MethodFinder's :private and :class options for the specified types." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithPrivateClassMethod, :method_options => [:private, :class, :exclude_ancestor_methods]
    pc.join_points_matched.should be_eql(Set.new([@cpri_jp]))
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should support MethodFinder's :private and :class options for the specified objects, which will return no methods." do
    pri = ClassWithPrivateInstanceMethod.new
    pc = Aquarium::Aspects::Pointcut.new :objects => pri, :method_options => [:private, :class, :exclude_ancestor_methods]
    pc.join_points_not_matched.should be_eql(Set.new([Aquarium::Aspects::JoinPoint.new(:object => pri, :method_name => :all, :class_method => true)]))
    pc.join_points_not_matched.size.should == 1
  end
end

describe Aquarium::Aspects::Pointcut, " (types or objects specified with method regular expressions)" do
  before(:each) do
    before_pointcut_spec
    @jp_rwe = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
    @jp_rw  = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
    @jp_we  = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
    @jp_r   = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
    @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
    @object_of_ClassWithAttribs = ClassWithAttribs.new
    @jp_rwe_o = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
    @jp_rw_o  = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
    @jp_we_o  = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
    @jp_r_o   = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
    @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
  end
  
  it "should match on public method readers and writers for type names by default." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :methods => [/^attr/]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match on public method readers and writers for types by default." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :methods => [/^attr/]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match on public method readers and writers for objects by default." do
    pc = Aquarium::Aspects::Pointcut.new :object => @object_of_ClassWithAttribs, :methods => [/^attr/]
    pc.join_points_matched.should == @expected_for_objects
  end
end

describe Aquarium::Aspects::Pointcut, " (:exclude_methods => methods specified)" do
  before(:each) do
    before_exclude_spec
  end
  
  it "should remove type-specified JoinPoints matching the excluded methods specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 7
    pc.join_points_matched.should == Set.new([@jp12, @jp13, @jp21, @jp22, @jp31, @jp32, @jp33])
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove type-specified JoinPoints matching the excluded methods specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :types => [ExcludeTestOne, ExcludeTestTwo, ExcludeTestThree], :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 5
    pc.join_points_matched.should == Set.new([@jp12, @jp22, @jp31, @jp32, @jp33])
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove object-specified JoinPoints matching the excluded methods specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :objects => [@et1, @et2, @et3], :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 7
    pc.join_points_matched.should == Set.new([@ojp12, @ojp13, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33])
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove object-specified JoinPoints matching the excluded methods specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :objects => [@et1, @et2, @et3], :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 5
    pc.join_points_matched.should == Set.new([@ojp12, @ojp22, @ojp31, @ojp32, @ojp33])
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove join-point-specified JoinPoints matching the excluded methods specified by name." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_methods => [:method11, :method23], :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 14
    pc.join_points_matched.should == Set.new([@jp12, @jp13, @jp21, @jp22, @jp31, @jp32, @jp33, @ojp12, @ojp13, @ojp21, @ojp22, @ojp31, @ojp32, @ojp33])
    pc.join_points_not_matched.size.should == 0
  end
  
  it "should remove join-point-specified JoinPoints matching the excluded methods specified by regular expression." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => @all_jps, :exclude_methods => /method[12][13]/, :method_options => :exclude_ancestor_methods
    pc.join_points_matched.size.should == 10
    pc.join_points_matched.should == Set.new([@jp12, @jp22, @jp31, @jp32, @jp33, @ojp12, @ojp22, @ojp31, @ojp32, @ojp33])
    pc.join_points_not_matched.size.should == 0
  end
end
  
describe Aquarium::Aspects::Pointcut, " (types or objects specified with attribute regular expressions)" do
  before(:each) do
    before_pointcut_spec
    @jp_rwe = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
    @jp_rw  = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
    @jp_we  = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
    @jp_r   = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
    @expected_for_types = Set.new([@jp_rw, @jp_rwe, @jp_r, @jp_we])
    @object_of_ClassWithAttribs = ClassWithAttribs.new
    @jp_rwe_o = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs=
    @jp_rw_o  = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrRW_ClassWithAttribs
    @jp_we_o  = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrW_ClassWithAttribs=
    @jp_r_o   = Aquarium::Aspects::JoinPoint.new :object => @object_of_ClassWithAttribs, :method_name => :attrR_ClassWithAttribs
    @expected_for_objects = Set.new([@jp_rw_o, @jp_rwe_o, @jp_r_o, @jp_we_o])
  end
  
  it "should match on public attribute readers and writers for type names by default." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/]
    pc.join_points_matched.size.should == 4
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match on public attribute readers and writers for types by default." do
    pc = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match on public attribute readers and writers for objects by default." do
    pc = Aquarium::Aspects::Pointcut.new :object => @object_of_ClassWithAttribs, :attributes => [/^attr/]
    pc.join_points_matched.should == @expected_for_objects
  end
  
  it "should match attribute specifications for types that are prefixed with @." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^@attr.*ClassWithAttribs/]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match attribute specifications for objects that are prefixed with @." do
    pc = Aquarium::Aspects::Pointcut.new :object => @object_of_ClassWithAttribs, :attributes => [/^@attr.*ClassWithAttribs/]
    pc.join_points_matched.should == @expected_for_objects
  end
  
  it "should match attribute specifications that are regular expressions of symbols." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^:attr.*ClassWithAttribs/]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match attribute specifications for objects that are regular expressions of symbols." do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match public attribute readers and writers for types when both the :readers and :writers options are specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:readers, :writers]
    pc.join_points_matched.should == @expected_for_types
  end
  
  it "should match public attribute readers and writers for objects when both the :readers and :writers options are specified." do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:readers, :writers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match public attribute readers for types only when the :readers option is specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:readers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
  end
  
  it "should match public attribute readers for objects only when the :readers option is specified." do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:readers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
  end
  
  it "should match public attribute writers for types only when the :writers option is specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr.*ClassWithAttribs/], :attribute_options => [:writers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match public attribute writers for objects only when the :writers option is specified." do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^:attr.*ClassWithAttribs/], :attribute_options => [:writers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match attribute writers for types whether or not the attributes specification ends with an equal sign." do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", 
      :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:writers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
    pc2 = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", 
      :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:writers]
    pc2.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match attribute writers for objects whether or not the attributes specification ends with an equal sign." do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:writers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
    pc2 = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:writers]
    pc2.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs=),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrW_ClassWithAttribs=)])
  end
  
  it "should match attribute readers for types when the :readers option is specified even if the attributes specification ends with an equal sign!" do
    pc = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", 
      :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
    pc2 = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", 
      :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
    pc2.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:type => "ClassWithAttribs", :method_name => :attrR_ClassWithAttribs)])
  end
  
  it "should match attribute readers for objects when the :readers option is specified even if the attributes specification ends with an equal sign!" do
    object = ClassWithAttribs.new
    pc = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs=/], :attribute_options => [:readers]
    pc.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
    pc2 = Aquarium::Aspects::Pointcut.new :object => object, :attributes => [/^attr[RW]+_ClassWithAttribs/], :attribute_options => [:readers]
    pc2.join_points_matched.should == Set.new([
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrRW_ClassWithAttribs),
      Aquarium::Aspects::JoinPoint.new(:object => object, :method_name => :attrR_ClassWithAttribs)])
  end  
end

describe Aquarium::Aspects::Pointcut, " (join points specified)" do
  before(:each) do
    before_pointcut_spec
    @anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
    @expected_matched = [@pub_jp, @pro_jp, @pri_jp, @cpub_jp, @cpri_jp,
        Aquarium::Aspects::JoinPoint.new(:object => @anClassWithPublicInstanceMethod, :method => :public_instance_test_method)]
    @expected_not_matched = [
      Aquarium::Aspects::JoinPoint.new(:type   => ClassWithPublicInstanceMethod,    :method => :foo),
      Aquarium::Aspects::JoinPoint.new(:object => @anClassWithPublicInstanceMethod, :method => :foo)]
  end

  it "should return matches only for existing join points." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => (@expected_matched + @expected_not_matched)
    pc.join_points_matched.should == Set.new(@expected_matched)
  end

  it "should return non-matches for non-existing join points." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => (@expected_matched + @expected_not_matched)
    pc.join_points_not_matched.should == Set.new(@expected_not_matched)
  end

  it "should ignore :methods, :attributes, :method_options, and :attribute_options for the join points specified." do
    pc = Aquarium::Aspects::Pointcut.new :join_points => (@expected_matched + @expected_not_matched),
      :methods => :kind_of?, :attributes => :name, :method_options => [:class], :attribute_options => [:readers]
    pc.join_points_matched.should == Set.new(@expected_matched)
    pc.join_points_not_matched.should == Set.new(@expected_not_matched)
  end
end

describe Aquarium::Aspects::Pointcut, " (methods that end in non-alphanumeric characters)" do
  class ClassWithFunkyMethodNames
    def huh?; true; end
    def yes!; true; end
    def x= other; false; end
    def == other; false; end
    def =~ other; false; end
  end
  
  before(:each) do
    @funky = ClassWithFunkyMethodNames.new
  end  

  {'?' => :huh?, '!' => :yes!, '=' => :x=}.each do |char, method|
    it "should match instance methods for types when searching for names that end with a '#{char}' character." do
      pc = Aquarium::Aspects::Pointcut.new :types => ClassWithFunkyMethodNames, :method => method, :method_options => [:exclude_ancestor_methods]
      expected_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end

    it "should match instance methods for objects when searching for names that end with a '#{char}' character." do
      pc = Aquarium::Aspects::Pointcut.new :object => @funky, :method => method, :method_options => [:exclude_ancestor_methods]
      expected_jp = Aquarium::Aspects::JoinPoint.new :object => @funky, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end

    it "should match instance methods for types when searching for names that end with a '#{char}' character, using a regular expressions." do
      pc = Aquarium::Aspects::Pointcut.new :types => ClassWithFunkyMethodNames, :methods => /#{Regexp.escape(char)}$/, :method_options => [:exclude_ancestor_methods]
      expected_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end

    it "should match instance methods for object when searching for names that end with a '#{char}' character, using a regular expressions." do
      pc = Aquarium::Aspects::Pointcut.new :object => @funky, :methods => /#{Regexp.escape(char)}$/, :method_options => [:exclude_ancestor_methods]
      expected_jp = Aquarium::Aspects::JoinPoint.new :object => @funky, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end
  end

  {'=' => :==, '~' => :=~}.each do |char, method|
    it "should match the #{method} instance method for types, if you don't suppress ancestor methods, even if the method is defined in the class!" do
      pc = Aquarium::Aspects::Pointcut.new :types => ClassWithFunkyMethodNames, :method => method, :method_options => [:instance]
      expected_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithFunkyMethodNames, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end
  
    it "should match the #{method} instance method for objects, if you don't suppress ancestor methods, even if the method is defined in the class!" do
      pc = Aquarium::Aspects::Pointcut.new :object => @funky, :method => method, :method_options => [:instance]
      expected_jp = Aquarium::Aspects::JoinPoint.new :object => @funky, :method_name => method
      pc.join_points_matched.should == Set.new([expected_jp])
    end

    it "should match the #{method} instance method for types when using a regular expressions, if you don't suppress ancestor methods, even if the method is defined in the class!" do
      pc = Aquarium::Aspects::Pointcut.new :types => ClassWithFunkyMethodNames, :methods => /#{Regexp.escape(char)}$/, :method_options => [:instance]
      pc.join_points_matched.any? {|jp| jp.method_name == method}.should be_true
    end

    it "should match the #{method} instance method for objects when using a regular expressions, if you don't suppress ancestor methods, even if the method is defined in the class!" do
      pc = Aquarium::Aspects::Pointcut.new :object => @funky, :methods => /#{Regexp.escape(char)}$/, :method_options => [:instance]
      pc.join_points_matched.any? {|jp| jp.method_name == method}.should be_true
    end
  end
end
  
describe Aquarium::Aspects::Pointcut, " (:attributes => :all option not yet supported)" do
  
  it "should raise if :all is used for attributes for types (not yet supported)." do
    lambda { Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => :all }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should raise if :all is used for attributes for objects (not yet supported)." do
    lambda { Aquarium::Aspects::Pointcut.new :object => ClassWithAttribs.new, :attributes => :all }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe "Aquarium::Aspects::Pointcut" do
  
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
    pc = Aquarium::Aspects::Pointcut.new :objects => [@notQuiteEmpty, @objectWithSingletonMethod], :methods => :all, :method_options => [:singleton]
    pc.join_points_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => @objectWithSingletonMethod, :method_name => :a_singleton_method)])
    pc.join_points_not_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:object => @notQuiteEmpty, :method_name => :all)])
  end    
  
  it "should find type-level singleton methods for types when :singleton is specified." do
    pc = Aquarium::Aspects::Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :exclude_ancestor_methods]
    pc.join_points_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:type => NotQuiteEmpty, :method_name => :a_class_singleton_method)])
    pc.join_points_not_matched.should == Set.new([Aquarium::Aspects::JoinPoint.new(:type => Empty, :method_name => :all)])
  end
  
  it "should raise when specifying method options :singleton with :class, :public, :protected, or :private." do
    lambda { Aquarium::Aspects::Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :class]}.should     raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :public]}.should    raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :protected]}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { Aquarium::Aspects::Pointcut.new :types => [NotQuiteEmpty, Empty], :methods => :all, :method_options => [:singleton, :private]}.should    raise_error(Aquarium::Utils::InvalidOptions)
  end    
end
  

describe Aquarium::Aspects::Pointcut, "#eql?" do  
  it "should return true for the same Aquarium::Aspects::Pointcut object." do
    pc = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc.should be_eql(pc)
    pc1 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
    pc1.should be_eql(pc1)
  end
  
  it "should return true for Aquarium::Aspects::Pointcuts that specify the same types and methods." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc1.should be_eql(pc2)
  end
  
  it "should return false if the matched types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /ClassWithPublicMethod/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/
    pc1.should_not eql(pc2)
  end
  
  it "should return false for Aquarium::Aspects::Pointcuts that specify different types, even if no methods match." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /ClassWithPublicMethod/, :methods => /foobar/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/        , :methods => /foobar/
    pc1.should_not eql(pc2)
  end
  
  it "should return false for Aquarium::Aspects::Pointcuts that specify different methods." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /ClassWithPublicMethod/, :methods =>/^private/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /ClassWithPublicMethod/, :methods =>/^public/
    pc1.should_not eql(pc2)
  end
  
  it "should return false for Aquarium::Aspects::Pointcuts that specify equivalent objects that are not the same object." do
    pc1 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
    pc1.should_not eql(pc2)
  end
  
  it "should return false for Aquarium::Aspects::Pointcuts that specify equivalent objects that are not the same object, even if no methods match." do
    pc1 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /foobar/
    pc2 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /foobar/
    pc1.should_not eql(pc2)
  end
  
  it "should return false if the matched objects are different objects." do
    pc1 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPublicClassMethod.new, :methods => /_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :object => ClassWithPrivateClassMethod.new, :methods => /_test_method$/
    pc1.should_not eql(pc2)
  end

  it "should return true if the matched objects are the same object." do
    object = ClassWithPublicClassMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new  :object => object, :methods => /_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :object => object, :methods => /_test_method$/
    pc1.should eql(pc2)
  end

  it "should return false if the not_matched types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => :UnknownFoo
    pc2 = Aquarium::Aspects::Pointcut.new  :types => :UnknownBar
    pc1.should_not eql(pc2)
  end

  it "should return false if the matched methods for the same types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /public.*_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc1.should_not == pc2
  end

  it "should return false if the matched methods for the same objects are different." do
    pub = ClassWithPublicInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :methods => /public.*_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :methods => /_test_method$/
    pc1.should_not == pc2
  end

  it "should return false if the not_matched methods for the same types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /foo/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /bar/
    pc1.should_not == pc2
  end

  it "should return false if the not_matched methods for the same objects are different." do
    pub = ClassWithPublicInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :methods => /foo/
    pc2 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :methods => /bar/
    pc1.should_not == pc2
  end

  it "should return false if the matched attributes for the same types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :attributes => /attrRW/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :attributes => /attrR/
    pc1.should_not == pc2
  end

  it "should return false if the matched attributes for the same objects are different." do
    pub = ClassWithPublicInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :attributes => /attrRW/
    pc2 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :attributes => /attrR/
    pc1.should_not == pc2
  end

  it "should return false if the not_matched attributes for the same types are different." do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :attributes => /foo/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :attributes => /bar/
    pc1.should_not == pc2
  end

  it "should return false if the not_matched attributes for the same objects are different." do
    pub = ClassWithPublicInstanceMethod.new
    pri = ClassWithPrivateInstanceMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :attributes => /foo/
    pc2 = Aquarium::Aspects::Pointcut.new  :objects => [pub, pri], :attributes => /bar/
    pc1.should_not == pc2
  end
end

describe "Aquarium::Aspects::Pointcut#eql?" do
  it "should be an alias for #==" do
    pc1 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc2 = Aquarium::Aspects::Pointcut.new  :types => /Class.*Method/, :methods => /_test_method$/
    pc3 = Aquarium::Aspects::Pointcut.new  :objects => [ClassWithPublicInstanceMethod.new, ClassWithPublicInstanceMethod.new]
    pc1.should be_eql(pc1)
    pc1.should be_eql(pc2)
    pc1.should_not eql(pc3)
    pc2.should_not eql(pc3)
  end
end

describe Aquarium::Aspects::Pointcut, "#candidate_types" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should return only candidate matching types when the input types exist." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types 
    pc.candidate_types.matched_keys.sort {|x,y| x.to_s <=> y.to_s}.should == @example_types.sort {|x,y| x.to_s <=> y.to_s}
    pc.candidate_types.not_matched_keys.should == []
  end

  it "should return only candidate matching types when the input type names correspond to existing types." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types.map {|t| t.to_s}
    pc.candidate_types.matched_keys.sort {|x,y| x.to_s <=> y.to_s}.should == @example_types.sort {|x,y| x.to_s <=> y.to_s}
    pc.candidate_types.not_matched_keys.should == []
  end

  it "should return only candidate non-matching types when the input types do not exist." do
    pc = Aquarium::Aspects::Pointcut.new :types => 'NonExistentClass'
    pc.candidate_types.matched_keys.should == []
    pc.candidate_types.not_matched_keys.should == ['NonExistentClass']
  end

  it "should return no candidate matching or non-matching types when only objects are input." do
    pc = Aquarium::Aspects::Pointcut.new :objects => @example_types.map {|t| t.new}
    pc.candidate_types.matched_keys.should == []
    pc.candidate_types.not_matched_keys.should == []
  end
end

describe Aquarium::Aspects::Pointcut, "#candidate_objects" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should return only candidate matching objects when the input are objects." do
    example_objs = @example_types.map {|t| t.new}
    pc = Aquarium::Aspects::Pointcut.new :objects => example_objs
    example_objs.each do |obj|
      pc.candidate_objects.matched[obj].should_not be(nil?)
    end
    pc.candidate_objects.not_matched_keys.should == []
  end
end

describe Aquarium::Aspects::Pointcut, "#candidate_join_points" do
  before(:each) do
    before_pointcut_spec
  end
  
  it "should return only candidate non-matching join points for the input join points that do not exist." do
    anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
    example_jps = [
      Aquarium::Aspects::JoinPoint.new(:type   => ClassWithPublicInstanceMethod,   :method => :foo),
      Aquarium::Aspects::JoinPoint.new(:object => anClassWithPublicInstanceMethod, :method => :foo)]
    pc = Aquarium::Aspects::Pointcut.new :join_points => example_jps
    pc.candidate_join_points.matched.size.should == 0
    pc.candidate_join_points.not_matched[example_jps[0]].should_not be_nil
    pc.candidate_join_points.not_matched[example_jps[1]].should_not be_nil
  end
  
  it "should return only candidate matching join points for the input join points that do exist." do
    anClassWithPublicInstanceMethod = ClassWithPublicInstanceMethod.new
    example_jps = [
      Aquarium::Aspects::JoinPoint.new(:type   => ClassWithPublicInstanceMethod,   :method => :public_instance_test_method),
      Aquarium::Aspects::JoinPoint.new(:object => anClassWithPublicInstanceMethod, :method => :public_instance_test_method)]
    pc = Aquarium::Aspects::Pointcut.new :join_points => example_jps
    pc.candidate_join_points.matched.size.should == 2
    pc.candidate_join_points.matched[example_jps[0]].should_not be_nil
    pc.candidate_join_points.matched[example_jps[1]].should_not be_nil
    pc.candidate_join_points.not_matched.size.should == 0
  end
end

describe Aquarium::Aspects::Pointcut, "#specification" do
  before(:each) do
    before_pointcut_spec
    @empty_set = Set.new
    @default_specification = {
      :types => @empty_set, :objects => @empty_set, :join_points => @empty_set,
      :methods => @empty_set, :method_options => @empty_set,
      :attributes => @empty_set, :attribute_options => @empty_set, 
      :exclude_types => @empty_set,
      :exclude_objects => @empty_set,
      :exclude_join_points => @empty_set,
      :exclude_pointcuts => @empty_set,
      :exclude_methods => @empty_set,
      :default_objects => @empty_set} 
    @default_specification_all_methods = { :methods => Set.new([:all]) } | @default_specification
  end

  it "should return ':attribute_options => []', by default, if no arguments are given." do
    pc = Aquarium::Aspects::Pointcut.new
    pc.specification.should == @default_specification_all_methods
  end

  it "should return the input :types and :type arguments combined into an array keyed by :types." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :type => String
    pc.specification.should == { :types => Set.new(@example_types + [String]) } | @default_specification_all_methods
  end
  
  it "should return the input :objects and :object arguments combined into an array keyed by :objects." do
    example_objs = @example_types.map {|t| t.new}
    s1234 = "1234"
    pc = Aquarium::Aspects::Pointcut.new :objects => example_objs, :object => s1234
    pc.specification.should == { :objects => Set.new(example_objs + [s1234]) } | @default_specification_all_methods
  end

  it "should return the input :methods and :method arguments combined into an array keyed by :methods." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :methods => /^get/, :method => "dup"
    pc.specification.should == { :types => Set.new(@example_types), :methods => Set.new([/^get/, "dup"]) } | @default_specification
  end
  
  it "should return the input :method_options verbatim." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :methods => /^get/, :method => "dup", :method_options => [:instance, :public]
    pc.specification.should == { :types => Set.new(@example_types), :methods => Set.new([/^get/, "dup"]), 
        :method_options => Set.new([:instance, :public]), :default_objects => @empty_set } | @default_specification
  end
  
  it "should return the input :methods and :method arguments combined into an array keyed by :methods." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :attributes => /^state/, :attribute => "name"
    pc.specification.should == { :types => Set.new(@example_types), :objects => @empty_set, :join_points => @empty_set,
      :methods => @empty_set, :method_options => Set.new([]), :default_objects => @empty_set,
      :attributes => Set.new([/^state/, "name"]), :attribute_options => @empty_set } | @default_specification
  end
  
  it "should return the input :attributes, :attribute and :attribute_options arguments, verbatim." do
    pc = Aquarium::Aspects::Pointcut.new :types => @example_types, :attributes => /^state/, :attribute => "name", :attribute_options => :reader
    pc.specification.should == { :types => Set.new(@example_types), :attributes => Set.new([/^state/, "name"]), 
      :attribute_options => Set.new([:reader]) } | @default_specification
  end
end

describe "Aquarium::Aspects::Pointcut.make_attribute_method_names" do
  before do
    @expected_attribs = Set.new(%w[a a= b b= c c= d d=])
  end
  
  it "should generate attribute reader and writer method names when the attribute name is prefixed with @." do
    Aquarium::Aspects::Pointcut.make_attribute_method_names(%w[@a @b @c @d]).should == @expected_attribs 
  end

  it "should generate attribute reader and writer method names when the attribute name is not prefixed with @." do
    Aquarium::Aspects::Pointcut.make_attribute_method_names(%w[a b c d]).should == @expected_attribs
  end

  it "should generate attribute reader and writer method names when the attribute name is a symbol." do
    Aquarium::Aspects::Pointcut.make_attribute_method_names([:a, :b, :c, :d]).should == @expected_attribs 
  end
end
