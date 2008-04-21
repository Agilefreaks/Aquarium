require 'aquarium/dsl/aspect_dsl'

# Add the Aquarium::DSL convenience methods to Object. Only require this
# file if you <i>really</i> want these methods on all objects in your runtime!
# For example, Rails already adds <tt>before</tt> and <tt>after</tt> methods
# to object, so including this file is not compatible!
class Object
  include Aquarium::DSL
end

