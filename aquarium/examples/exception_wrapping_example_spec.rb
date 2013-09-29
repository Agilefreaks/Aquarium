require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper'
require 'aquarium'

# Example demonstrating "wrapping" an exception; rescuing an exception and 
# throwing a different one. A common use for this is to map exceptions across
# "domain" boundaries, e.g., persistence and application logic domains. 
# Note that you must use :around advice, since :after_raising cannot change
# the control flow.
# (However, see feature request #19119)

module Aquarium
  class Exception1 < Exception; end
  class Exception2 < Exception; end
  class NewException < Exception; end

  class Raiser
    def raise_exception1
      raise Exception1.new("one")
    end
    def raise_exception2
      raise Exception2.new("two")
    end
  end
end

describe "Rescuing one exception type and raising a second type" do
  before :all do
    @aspect = Aquarium::Aspects::Aspect.new :around, 
      :calls_to => /^raise_exception/, :in_type => Aquarium::Raiser do |jp, obj, *args|
      begin
        jp.proceed
      rescue Aquarium::Exception1 => e
        raise Aquarium::NewException.new("New Exception: old exception message was: #{e.message}")
      end
    end
    @raiser = Aquarium::Raiser.new
  end
  
  after :all do
    @aspect.unadvise
  end
  
  it "should intercept the specified type of exception" do
    expect { @raiser.raise_exception1 }.to raise_error(Aquarium::NewException)
  end
  it "should not intercept other types of exceptions" do
    expect { @raiser.raise_exception2 }.to raise_error(Aquarium::Exception2)
  end
end
