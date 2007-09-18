require 'aquarium/aspects/dsl/aspect_dsl'

# Add aspect convenience methods to Object. Only require this
# file if you really want these methods on all objects in your runtime!
class Object
  include Aquarium::Aspects::DSL::AspectDSL
end

