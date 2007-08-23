require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/hash_utils'

describe Aquarium::Utils::HashUtils, "#make_hash" do
  
  it "should return an empty hash if the input is nil." do
    make_hash(nil).should == {}
  end

  it "should return an empty hash if the input hash is empty." do
    make_hash({}).should == {}
  end

  it "should return a hash with all nil keys and their corresponding values removed." do
    make_hash({nil => 'nil', :a => 'a'}).should == {:a => 'a'}
  end

  it "should return an unmodified hash if the input hash has no nil keys." do
    make_hash({:a => 'a', :b => 'b'}).should == {:a => 'a', :b => 'b'}
  end

  it "should return a 1-element hash with an empty key and a nil value if the input is empty." do
    make_hash("").should == {"" => nil}
  end

  it "should return a 1-element hash with the input item as a key and nil as the corresponding value if a single input value is given and no block is given." do
    make_hash("123").should == {"123" => nil}
  end

  it "should return a 1-element hash with the input item as a key and the value of the block as the corresponding value if a single input value is given." do
    make_hash("123"){|x| x+x}.should == {"123" => "123123"}
  end

  it "should return a hash with the input list items as keys with any nils removed." do
    make_hash(["123", nil, nil, "22", nil]).should == {"123" => nil, "22" => nil}
  end

  it "should return a hash with the input list items as keys and nils as the corresponding values, if no block is given." do
    make_hash(["123", "22"]).should == {"123" => nil, "22" => nil}
  end

  it "should return a hash with the input list items as keys and the value of the block as the corresponding value." do
    make_hash(["123", "22"]){|x| x+x}.should == {"123" => "123123", "22" => "2222"}
  end

end

