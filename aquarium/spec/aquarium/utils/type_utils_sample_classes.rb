class BaseForDescendents; end
module ModuleForDescendents; end
class D1ForDescendents  < BaseForDescendents
  include ModuleForDescendents
end
class D2ForDescendents  < BaseForDescendents; end
class D11ForDescendents < D1ForDescendents; end

module Aquarium
  module ForDescendents
    class NestedBaseForDescendents; end
    module NestedModuleForDescendents; end
    class NestedD1ForDescendents  < NestedBaseForDescendents
      include NestedModuleForDescendents
    end
    class NestedD2ForDescendents  < NestedBaseForDescendents; end
    class NestedD11ForDescendents < NestedD1ForDescendents; end
    
    class NestedD3ForDescendents < BaseForDescendents
      include ModuleForDescendents
    end
    class NestedD4ForDescendents  < BaseForDescendents; end
    class NestedD31ForDescendents < D1ForDescendents; end
    
    module Nested2ModuleForDescendents
      include ModuleForDescendents
    end
  end
end

