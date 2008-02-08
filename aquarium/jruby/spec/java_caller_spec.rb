$:.unshift '/Users/deanwampler/projects/ruby/aquarium/aquarium-svn/trunk/aquarium/lib'
require 'rubygems'
require 'spec'
require 'aquarium'
require 'example.jar'
include Java

include Aquarium::Aspects

class StringLengthListComparator 
  include java.util.Comparator
  def compare s1, s2
    s1.length <=> s2.length
  end
end

def do_sort list_sorter = @list_sorter
  sorted_list = list_sorter.do_work(@orig_list)
  sorted_list.should_not eql(@orig_list)
  sorted_list.size.should == @orig_list.size
  expected = %w[is to to of now the for all men the aid time good come their country]
  sorted_list.to_a.should eql(expected)
end

def make_aspect use_class = true
  key   = use_class ? :on_type : :on_object
  value = use_class ? Java::example.sorter.StringListSorter : @list_sorter
  aspect = Aspect.new :around, :calls_to => :do_work, key => value do |jp, object, *args|
    @aspect_log += "entering do_work(#{args.inspect})\n"
    result = jp.proceed
    @aspect_log += "leaving do_work(#{args.inspect})\n"
    result
  end
end

describe "StringListSorter without advice" do
  before :each do
    @list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @orig_list = %w[now is the time for all good men to come to the aid of their country]
  end
  
  it "should sort without logging" do
    do_sort
  end
end

describe "StringListSorter instance with advice" do
  before :each do
    @list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @orig_list = %w[now is the time for all good men to come to the aid of their country]
    @aspect_log = ""
  end
  
  it "should invoke the advice when do_work is called" do
    aspect = make_aspect false
    do_sort
    @aspect_log.should_not be_empty
    @aspect_log.should include("entering do_work")
    @aspect_log.should include("leaving do_work")
    aspect.unadvise
    @aspect_log = ""
  end
end

describe "Second StringListSorter instance" do
  before :each do
    @list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @orig_list = %w[now is the time for all good men to come to the aid of their country]
    @aspect_log = ""
  end
  
  it "should not be advised by the advice applied to a different instance" do
    aspect = make_aspect false
    list_sorter2 = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    do_sort list_sorter2
    @aspect_log.should be_empty
    aspect.unadvise
  end
end

describe "StringListSorter instance with advice added then removed" do
  before :each do
    @list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @orig_list = %w[now is the time for all good men to come to the aid of their country]
    @aspect_log = ""
  end
  
  it "should log when do_work is called" do
    aspect = make_aspect false
    do_sort
    @aspect_log = ""
    aspect.unadvise
    do_sort
    @aspect_log.should be_empty
  end
end

describe "StringListSorter class with advice" do
  before :each do
    @list_sorter = Java::example.sorter.StringListSorter.new(StringLengthListComparator.new)
    @orig_list = %w[now is the time for all good men to come to the aid of their country]
    @aspect_log = ""
  end
  
  it "should invoke the advice when do_work is called" do
    aspect = make_aspect true
    do_sort
    @aspect_log.should_not be_empty
    @aspect_log.should include("entering do_work")
    @aspect_log.should include("leaving do_work")
    aspect.unadvise
    @aspect_log = ""
  end
end
