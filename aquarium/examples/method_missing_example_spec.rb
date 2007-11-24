require File.dirname(__FILE__) + '/../spec/aquarium/spec_helper.rb'
require 'aquarium'

# Example demonstrating "around" advice for method_missing. This is a technique for
# avoiding collisions when different toolkits want to override method_missing in the
# same classes, e.g., Object. Using around advice as shown allows a toolkit to add 
# custom behavior while invoking the "native" method_missing to handle unrecognized
# method calls.
# Note that it is essential to use around advice, not before or after advice, because
# neither can prevent the call to the "wrapped" method_missing, which is presumably
# not what you want.
# In this (contrived) example, an Echo class uses method_missing to simply echo
# the method name and arguments. An aspect is used to intercept any calls to a 
# fictitious "log" method and handle those in a different way.

module Aquarium
  class Echo
    def method_missing sym, *args
      @log ||= []
      @log << "Echoing: #{sym.to_s}: #{args.join(" ")}"
    end
    def logged_messages; @log; end
    def respond_to? sym, include_private = false
      true
    end
  end
end

describe "An example of a class' method_missing without around advice" do
  it "should handle all invocations of method_missing." do
    echo = Aquarium::Echo.new
    echo.say "hello", "world!"
    echo.log "something", "interesting..."
    echo.shout "theater", "in", "a", "crowded", "firehouse!"
    echo.logged_messages.size.should == 3
    echo.logged_messages[0].should == "Echoing: say: hello world!"
    echo.logged_messages[1].should == "Echoing: log: something interesting..."
    echo.logged_messages[2].should == "Echoing: shout: theater in a crowded firehouse!"
  end
end

describe "An example of a class' method_missing with around advice" do
  it "should only handle invocations not processed by the around advice." do
    @intercepted_message = nil
    aspect = Aquarium::Aspects::Aspect.new :around, :type => Aquarium::Echo, :method => :method_missing do |join_point, obj, sym, *args|
      if sym == :log 
        @intercepted_message = "log: #{args.join(" ")}" 
      else
        join_point.proceed
      end
    end
    echo = Aquarium::Echo.new
    echo.say "hello", "world!"
    echo.log "something", "interesting..."
    echo.shout "theater", "in", "a", "crowded", "firehouse!"
    echo.logged_messages.size.should == 2
    echo.logged_messages[0].should == "Echoing: say: hello world!"
    echo.logged_messages[1].should == "Echoing: shout: theater in a crowded firehouse!"
    @intercepted_message.should == "log: something interesting..."
    aspect.unadvise
  end
end
