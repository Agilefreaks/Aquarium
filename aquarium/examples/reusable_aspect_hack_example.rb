#!/usr/bin/env ruby
# Example demonstrating a hack for defining a reusable aspect in a module
# so that the aspect only gets created when the module is included by another
# module or class.
# Hacking like this defies the spirit of Aquarium's goal of being "intuitive",
# so I created a feature request #19122 to address this problem.
#
# WARNING: put the "include ..." statement at the END of the class declaration,
# as shown below. If you put the include statement at the beginning, as you
# normally wouuld for including a module, it won't advice any join points, 
# because no methods will have been defined at that point!!
 
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'aquarium'

module Aquarium
  module Reusables
    module TraceMethods
      def self.append_features mod
        Aquarium::Aspects::Aspect.new :around, 
            :type => mod, :methods => :all, :method_options => [:exclude_ancestor_methods] do |jp, object, *args|
          p "Entering: "+jp.target_type.name+"#"+jp.method_name.to_s+": args = "+args.inspect
          jp.proceed
          p "Leaving:  "+jp.target_type.name+"#"+jp.method_name.to_s+": args = "+args.inspect
        end
      end
    end    
  end
end

class NotTraced1
  def doit; p "NotTraced1#doit"; end
end
p "You will be warned that no join points in NotTraced2 were matched."
p "This happens because the include statement and hence the aspect evaluation happen BEFORE any methods are defined!"
class NotTraced2
  include Aquarium::Reusables::TraceMethods
  def doit; p "NotTraced2#doit"; end
end
class Traced1
  def doit; p "Traced1#doit"; end
  include Aquarium::Reusables::TraceMethods
end
class Traced2
  def doit; p "Traced1#doit"; end
  include Aquarium::Reusables::TraceMethods
end

p ""
p "No method tracing:"
NotTraced1.new.doit
NotTraced1.new.doit
p ""
p "Method tracing:"
Traced1.new.doit
Traced2.new.doit
