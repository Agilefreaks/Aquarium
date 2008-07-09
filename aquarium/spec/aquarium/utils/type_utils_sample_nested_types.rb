module Aquarium
  module NestedTestTypes
    def ntt; end
    module TopModule
      def tm; end
      module MiddleModule
        def mm; end
        module BottomModule
          def bm; end
        end
        class BottomModuleClass
          def bmc; end
        end
      end
    end
    class TopClass
      def tc; end
      class MiddleClass
        def mc; end
        class BottomClass
          def bc; end
        end
      end
    end
  end
end


module Aquarium
  module NestedTestTypes
    @@bottom_modules = [Aquarium::NestedTestTypes::TopModule::MiddleModule::BottomModule]
    @@bottom_modules_classes = [Aquarium::NestedTestTypes::TopModule::MiddleModule::BottomModuleClass]
    @@middle_modules = [Aquarium::NestedTestTypes::TopModule::MiddleModule] + @@bottom_modules + @@bottom_modules_classes
    @@top_modules = [Aquarium::NestedTestTypes::TopModule] + @@middle_modules
    @@bottom_classes = [Aquarium::NestedTestTypes::TopClass::MiddleClass::BottomClass]
    @@middle_classes = [Aquarium::NestedTestTypes::TopClass::MiddleClass] + @@bottom_classes
    @@top_classes = [Aquarium::NestedTestTypes::TopClass] + @@middle_classes
    @@all_types = [Aquarium::NestedTestTypes] + @@top_modules + @@top_classes
    def self.nested_in_NestedTestTypes 
      {Aquarium::NestedTestTypes => @@all_types,
       Aquarium::NestedTestTypes::TopModule => @@top_modules,
       Aquarium::NestedTestTypes::TopModule::MiddleModule => @@middle_modules,
       Aquarium::NestedTestTypes::TopModule::MiddleModule::BottomModule => @@bottom_modules,
       Aquarium::NestedTestTypes::TopModule::MiddleModule::BottomModuleClass => @@bottom_modules_classes,
       Aquarium::NestedTestTypes::TopClass => @@top_classes,
       Aquarium::NestedTestTypes::TopClass::MiddleClass => @@middle_classes,
       Aquarium::NestedTestTypes::TopClass::MiddleClass::BottomClass => @@bottom_classes}
    end
  end
end

