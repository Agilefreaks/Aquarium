require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/aspects/default_objects_handler'

module Aquarium
  class DefaultObjectsClass
    include Aquarium::Aspects::DefaultObjectsHandler
    
    attr_reader :specification
    
    def initialize hash = {}
      @specification = hash
    end
  end
end

describe Aquarium::Aspects::DefaultObjectsHandler, "#default_objects_given" do
  it "should return an empty array if the specification contains no :default_object or :default_objects key." do
    Aquarium::DefaultObjectsClass.new.default_objects_given.should == []
  end

  it "should return an array of objects that were specified with the :default_object key." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_object => defaults
    doc.default_objects_given.should == defaults
  end
  
  it "should return an array of objects that were specified with the :default_objects key." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_objects => defaults
    doc.default_objects_given.should == defaults
  end

  it "should return an array containing a single object if a single objects was specified with the :default_object key." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_object => default
    doc.default_objects_given.should == [default]
  end
  
  it "should return an array containing a single object if a single objects was specified with the :default_objects key." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_objects => default
    doc.default_objects_given.should == [default]
  end
end

describe Aquarium::Aspects::DefaultObjectsHandler, "#default_objects_given?" do
  it "should return false if the specification contains no :default_object or :default_objects key." do
    Aquarium::DefaultObjectsClass.new.default_objects_given?.should be_false
  end

  it "should return true if one or more objects were specified with the :default_object key." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_object => defaults
    doc.default_objects_given?.should be_true
  end
  
  it "should return true if one or more objects were specified with the :default_objects key." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_objects => defaults
    doc.default_objects_given?.should be_true
  end

  it "should return true if a single objects was specified with the :default_object key." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_object => default
    doc.default_objects_given?.should be_true
  end

  it "should return true if a single objects was specified with the :default_objects key." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_objects => default
    doc.default_objects_given?.should be_true
  end
end

describe Aquarium::Aspects::DefaultObjectsHandler, "#use_default_objects_if_defined" do
  it "should not change the specification if no :default_object or :default_objects were defined." do
    doc = Aquarium::DefaultObjectsClass.new
    doc.use_default_objects_if_defined
    doc.specification.should == {}
  end

  it "should set the :objects in the specification to an array of objects if :default_object was defined with an array of objects." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_object => defaults
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_object => defaults, :objects => defaults}
  end
  
  it "should set the :objects in the specification to an array of objects if :default_objects was defined with an array of objects." do
    defaults = ["1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_objects => defaults
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_objects => defaults, :objects => defaults}
  end
  
  it "should set the :objects in the specification to an array with one object if :default_object was defined with one object." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_object => default
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_object => default, :objects => [default]}
  end
  
  it "should set the :objects in the specification to an array with one object if :default_objects was defined with one object." do
    default = "1"
    doc = Aquarium::DefaultObjectsClass.new :default_objects => default
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_objects => default, :objects => [default]}
  end
  
  it "should set the :types in the specification to an array of types if :default_object was defined with an array of types." do
    defaults = [String, Aquarium::DefaultObjectsClass]
    doc = Aquarium::DefaultObjectsClass.new :default_object => defaults
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_object => defaults, :types => defaults}
  end
  
  it "should set the :types in the specification to an array of types if :default_objects was defined with an array of types." do
    defaults = [String, Aquarium::DefaultObjectsClass]
    doc = Aquarium::DefaultObjectsClass.new :default_objects => defaults
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_objects => defaults, :types => defaults}
  end
  
  it "should set the :types in the specification to an array with one type if :default_object was defined with one type." do
    default = String
    doc = Aquarium::DefaultObjectsClass.new :default_object => default
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_object => default, :types => [default]}
  end
  
  it "should set the :types in the specification to an array with one type if :default_objects was defined with one type." do
    default = String
    doc = Aquarium::DefaultObjectsClass.new :default_objects => default
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_objects => default, :types => [default]}
  end
  
  it "should set the :objects and :types in the specification to arrays of the corresponding objects and types if :default_objects was defined with objects and types." do
    defaults = [String, Aquarium::DefaultObjectsClass, "1", "2"]
    doc = Aquarium::DefaultObjectsClass.new :default_objects => defaults
    doc.use_default_objects_if_defined
    doc.specification.should == {:default_objects => defaults, :types => [String, Aquarium::DefaultObjectsClass], :objects => ["1", "2"]}
  end
  
end

