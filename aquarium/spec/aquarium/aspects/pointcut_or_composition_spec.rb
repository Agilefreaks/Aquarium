require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'

include Aquarium::Utils::HashUtils
include Aquarium::Aspects

describe Pointcut, "#or" do
  
  before :all do
    @pc1 = Pointcut.new
    @pc2 = Pointcut.new :types => /Class.*Public.*Method/, :method_options => [:exclude_ancestor_methods]
    @pc3 = Pointcut.new :object => ClassWithProtectedInstanceMethod.new, :method_options => [:protected, :exclude_ancestor_methods]
  end
   
  it "should return a new Pointcut equal to the second, appended, non-empty Pointcut if self is empty (has no join points)." do
    @pc1.or(@pc2).should eql(@pc2)
    @pc1.or(@pc3).should eql(@pc3)
  end
   
  it "should return a new Pointcut equal to self if the second pointcut is empty." do
    @pc2.or(@pc1).should eql(@pc2)
    @pc3.or(@pc1).should eql(@pc3)
  end
end
   
describe Pointcut, "#or (with two non-empty pointcuts)" do
  
  it "should return a new Pointcut whose join points are the union of the left- and right-hand side Pointcuts for type-based Pointcuts." do
    pc4 = Pointcut.new :type => ClassWithPublicInstanceMethod, :method_options => :exclude_ancestor_methods
    pc5 = Pointcut.new :type => ClassWithAttribs, :methods => /^attr.*=$/, :method_options => :exclude_ancestor_methods
    jp_np1 = JoinPoint.new :type => ClassIncludingModuleWithPublicInstanceMethod, :method => :public_instance_class_including_module_test_method
    jp_np2 = JoinPoint.new :type => ModuleWithPublicInstanceMethod, :method => :public_instance_module_test_method
    pc4.join_points_not_matched << jp_np1
    pc5.join_points_not_matched << jp_np2
    pc = pc4.or pc5
    jp1 = JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs=
    jp2 = JoinPoint.new :type => ClassWithAttribs, :method => :attrW_ClassWithAttribs=
    jp3 = JoinPoint.new :type => ClassWithPublicInstanceMethod,  :method => :public_instance_test_method
    pc.join_points_matched.should == Set.new([jp1, jp2, jp3])
    pc.join_points_not_matched.should == Set.new([jp_np1, jp_np2])
  end
   
  it "should return a new Pointcut whose join points are the union of the left- and right-hand side Pointcuts for object-based Pointcuts." do
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new
    pc4 = Pointcut.new :objects => [cwa], :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    pc5 = Pointcut.new :object  => pub, :method_options => :exclude_ancestor_methods
    pc = pc4.or pc5
    jp1 = JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs=
    jp2 = JoinPoint.new :object => cwa, :method => :attrW_ClassWithAttribs=
    jp3 = JoinPoint.new :object => pub, :method => :public_instance_test_method
    pc.join_points_matched.sort.should == [jp1, jp2, jp3].sort
    pc.join_points_not_matched.sort.should == []
  end
end
 
describe Pointcut, "#or (algebraic properties for type-based pointcuts)" do
  before :all do
    @pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    @pc2 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    @pc3 = Pointcut.new :types => /Class.*Public.*Method/, :method_options => [:public, :exclude_ancestor_methods]
  end
  
  it "should be unitary for type-based Pointcuts." do 
    pc = @pc1.or @pc2
    pc.should eql(@pc1)
    pc.should eql(@pc2)
  end
   
  it "should be commutative for type-based Pointcuts." do 
    pc13 = @pc1.or @pc3
    pc31 = @pc3.or @pc1
    pc13.should eql(pc31)
  end
   
  it "should be associativity for type-based Pointcuts." do 
    pc123a = (@pc1.or(@pc2)).or(@pc3)
    pc123b = @pc1.or(@pc2.or(@pc3))
    pc123a.should eql(pc123b)
  end
end
   
describe Pointcut, "#or (algebraic properties for object-based pointcuts)" do
  before :all do
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    @pc1 = Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    @pc2 = Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    @pc3 = Pointcut.new :objects => pub, :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
  end
  
  it "should be unitary for object-based Pointcuts." do 
    pc12 = @pc1.or @pc2
    pc12.should eql(@pc1)
    pc12.should eql(@pc2)
  end
   
  it "should be commutative for object-based Pointcuts." do 
    pc13 = @pc1.or @pc3
    pc31 = @pc3.or @pc1
    pc13.should eql(pc31)
  end
   
  it "should be associativity for object-based Pointcuts." do 
    pc123a = (@pc1.or(@pc2)).or(@pc3)
    pc123b = @pc1.or(@pc2.or(@pc3))
    pc123a.should eql(pc123b)
  end
end


describe Pointcut, "#|" do
  it "should be a synonym for #or." do
    pc1 = Pointcut.new
    pc2 = Pointcut.new :types => /Class.*Public.*Method/, :method_options => [:public, :exclude_ancestor_methods]
    pc3 = Pointcut.new :object => ClassWithPublicInstanceMethod.new, :method_options => [:exclude_ancestor_methods]
    pc12 = pc1 | pc2
    pc32 = pc3 | pc2
    pc23 = pc2 | pc3
    pc12.should_not equal(pc1)
    pc12.should_not equal(pc2)
    pc12.should eql(pc2)
    pc32.should eql(pc23)
    pca = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    pcb = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:readers, :exclude_ancestor_methods]
    pcc = Pointcut.new :types => /Class.*Method/, :method_options => [:exclude_ancestor_methods]
    pcabc1 = (pca | pcb) | pcc
    pcabc2 = pca | (pcb | pcc)
    pcabc1.should eql(pcabc2)
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pcd = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    pce = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:readers, :exclude_ancestor_methods]
    pcf = Pointcut.new :objects => pub, :method_options => [:exclude_ancestor_methods]
    pcdef1 = (pcd | pce) | pcf
    pcdef2 = pcd | (pce | pcf)
    pcdef1.should eql(pcdef2)
  end
end