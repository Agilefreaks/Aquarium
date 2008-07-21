require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'

include Aquarium::Utils::HashUtils
include Aquarium::Aspects

describe Pointcut, "#and" do
  it "should return a new Pointcut." do
    pc1 = Pointcut.new
    pc2 = Pointcut.new :types => ClassWithPublicInstanceMethod, :method_options => :exclude_ancestor_methods
    pc12 = (pc1.and(pc2))
    pc12.should_not equal(pc1)
    pc12.should_not equal(pc2)
  end
end  
  
describe Pointcut, "#and (when one pointcut is empty)" do
  before :all do
    @pc1 = Pointcut.new
    @pc2 = Pointcut.new :types => ClassWithPublicInstanceMethod, :method_options => :exclude_ancestor_methods
  end
  
  it "should return a new empty Pointcut if the left-hand Pointcut is empty, independent of the right-hand Pointcut." do
    (@pc1.and(@pc2)).should == @pc1
  end
   
  it "should return a new empty Pointcut if the right-hand Pointcut is empty, independent of the left-hand Pointcut." do
    (@pc2.and(@pc1)).should == @pc1
  end
end
   
describe Pointcut, "#and (when both pointcuts are not empty)" do
  before(:each) do
    @example_types = {}
    [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod, 
     ClassWithPublicClassMethod, ClassWithPrivateClassMethod].each {|c| @example_types[c] = []}
    @empty_set = Set.new
  end

  it "should return a new Pointcut whose join points are the intersection of the left- and right-hand side Pointcuts, each with multiple types." do
    pc1 = Pointcut.new :types => [ClassWithAttribs, ClassWithPublicInstanceMethod, ClassWithPrivateInstanceMethod], :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Pointcut.new :types => [ClassWithAttribs, ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod], :attributes => :attrRW_ClassWithAttribs, :attribute_options => [:exclude_ancestor_methods]
    pc = pc1.and pc2
    expected_jp = JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
  
  it "should return a new Pointcut whose join points are the intersection of the left- and right-hand side Pointcuts, each with multiple objects." do
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pri = ClassWithPrivateInstanceMethod.new
    pro = ClassWithProtectedInstanceMethod.new
    pc1 = Pointcut.new :objects => [cwa, pub, pri], :attributes => [/^attr/], :attribute_options => [:readers, :exclude_ancestor_methods]
    pc2 = Pointcut.new :objects => [cwa, pub, pro], :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
   
  it "should return a new Pointcut whose join points are the intersection of the left- and right-hand side Pointcuts, each with a single type." do
    pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Pointcut.new :types => "ClassWithAttribs", :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
  
  it "should return a new Pointcut whose join points are the intersection of the left- and right-hand side Pointcuts, each with a single object." do
    cwa = ClassWithAttribs.new
    pc1 = Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Pointcut.new :object => cwa, :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
end

describe Pointcut, "#and (algebraic properties for type-based pointcuts)" do
  before :all do
    @pc1 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    @pc2 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    @pc3 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/]
  end
  
  it "should be unitary for type-based Pointcuts." do 
    pc = @pc1.and @pc2
    pc.should == @pc1
    pc.should == @pc2
  end

  it "should be commutative for type-based Pointcuts." do 
    pc13 = @pc1.and @pc3
    pc31 = @pc3.and @pc1
    pc13.should == pc31
  end
  
  it "should be associativity for type-based Pointcuts." do 
    pc123a = (@pc1.and(@pc2)).and(@pc3)
    pc123b = @pc1.and(@pc2.and(@pc3))
    pc123a.should == pc123b
  end  
end

describe Pointcut, "#and (algebraic properties for object-based pointcuts)" do
  before :all do
    cwa = ClassWithAttribs.new
    @pc1 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    @pc2 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    @pc3 = Pointcut.new :objects => cwa, :attributes => [/^attr/]
  end
  
  it "should be unitary for object-based Pointcuts." do 
    pc = @pc1.and @pc2
    pc.should == @pc1
    pc.should == @pc2
  end
   
  it "should be commutative for object-based Pointcuts." do 
    pc13 = @pc1.and @pc3
    pc31 = @pc3.and @pc1
    pc13.should == pc31
  end
   
  it "should be associativity for object-based Pointcuts." do 
    pc123a = (@pc1.and(@pc2)).and(@pc3)
    pc123b = @pc1.and(@pc2.and(@pc3))
    pc123a.should == pc123b
  end
end

describe Pointcut, "#&" do

  it "should be a synonym for #and." do 
    pc1 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc3 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/]
    pc123a = (pc1 & pc2) & pc3
    pc123b = pc1 & (pc2 & pc3)
    pc123a.should == pc123b
    cwa = ClassWithAttribs.new
    pca = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pcb = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pcc = Pointcut.new :objects => cwa, :attributes => [/^attr/]
    pcabc1 = (pca & pcb) & pcc
    pcabc2 = pca & (pcb & pcc)
    pcabc1.should == pcabc2
  end
end