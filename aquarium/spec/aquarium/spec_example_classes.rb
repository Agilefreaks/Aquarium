# :enddoc:

require 'aquarium/aspects/dsl/aspect_dsl'

# Declares classes, etc. that support several different module specs.
class ExampleParentClass
  def == other
    self.object_id == other.object_id or self.class == other.class
  end
  alias :eql? :==
end

class ClassWithPublicInstanceMethod < ExampleParentClass
  def public_instance_test_method
  end
end
class ClassWithPublicInstanceMethod2 < ExampleParentClass
  def public_instance_test_method2
  end
end
class ClassWithProtectedInstanceMethod < ExampleParentClass
  protected
  def protected_instance_test_method
  end
end
class ClassWithPrivateInstanceMethod < ExampleParentClass
  private
  def private_instance_test_method
  end
end

class ClassWithPublicClassMethod < ExampleParentClass
  def self.public_class_test_method
  end
end
class ClassWithPrivateClassMethod < ExampleParentClass
  def self.private_class_test_method
  end
  private_class_method :private_class_test_method
end

class ClassWithAttribs < ExampleParentClass
  attr_accessor :attrRW_ClassWithAttribs, :name
  attr_reader   :attrR_ClassWithAttribs
  attr_writer   :attrW_ClassWithAttribs
  def initialize
    @name = "Name"
  end
  def eql? other
    super(other) && name.eql?(other.name)
  end
  alias :== :eql?
end

class Watchful 
  include Aquarium::Aspects::DSL::AspectDSL
  class WatchfulError < Exception
    def initialize message = nil
      super
    end
  end
  
  def eql? other
    super && instance_variables.each do |var|
      return false unless instance_variable_get(var) == other.instance_variable_get(var)
    end
  end
  alias :== :eql?

  %w[public protected private].each do |protection|
    class_eval(<<-EOF, __FILE__, __LINE__)
      public
      attr_accessor :#{protection}_watchful_method_args, :#{protection}_watchful_method_that_raises_args
      #{protection}
      def #{protection}_watchful_method *args
        @#{protection}_watchful_method_args = args
        yield *args if block_given?
      end
      def #{protection}_watchful_method_that_raises *args
        @#{protection}_watchful_method_that_raises_args = args
        yield *args if block_given?
        raise WatchfulError.new #("#{protection}_watchful_method_that_raises")
      end
    EOF
  end

  %w[public private].each do |protection|
    class_eval(<<-EOF, __FILE__, __LINE__)
      @@#{protection}_class_watchful_method_args = nil
      @@#{protection}_class_watchful_method_that_raises_args = nil
      class << self
        public
        def #{protection}_class_watchful_method_args
          @@#{protection}_class_watchful_method_args
        end
        def #{protection}_class_watchful_method_args= args
          @@#{protection}_class_watchful_method_args = args
        end
        def #{protection}_class_watchful_method_that_raises_args
          @@#{protection}_class_watchful_method_that_raises_args
        end
        def #{protection}_class_watchful_method_that_raises_args args
          @@#{protection}_class_watchful_method_that_raises_args = args
        end
      
        def #{protection}_class_watchful_method *args
          @@#{protection}_class_watchful_method_args = args
          yield *args if block_given?
        end
        def #{protection}_class_watchful_method_that_raises *args
          @@#{protection}_class_watchful_method_that_raises_args = args
          yield *args if block_given?
          raise WatchfulError.new #("#{protection}_class_watchful_method_that_raises")
        end
        #{protection} :#{protection}_class_watchful_method, :#{protection}_class_watchful_method_that_raises
      end
    EOF
  end
end

class WatchfulChild < Watchful; end
