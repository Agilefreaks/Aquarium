require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'

describe "Intersection of Pointcuts", :shared => true do
  include Aquarium::Utils::HashUtils
  # include Aquarium::Utils::HtmlEscaper
  
  before(:each) do
    @example_types = {}
    [ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod, ClassWithPrivateInstanceMethod, 
     ClassWithPublicClassMethod, ClassWithPrivateClassMethod].each {|c| @example_types[c] = []}
    @empty_set = Set.new
  end

  it "should return an empty Aquarium::Aspects::Pointcut if the left-hand Aquarium::Aspects::Pointcut is empty, independent of the right-hand Aquarium::Aspects::Pointcut." do
    pc1 = Aquarium::Aspects::Pointcut.new
    pc2 = Aquarium::Aspects::Pointcut.new :types => /Class.*Method/
    (pc1.and(pc2)).should == pc1
    pc3 = Aquarium::Aspects::Pointcut.new :object => ClassWithPublicInstanceMethod.new
    (pc1.and(pc3)).should == pc1
  end
   
  it "should return an empty Aquarium::Aspects::Pointcut if the second pointcut has no join points." do
    pc1 = Aquarium::Aspects::Pointcut.new :types => /Class.*Method/
    pc2 = Aquarium::Aspects::Pointcut.new
    (pc1.and(pc2)).should == pc2
    pc3 = Aquarium::Aspects::Pointcut.new :object => ClassWithPublicInstanceMethod.new
    (pc3.and(pc2)).should == pc2
  end
   
  it "should return a new Aquarium::Aspects::Pointcut whose join points are the intersection of the left- and right-hand side Aquarium::Aspects::Pointcuts, each with multiple types." do
    pc1 = Aquarium::Aspects::Pointcut.new :types => [ClassWithAttribs, ClassWithPublicInstanceMethod, ClassWithPrivateInstanceMethod], :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => [ClassWithAttribs, ClassWithPublicInstanceMethod, ClassWithProtectedInstanceMethod], :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
  
  it "should return a new Aquarium::Aspects::Pointcut whose join points are the intersection of the left- and right-hand side Aquarium::Aspects::Pointcuts, each with multiple objects." do
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pri = ClassWithPrivateInstanceMethod.new
    pro = ClassWithProtectedInstanceMethod.new
    pc1 = Aquarium::Aspects::Pointcut.new :objects => [cwa, pub, pri], :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Aquarium::Aspects::Pointcut.new :objects => [cwa, pub, pro], :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = Aquarium::Aspects::JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
   
  it "should return a new Aquarium::Aspects::Pointcut whose join points are the intersection of the left- and right-hand side Aquarium::Aspects::Pointcuts, each with a single type." do
    pc1 = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => "ClassWithAttribs", :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
  
  it "should return a new Aquarium::Aspects::Pointcut whose join points are the intersection of the left- and right-hand side Aquarium::Aspects::Pointcuts, each with a single object." do
    cwa = ClassWithAttribs.new
    pc1 = Aquarium::Aspects::Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc2 = Aquarium::Aspects::Pointcut.new :object => cwa, :attributes => :attrRW_ClassWithAttribs
    pc = pc1.and pc2
    expected_jp = Aquarium::Aspects::JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs
    pc.join_points_matched.should == Set.new([expected_jp])
    pc.join_points_not_matched.should == @empty_set
  end
   
  it "should be unitary for type-based Aquarium::Aspects::Pointcuts." do 
    pc1 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc = pc1.and pc2
    pc.should == pc1
    pc.should == pc2
  end
  
  it "should be unitary for object-based Aquarium::Aspects::Pointcuts." do 
    cwa = ClassWithAttribs.new
    pc1 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc = pc1.and pc2
    pc.should == pc1
    pc.should == pc2
  end
   
  it "should be commutative for type-based Aquarium::Aspects::Pointcuts." do 
    pc1 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => /Class.*Method/
    pc12 = pc1.and pc2
    pc21 = pc2.and pc1
    pc12.should == pc21
  end
  
  it "should be commutative for object-based Aquarium::Aspects::Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :objects => pub, :attributes => [/^attr/], :attribute_options => [:writers]
    pc12 = pc1.and pc2
    pc21 = pc2.and pc1
    pc12.should == pc21
  end
   
  it "should be associativity for type-based Aquarium::Aspects::Pointcuts." do 
    pc1 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Aquarium::Aspects::Pointcut.new :types => /Class.*Method/
    pc123a = (pc1.and(pc2)).and(pc3)
    pc123b = pc1.and(pc2.and(pc3))
    pc123a.should == pc123b
  end
  
  it "should be associativity for object-based Aquarium::Aspects::Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Aquarium::Aspects::Pointcut.new :objects => pub
    pc123a = (pc1.and(pc2)).and(pc3)
    pc123b = pc1.and(pc2.and(pc3))
    pc123a.should == pc123b
  end
end

describe Aquarium::Aspects::Pointcut, "#and" do
  it_should_behave_like "Intersection of Pointcuts"
end

describe Aquarium::Aspects::Pointcut, "#&" do
  include Aquarium::Utils::HashUtils

  it_should_behave_like "Intersection of Pointcuts"

  it "should be associativity for type-based Aquarium::Aspects::Pointcuts." do 
    pc1 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Aquarium::Aspects::Pointcut.new :types => /Class.*Method/
    pc123a = (pc1 & pc2) & pc3
    pc123b = pc1 & (pc2 & pc3)
    pc123a.should == pc123b
  end

  it "should be associativity for object-based Aquarium::Aspects::Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Aquarium::Aspects::Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Aquarium::Aspects::Pointcut.new :objects => pub
    pc123a = (pc1 & pc2) & pc3
    pc123b = pc1 & (pc2 & pc3)
    pc123a.should == pc123b
  end
end