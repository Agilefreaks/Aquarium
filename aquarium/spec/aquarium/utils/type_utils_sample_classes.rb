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

module Aquarium
  module Utils
    module TypeUtils
      @@sample_modules = [
        ModuleForDescendents,
        Aquarium::ForDescendents::NestedModuleForDescendents,
        Aquarium::ForDescendents::Nested2ModuleForDescendents]

      @@sample_classes = [
        BaseForDescendents,
        D1ForDescendents,
        D2ForDescendents,
        D11ForDescendents,
        Aquarium::ForDescendents::NestedBaseForDescendents,
        Aquarium::ForDescendents::NestedD1ForDescendents,
        Aquarium::ForDescendents::NestedD2ForDescendents,
        Aquarium::ForDescendents::NestedD11ForDescendents,
        Aquarium::ForDescendents::NestedD3ForDescendents,
        Aquarium::ForDescendents::NestedD4ForDescendents,
        Aquarium::ForDescendents::NestedD31ForDescendents]

      @@sample_types = @@sample_modules + @@sample_classes

      def self.sample_types;   @@sample_types;   end
      def self.sample_modules; @@sample_modules; end
      def self.sample_classes; @@sample_classes; end
      
      
      @@sample_modules_descendents = {
        ModuleForDescendents => [
          Aquarium::ForDescendents::Nested2ModuleForDescendents,
          Aquarium::ForDescendents::NestedD31ForDescendents,
          Aquarium::ForDescendents::NestedD3ForDescendents,
          D11ForDescendents,
          D1ForDescendents,
          ModuleForDescendents],
        Aquarium::ForDescendents::NestedModuleForDescendents => [
          Aquarium::ForDescendents::NestedD11ForDescendents,
          Aquarium::ForDescendents::NestedD1ForDescendents,
          Aquarium::ForDescendents::NestedModuleForDescendents],
        Aquarium::ForDescendents::Nested2ModuleForDescendents => [
          Aquarium::ForDescendents::Nested2ModuleForDescendents]}

      @@sample_classes_descendents = {
        BaseForDescendents => [
          Aquarium::ForDescendents::NestedD31ForDescendents,
          Aquarium::ForDescendents::NestedD3ForDescendents,
          Aquarium::ForDescendents::NestedD4ForDescendents,
          BaseForDescendents,
          D11ForDescendents,
          D1ForDescendents,
          D2ForDescendents],
        D1ForDescendents => [
          Aquarium::ForDescendents::NestedD31ForDescendents,
          D11ForDescendents,
          D1ForDescendents],
        D2ForDescendents => [D2ForDescendents],
        D11ForDescendents => [D11ForDescendents],
        Aquarium::ForDescendents::NestedBaseForDescendents => [
          Aquarium::ForDescendents::NestedBaseForDescendents,
          Aquarium::ForDescendents::NestedD11ForDescendents,
          Aquarium::ForDescendents::NestedD1ForDescendents,
          Aquarium::ForDescendents::NestedD2ForDescendents],
        Aquarium::ForDescendents::NestedD1ForDescendents => [
          Aquarium::ForDescendents::NestedD11ForDescendents,
          Aquarium::ForDescendents::NestedD1ForDescendents],
        Aquarium::ForDescendents::NestedD2ForDescendents => [
          Aquarium::ForDescendents::NestedD2ForDescendents],
        Aquarium::ForDescendents::NestedD11ForDescendents => [
          Aquarium::ForDescendents::NestedD11ForDescendents],
        Aquarium::ForDescendents::NestedD3ForDescendents => [
          Aquarium::ForDescendents::NestedD3ForDescendents],
        Aquarium::ForDescendents::NestedD4ForDescendents => [
          Aquarium::ForDescendents::NestedD4ForDescendents],
        Aquarium::ForDescendents::NestedD31ForDescendents => [
          Aquarium::ForDescendents::NestedD31ForDescendents]}
  
      @@sample_types_descendents = @@sample_classes_descendents.merge @@sample_modules_descendents


      @@sample_modules_ancestors = {
        ModuleForDescendents => [ModuleForDescendents],
        Aquarium::ForDescendents::NestedModuleForDescendents => [Aquarium::ForDescendents::NestedModuleForDescendents],
        Aquarium::ForDescendents::Nested2ModuleForDescendents => [
          Aquarium::ForDescendents::Nested2ModuleForDescendents,
          ModuleForDescendents]}

      @@sample_classes_ancestors = {
        BaseForDescendents => [
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        D1ForDescendents => [
          D1ForDescendents,
          ModuleForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        D2ForDescendents => [
          D2ForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        D11ForDescendents => [
          D11ForDescendents,
          D1ForDescendents,
          ModuleForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedBaseForDescendents => [
          Aquarium::ForDescendents::NestedBaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD1ForDescendents => [
          Aquarium::ForDescendents::NestedD1ForDescendents,
          Aquarium::ForDescendents::NestedModuleForDescendents,
          Aquarium::ForDescendents::NestedBaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD2ForDescendents => [
          Aquarium::ForDescendents::NestedD2ForDescendents,
          Aquarium::ForDescendents::NestedBaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD11ForDescendents => [
          Aquarium::ForDescendents::NestedD11ForDescendents,
          Aquarium::ForDescendents::NestedD1ForDescendents,
          Aquarium::ForDescendents::NestedModuleForDescendents,
          Aquarium::ForDescendents::NestedBaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD3ForDescendents => [
          Aquarium::ForDescendents::NestedD3ForDescendents,
          ModuleForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD4ForDescendents => [
          Aquarium::ForDescendents::NestedD4ForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel],
        Aquarium::ForDescendents::NestedD31ForDescendents => [
          Aquarium::ForDescendents::NestedD31ForDescendents,
          D1ForDescendents,
          ModuleForDescendents,
          BaseForDescendents,
          BasicObject,
          Object,
          Kernel]}
          
        @@sample_types_ancestors = @@sample_classes_ancestors.merge @@sample_modules_ancestors 
          

        %w[types modules classes].each do |x|
          class_eval <<-EOF
            def self.sample_#{x}_descendents
              @@sample_#{x}_descendents
            end
            def self.sample_#{x}_ancestors
              @@sample_#{x}_ancestors
            end
            def self.sample_#{x}_descendents_and_ancestors
              self.sample_#{x}_descendents & sample_#{x}_ancestors
            end
          EOF
        end
          
    end
  end
end
    
    