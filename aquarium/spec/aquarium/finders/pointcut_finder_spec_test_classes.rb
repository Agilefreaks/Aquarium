
module Aquarium
  module PointcutFinderTestClasses
    class PointcutConstantHolder1
      include Aquarium::DSL
      def mc1; end
      def doit; mc1; end
      POINTCUT1 = pointcut :calls_to => :mc1 unless const_defined?("POINTCUT1") 
    end
    class PointcutConstantHolder2
      include Aquarium::DSL
      def mc2; end
      def doit; mc2; end
      POINTCUT2 = pointcut :calls_to => :mc2 unless const_defined?("POINTCUT2")
    end
    class PointcutClassVariableHolder1
      include Aquarium::DSL
      def mcv1; end
      def doit; mcv1; end
      @@pointcut1 = pointcut :calls_to => :mcv1
      def self.pointcut1; @@pointcut1; end
    end
    class OuterPointcutHolder
      class NestedPointcutConstantHolder1
        include Aquarium::DSL
        def mc11; end
        def doit; mc11; end
        POINTCUT11 = pointcut :calls_to => :mc11 unless const_defined?("POINTCUT11")
      end
      class NestedPointcutClassVariableHolder1
        include Aquarium::DSL
        def mcv11; end
        def doit; mcv11; end
        @@pointcut11 = pointcut :calls_to => :mcv11
        def self.pointcut11; @@pointcut11; end
      end
    end
    class ParentOfPointcutHolder; end
    class PointcutConstantHolderChild < ParentOfPointcutHolder
      include Aquarium::DSL
      def mc; end
      def doit; mc; end
      POINTCUT = pointcut :calls_to => :mc unless const_defined?("POINTCUT")
    end
    class DescendentOfPointcutConstantHolderChild < PointcutConstantHolderChild; end
  
    def self.sort_pc_array pc_array
      pc_array.sort{|x,y| x.object_id <=> y.object_id}
    end
    def self.found_pointcuts_should_match found_result_set, expected_found_pc_array, expected_not_found_type_array = []
      found_result_set.matched.size.should == expected_found_pc_array.size
      found_result_set.not_matched.size.should == expected_not_found_type_array.size
      self.sort_pc_array(found_result_set.found_pointcuts).should == expected_found_pc_array
    end

    def self.all_pointcut_classes
      [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1, 
       Aquarium::PointcutFinderTestClasses::PointcutConstantHolder2,
       Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1,  
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutConstantHolder1, 
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutClassVariableHolder1]
    end
    def self.all_constants_pointcut_classes
      [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1, 
       Aquarium::PointcutFinderTestClasses::PointcutConstantHolder2,
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutConstantHolder1]
    end
    def self.all_class_variables_pointcut_classes
      [Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1,  
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutClassVariableHolder1]
    end

    def self.all_pointcuts
      sort_pc_array [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1::POINTCUT1, 
       Aquarium::PointcutFinderTestClasses::PointcutConstantHolder2::POINTCUT2,
       Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1.pointcut1,  
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutConstantHolder1::POINTCUT11, 
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutClassVariableHolder1.pointcut11]
    end
    def self.all_constants_pointcuts
      sort_pc_array [Aquarium::PointcutFinderTestClasses::PointcutConstantHolder1::POINTCUT1, 
       Aquarium::PointcutFinderTestClasses::PointcutConstantHolder2::POINTCUT2,
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutConstantHolder1::POINTCUT11]
    end
    def self.all_class_variables_pointcuts
      sort_pc_array [Aquarium::PointcutFinderTestClasses::PointcutClassVariableHolder1.pointcut1,  
       Aquarium::PointcutFinderTestClasses::OuterPointcutHolder::NestedPointcutClassVariableHolder1.pointcut11]
    end
  end
end