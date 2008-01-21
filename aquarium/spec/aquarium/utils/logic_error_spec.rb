require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/logic_error'

# This doesn't do much..., except make rcov happy, since this exception is essentially for catching bugs.
describe Aquarium::Utils::LogicError, ".new" do
  it "should return an exception object" do
    Aquarium::Utils::LogicError.new.kind_of?(Exception).should be_true 
  end
end
