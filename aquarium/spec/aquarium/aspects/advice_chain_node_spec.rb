require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium'

include Aquarium::Aspects::Advice

# Some of AdviceChainNode and related classes are tested through advice_spec.rb. We rely on rcov to
# tell us otherwise...
describe Aquarium::Aspects::AdviceChainNode, "#each" do
  it "should return each node in succession" do
    static_join_point = :static_join_point
    advice = lambda {|jp, obj, *args| p ":none advice"}
    options = {
      :advice_kind => :none, 
      :advice => advice,
      :next_node => nil,
      :static_join_point => static_join_point}    
    advice_chain = Aquarium::Aspects::AdviceChainNodeFactory.make_node options

    KINDS_IN_PRIORITY_ORDER.each do |advice_kind|
      advice = lambda {|jp, obj, *args| p "#{advice_kind} advice"}
      options[:advice_kind] = advice_kind
      options[:advice]      = advice,
      options[:next_node]   = advice_chain
      advice_chain = Aquarium::Aspects::AdviceChainNodeFactory.make_node options
    end
    
    advice_chain.size.should == 6
    expected_advice_kinds = KINDS_IN_PRIORITY_ORDER.reverse + [:none]
    count = 0
    advice_chain.each do |node|
      node.advice_kind.should == expected_advice_kinds[count]
      count += 1
    end
  end
end
