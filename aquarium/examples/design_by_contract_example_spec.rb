require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper.rb'
require 'aquarium'
require 'aquarium/extras/design_by_contract'

# Example demonstrating "Design by Contract", Bertrand Meyer's idea for programmatically-
# specifying the contract of use for a class or module and testing it at runtime (usually
# during the testing process)
# This example is adapted from spec/extras/design_by_contract_spec.rb.
# Note: the DesignByContract module adds the #precondition, #postcondition, and #invariant
# methods shown below to Object and they use "self" as the :object to advise.  

module Aquarium
  class PreCondExample
    def action *args
      @state = *args
    end
    attr_reader :state

    precondition :method => :action, :message => "Must pass more than one argument." do |jp, obj, *args|
      args.size > 0
    end
  end
end
  
describe "An example using a precondition" do
  it "should fail at the call entry point if the precondition is not satisfied." do
    lambda { Aquarium::PreCondExample.new.action }.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
end

describe "An example using a precondition" do
  it "should not fail at the call entry point if the precondition is satisfied." do
    Aquarium::PreCondExample.new.action :a1
  end
end

module Aquarium
  class PostCondExample
    def action *args
      @state = *args
    end
    attr_reader :state

    postcondition :method => :action, 
      :message => "Must pass more than one argument and first argument must be non-empty." do |jp, obj, *args|
      args.size > 0 && ! args[0].empty?
    end
  end
end

describe "An example using a postcondition" do
  it "should fail at the call exit point if the postcondition is not satisfied." do
    lambda { Aquarium::PostCondExample.new.action }.should    raise_error(Aquarium::Extras::DesignByContract::ContractError)
    lambda { Aquarium::PostCondExample.new.action "" }.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
end

describe "An example using a postcondition" do
  it "should not fail at the call entry point if the postcondition is satisfied." do
    Aquarium::PostCondExample.new.action :a1
  end
end

module Aquarium
  class InvarCondExample
    def initialize 
      @invar = 0
    end
    attr_reader :invar
    def good_action
    end
    def bad_action
      @invar = 1
    end

    invariant :methods => /action$/, :message => "Must not change the @invar value." do |jp, obj, *args|
      obj.invar == 0
    end
  end
end

describe "An example using an invariant" do
  it "should fail at the call entry or exit point if the invariant is not satisfied." do
    lambda { Aquarium::InvarCondExample.new.bad_action }.should    raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
end

describe "An example using an invariant" do
  it "should pass at the call entry and exit point if the invariant is satisfied." do
    Aquarium::InvarCondExample.new.good_action
  end
end
