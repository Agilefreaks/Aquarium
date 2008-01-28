require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require 'aquarium/extensions/set'

class Foo
  def initialize name
    @name = name
  end
  attr_reader :name
  def eql? other
    name.eql? other.name
  end
  alias :== :eql?
end
class Bar
end

describe "set comparison", :shared => true do
  it "should return true for the same set" do
    s = Set.new [Foo.new("f1"), Foo.new("f2")]
    s.should eql(s)
  end

  it "should return true for equivalent sets" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f2"), Foo.new("f1")]
    s1.should eql(s2)
  end

  it "should return false for sets where one is a subset of, but not equivalent to, the other set" do
    s1 = Set.new [Foo.new("f1")]
    s2 = Set.new [Foo.new("f2"), Foo.new("f1")]
    s1.should_not eql(s2)
  end

  it "should return false for sets where some element pairs are of different types" do
    s1 = Set.new [Foo.new("f1"), Bar.new]
    s2 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s1.should_not eql(s2)
  end
end

describe Set, "#==" do
  it_should_behave_like "set comparison"
end

describe Set, "#eql?" do
  it_should_behave_like "set comparison"
end

describe Set, "#union_using_eql_comparison" do
  it "should return an equivalent set if unioned with itself" do
    s = Set.new [Foo.new("f1"), Foo.new("f2")]
    s.union_using_eql_comparison(s).should eql(s)
  end

  it "should return an equivalent set if unioned with another equivalent set" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s1.union_using_eql_comparison(s2).should eql(s1)
  end

  it "should return an equivalent set if unioned with subset" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f1")]
    s1.union_using_eql_comparison(s2).should eql(s1)
    s2.union_using_eql_comparison(s1).should eql(s1)
  end

  it "should return a combined set if unioned with a disjoint set" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f3")]
    s3 = Set.new [Foo.new("f1"), Foo.new("f2"), Foo.new("f3")]
    s1.union_using_eql_comparison(s2).should eql(s3)
    s2.union_using_eql_comparison(s1).should eql(s3)
  end
end

describe Set, "#intersection_using_eql_comparison" do
  it "should return an equivalent set if intersectioned with itself" do
    s = Set.new [Foo.new("f1"), Foo.new("f2")]
    s.intersection_using_eql_comparison(s).should eql(s)
  end

  it "should return an equivalent set if intersectioned with another equivalent set" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s1.intersection_using_eql_comparison(s2).should eql(s1)
  end

  it "should return a subset if intersectioned with an equivalent subset" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f1")]
    s1.intersection_using_eql_comparison(s2).should eql(s2)
    s2.intersection_using_eql_comparison(s1).should eql(s2)
  end

  it "should return an empty set if intersectioned with a disjoint set" do
    s1 = Set.new [Foo.new("f1"), Foo.new("f2")]
    s2 = Set.new [Foo.new("f3")]
    s1.intersection_using_eql_comparison(s2).should eql(Set.new)
    s2.intersection_using_eql_comparison(s1).should eql(Set.new)
  end
end

