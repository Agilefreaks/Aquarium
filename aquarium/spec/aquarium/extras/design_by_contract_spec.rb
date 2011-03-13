require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/extras/design_by_contract'

describe Aquarium::Extras::DesignByContract, "precondition" do
  class PreCond
    include Aquarium::Extras::DesignByContract   
    def action *args
    end
    
    precondition :method => :action, :message => "Must pass more than one argument." do |jp, obj, *args|
      args.size > 0
    end
  end
  
  it "should add advice that raises if the precondition is not satisfied" do
    lambda {PreCond.new.action}.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
  
  it "should add advice that does not raise if the precondition is satisfied" do
    PreCond.new.action(:a1)
  end
end

describe Aquarium::Extras::DesignByContract, "postcondition" do
  class PostCond
    include Aquarium::Extras::DesignByContract    
    def action *args
    end
    
    postcondition :method => :action, :message => "Must pass more than one argument and first argument must be non-empty." do |jp, obj, *args|
      args.size > 0 && ! args[0].to_s.empty?
    end
  end
  
  it "should add advice that raises if the postcondition is not satisfied" do
    lambda {PostCond.new.action}.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
    lambda {PostCond.new.action("")}.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
  
  it "should add advice that does not raise if the postcondition is satisfied" do
    PostCond.new.action(:a1)
  end
end


describe Aquarium::Extras::DesignByContract, "invariant" do
  class InvarCond
    include Aquarium::Extras::DesignByContract    
    def initialize 
      @invar = 0
    end
    attr_reader :invar
    def good_action
      "good"
    end
    def bad_action
      @invar = 1
      "bad"
    end
    
    invariant :methods => /action$/, :message => "Must not change the @invar value." do |jp, obj, *args|
      obj.invar == 0
    end
  end
  
  it "should add advice that raises if the invariant is not satisfied" do
    lambda {InvarCond.new.bad_action}.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
  
  it "should add advice that does not raise if the invariant is satisfied" do
    InvarCond.new.good_action
  end
  
  it "should return the value returned by the checked method when the invariant is satisfied" do
    InvarCond.new.good_action.should == "good"
  end
end

describe Aquarium::Extras::DesignByContract, "global enable/disable option" do
  class ContractEnablement
    include Aquarium::Extras::DesignByContract   
    def action *args
    end
    
    precondition :method => :action, :message => "Must pass more than one argument." do |jp, obj, *args|
      args.size > 0
    end
  end
  
  it "should disable creation of the contract aspects when the contracts are disabled" do
    begin
      Aquarium::Extras::DesignByContract.disable_all
      lambda { ContractEnablement.new.action }.should_not raise_error(Aquarium::Extras::DesignByContract::ContractError)
    ensure
      Aquarium::Extras::DesignByContract.enable_all
    end
  end
  
  it "should enable creation of the contract aspects when the contracts are enabled" do
    Aquarium::Extras::DesignByContract.enable_all
    lambda { ContractEnablement.new.action }.should raise_error(Aquarium::Extras::DesignByContract::ContractError)
  end
end
