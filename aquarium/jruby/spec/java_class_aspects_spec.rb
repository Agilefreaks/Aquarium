require File.dirname(__FILE__) + '/spec_helper'

include Aquarium::Aspects

# The Aquarium README summarizes the known bugs and limitations of the JRuby integration.

class StringLengthListComparator 
  include java.util.Comparator
  def compare s1, s2
    s1.length <=> s2.length
  end
end

class StringListCaseConverterAndSorterWithConvertCaseOverride < Java::example.sorter.converter.StringListCaseConverterAndSorter
  def convertCase *args; super *args; end
end

java_example_types = [
  Java::example.Worker, 
  Java::example.sorter.StringListSorter, 
  Java::example.sorter.converter.StringListCaseConverterAndSorter,
  StringListCaseConverterAndSorterWithConvertCaseOverride]

def do_sort list_sorter, method_name = :do_work
  orig_list = %w[now is the time for all good men to come to the aid of their country]
  sorted_list = list_sorter.send(method_name,orig_list)
  sorted_list.should_not eql(orig_list)
  sorted_list.size.should == orig_list.size
  expected = %w[is to to of now the for all men the aid time good come their country]
  sorted_list.to_a.should eql(expected)
end

def is_java_interface? type
  type.java_class.interface?
end

def log_should_contain_entries
  @aspect_log.should_not be_empty
  @aspect_log.should include("entering do_work")
  @aspect_log.should include("leaving do_work")
end

def make_advice
  return Proc.new { |jp, object, *args|
    @aspect_log += "entering do_work(#{args.inspect})\n"
    result = jp.proceed
    @aspect_log += "leaving do_work(#{args.inspect})\n"
    result
  }
end
  
describe "Java type without advice" do  
  it "should not be advised" do
    do_sort Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
  end
end

describe "Java instance with advice" do
  before :each do
    @aspect_log = ""
  end

  it "should invoke the advice when the advised methods on the same instance are called" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    aspect = Aspect.new :around, :calls_to => :do_work, :object => list_sorter, :advice => make_advice
    do_sort list_sorter
    log_should_contain_entries

    list_sorter2 = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    aspect = Aspect.new :around, :calls_to => :do_work, :object => list_sorter2, :advice => make_advice
    @aspect_log = ""
    do_sort list_sorter2
    log_should_contain_entries
    aspect.unadvise
  end
end

describe "Second Java instance of the same type" do
  it "should not be advised by the advice applied to a different instance" do
    aspect = Aspect.new :around, :calls_to => :do_work, :object => Java::example.sorter.StringListSorter.new(StringLengthListComparator.new), :advice => make_advice
    list_sorter2 = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @aspect_log = ""
    do_sort list_sorter2
    @aspect_log.should be_empty
    aspect.unadvise
  end
end

describe "Second Java instance of a derived type" do
  it "should not be advised by the advice applied to an instance of a parent type" do
    aspect = Aspect.new :around, :calls_to => :do_work, :object => Java::example.sorter.StringListSorter.new(StringLengthListComparator.new), :advice => make_advice
    list_sorter2 = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    @aspect_log = ""
    do_sort list_sorter2
    @aspect_log.should be_empty
    aspect.unadvise
  end
end

describe "Java instance with advice added then removed" do
  it "should not be advised after the advice is removed" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    aspect = Aspect.new :around, :calls_to => :do_work, :object => list_sorter, :advice => make_advice
    @aspect_log = ""
    do_sort list_sorter
    @aspect_log = ""
    aspect.unadvise
    do_sort list_sorter
    @aspect_log.should be_empty

    list_sorter2 = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    aspect2 = Aspect.new :around, :calls_to => :do_work, :object => list_sorter2, :advice => make_advice
    do_sort list_sorter2
    @aspect_log = ""
    aspect2.unadvise
    do_sort list_sorter2
    @aspect_log.should be_empty
  end
end

describe "Java interface used with :type => ... (or synonym)" do
  it "should never match join points; you must use :type(s)_and_descendents, instead" do     
    aspect = Aspect.new :around, :calls_to => [:do_work, :doWork], :type => Java::example.Worker, :ignore_no_matching_join_points => true do; end
    aspect.join_points_matched.should be_empty
  end
end

