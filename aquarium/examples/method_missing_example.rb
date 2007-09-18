#!/usr/bin/env ruby
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

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

module Aquarium
  class Echo
    def method_missing sym, *args
      p "Echoing: #{sym.to_s}: #{args.join(" ")}"
    end
  end
end

p "Before advising Echo:"
echo1 = Aquarium::Echo.new
echo1.say "hello", "world!"
echo1.log "something", "interesting..."
echo1.shout "theater", "in", "a", "crowded", "firehouse!"

Aquarium::Aspects::Aspect.new :around, :type => Aquarium::Echo, :method => :method_missing do |join_point, sym, *args|
  if sym == :log 
    p "--- Sending to log: #{args.join(" ")}" 
  else
    join_point.proceed
  end
end

p "After advising Echo:"
echo2 = Aquarium::Echo.new
echo2.say "hello", "world!"
echo2.log "something", "interesting..."
echo2.shout "theater", "in", "a", "crowded", "firehouse!"

