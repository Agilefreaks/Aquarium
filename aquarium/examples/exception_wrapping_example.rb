#!/usr/bin/env ruby
# Example demonstrating "wrapping" an exception; rescuing an exception and 
# throwing a different one. A common use for this is to map exceptions across
# "domain" boundaries, e.g., persistence and application logic domains. 
# Note that you must use :around advice, since :after_raising cannot change
# the control flow.
# (However, see feature request #19119)

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

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

Aquarium::Aspects::Aspect.new :around, 
    :calls_to => /^raise_exception/, 
    :in_type => Aquarium::Raiser do |jp, obj, *args|
  begin
    jp.proceed
  rescue Aquarium::Exception1 => e
    raise Aquarium::NewException.new("Exception message was \"#{e.message}\"")
  end
end

p "The raised Aquarium::Exception2 raised here won't be intercepted:"
begin
  Aquarium::Raiser.new.raise_exception2
rescue Aquarium::Exception2 => e
  p "Rescued exception: #{e.class} with message: #{e}"
end

p "The raised Aquarium::Exception1 raised here will be intercepted and"
p " Aquarium::NewException will be raised:"
begin
  Aquarium::Raiser.new.raise_exception1
rescue Aquarium::NewException => e
  p "Rescued exception: #{e.class} with message: #{e}"
end