describe "Java interface used with :type_and_descendents => ... (or synonym)" do
  before :each do
    @aspect = Aspect.new :around, :calls_to => :do_work, :type_and_descendents => Java::example.Worker, 
      # :advice => make_advice
      :exclude_type => StringListCaseConverterAndSorterWithConvertCaseOverride, :advice => make_advice
    @aspect_log = ""
  end
  after :each do
    @aspect.unadvise
  end
  
  it "should invoke the advice when the advised methods of directly-implementing subclasses are called" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
  end

  it "should invoke the advice when the advised methods of indirectly-implementing subclasses are called" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
  end

  it "should not invoke the advice after the advice is removed" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
    @aspect_log = ""
    do_sort list_sorter
    do_sort Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    @aspect_log.should be_empty
  end

  it "should allow #unadvise to be called repeatedly" do
    lambda {@aspect.unadvise}.should_not raise_error
    lambda {@aspect.unadvise}.should_not raise_error
  end
end

describe "Java class used with :type_and_descendents => ..." do
  before :each do
    @aspect = Aspect.new :around, :calls_to => :do_work, :type_and_descendents => Java::example.sorter.StringListSorter, 
      :exclude_type => StringListCaseConverterAndSorterWithConvertCaseOverride, :advice => make_advice
    @aspect_log = ""
  end
  
  it "should invoke the advice when the advised methods of the class are called" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
  end

  it "should invoke the advice when the advised methods of extending subclasses are called" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
  end

  it "should not invoke the advice after the advice is removed" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
    @aspect_log = ""
    do_sort list_sorter
    do_sort Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    @aspect_log.should be_empty
  end
end

describe "Derived Java class used with :type_and_descendents => ..." do
  before :each do
    @aspect_log = ""
    @aspect = Aspect.new :around, :calls_to => :do_work, :type_and_descendents => Java::example.sorter.converter.StringListCaseConverterAndSorter, 
      :exclude_type => StringListCaseConverterAndSorterWithConvertCaseOverride, :advice => make_advice
  end

  it "should not invoke the advice when the advised methods of parent classes are called" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    @aspect_log.should be_empty
    @aspect.unadvise
  end

  it "should invoke the advice when the advised methods of the same class are called" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
  end

  it "should not invoke the advice after the advice is removed" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
    @aspect_log = ""
    do_sort list_sorter
    @aspect_log.should be_empty
  end
end

describe "Derived Java class used with :type_and_ancestors => ..." do
  before :each do
    @aspect_log = ""
    @aspect = Aspect.new :around, :calls_to => :do_work, :type_and_ancestors => Java::example.sorter.converter.StringListCaseConverterAndSorter, :advice => make_advice
  end

  it "should invoke the advice when the advised methods of parent classes are called" do
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
  end

  it "should invoke the advice when the advised methods of the same class are called" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
  end

  it "should not invoke the advice after the advice is removed" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    @aspect.unadvise
    @aspect_log = ""
    do_sort list_sorter
    @aspect_log.should be_empty
  end
end

describe "Java camel-case method name 'doFooBar'" do
  before :each do
    @aspect_log = ""
  end

  it "should be matched when using the camel-case form of the name 'doFooBar'" do
    aspect = Aspect.new :around, :calls_to => :doWork, :type_and_descendents => Java::example.sorter.StringListSorter, 
      :restricting_methods_to => [:exclude_ancestor_methods], :advice => make_advice
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter, :doWork
    log_should_contain_entries
    aspect.unadvise
  end

  it "should be matched when using the underscore form of the name 'do_foo_bar'" do
    aspect = Aspect.new :around, :calls_to => :do_work, :type_and_descendents => Java::example.sorter.StringListSorter, 
      :restricting_methods_to => [:exclude_ancestor_methods], :advice => make_advice
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter
    log_should_contain_entries
    aspect.unadvise
  end
  
  it "should advise 'doFooBar' separately from 'do_foo_bar', so that invoking 'do_foo_bar' will not invoke the advice!" do
    aspect = Aspect.new :around, :calls_to => :doWork, :type_and_descendents => Java::example.sorter.StringListSorter, 
      :restricting_methods_to => [:exclude_ancestor_methods], :advice => make_advice
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter, :do_work
    @aspect_log.should be_empty
    aspect.unadvise
  end
  it "should advise 'do_foo_bar' separately from 'doFooBar', so that invoking 'doFooBar' will not invoke the advice!" do
    aspect = Aspect.new :around, :calls_to => :do_work, :type_and_descendents => Java::example.sorter.StringListSorter,
      :restricting_methods_to => [:exclude_ancestor_methods], :advice => make_advice
    list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter, :doWork
    @aspect_log.should be_empty
    aspect.unadvise
  end
end

describe "Java method advice" do
  it "will not be invoked when the method is called by other Java methods" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :convertCase, :in_type => Java::example.sorter.converter.StringListCaseConverterAndSorter do
      @advise_called = true
    end
    do_sort list_sorter
    @advise_called.should be_false
    aspect.unadvise
  end

  it "should be invoked when the method is called by other Java methods, using a ruby subclass that overrides the advised method" do
    list_sorter = StringListCaseConverterAndSorterWithConvertCaseOverride.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :convertCase, :in_type => Java::example.sorter.converter.StringListCaseConverterAndSorter do
      @advise_called = true
    end
    do_sort list_sorter
    @advise_called.should be_true
    aspect.unadvise
  end

  it "should be invoked when the method is called by a Ruby method" do
    list_sorter = Java::example.sorter.converter.StringListCaseConverterAndSorter.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :convertCase, :in_type => Java::example.sorter.converter.StringListCaseConverterAndSorter do
      @advise_called = true
    end
    list_sorter.convertCase(java.util.ArrayList.new)
    @advise_called.should be_true
    aspect.unadvise
  end
end

describe "Ruby subclass with advice on method in a Java parent class" do
  it "should be invoked, but isn't, when the method is advised using the Java form of its name (doFoo), rather than the Ruby form (do_foo) -- BUG #18326" do
    list_sorter = StringListCaseConverterAndSorterWithConvertCaseOverride.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :doWork, :in_type => StringListCaseConverterAndSorterWithConvertCaseOverride do
      @advise_called = true
    end
    do_sort list_sorter
    @advise_called.should be_false
    # @advise_called.should be_true
    aspect.unadvise
  end

  it "should be invoked when the method is called by a Ruby method" do
    list_sorter = StringListCaseConverterAndSorterWithConvertCaseOverride.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :do_work, :in_type => StringListCaseConverterAndSorterWithConvertCaseOverride do
      @advise_called = true
    end
    do_sort list_sorter
    @advise_called.should be_true
    aspect.unadvise
  end

  it "should be removed cleanly when aspect#unadvise is called" do
    list_sorter = StringListCaseConverterAndSorterWithConvertCaseOverride.new(StringLengthListComparator.new)
    @advise_called = false
    aspect = Aspect.new :before, :calls_to => :do_work, :in_type => StringListCaseConverterAndSorterWithConvertCaseOverride do
      @advise_called = true
    end
    do_sort list_sorter
    @advise_called.should be_true
    aspect.unadvise
    @advise_called = false
    do_sort list_sorter
    @advise_called.should be_false
  end
end

describe "JDK classes" do
  it "should be advisable by Aquarium aspects" do
    @aspect_log = ""
    aspect = Aspect.new :before, :calls_to => :add, :on_type => java.util.ArrayList do |jp, obj, *args|
      @aspect_log << "adding: #{args[0]}\n"
    end
    list = java.util.ArrayList.new
    list.add(1)
    list.add(2)
    @aspect_log.should include("adding: 1")
    @aspect_log.should include("adding: 2")
    aspect.unadvise
    @aspect_log = ""
    list.add(1)
    list.add(2)
    @aspect_log.should be_empty
  end
end  


include Aquarium::Utils

describe TypeUtils, ".descendents" do
  it "should return Java classes implementing a Java interface" do
    actual = TypeUtils.descendents Java::example.Worker
    actual.size.should == java_example_types.size
    java_example_types.each {|x| actual.should include(x)}
  end

  it "should return Java classes extending a Java class" do
    expected = [
      Java::example.sorter.StringListSorter, 
      Java::example.sorter.converter.StringListCaseConverterAndSorter,
      StringListCaseConverterAndSorterWithConvertCaseOverride]
    actual = TypeUtils.descendents Java::example.sorter.StringListSorter
    actual.size.should == expected.size
    expected.each {|x| actual.should include(x)}
  end
end

describe "Java::Packages::Type.ancestors" do
  it "should return Java classes and interfaces that are ancestors of a Java class" do
    anc = Java::example.sorter.converter.StringListCaseConverterAndSorter.ancestors
    [Java::example.Worker, Java::example.sorter.StringListSorter, Java::example.sorter.converter.StringListCaseConverterAndSorter].each do |t|
      anc.should include(t) 
    end
  end
end
