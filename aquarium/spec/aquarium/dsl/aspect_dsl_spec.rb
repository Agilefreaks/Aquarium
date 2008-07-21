require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/dsl/aspect_dsl'

class DSLClass
  include Aquarium::DSL
end

describe "Aquarium::DSL" do
  before :all do
    @advice = proc {|jp, obj, *args| "advice"}
    @pointcut_opts = {:calls_to => :public_watchful_method, :in_type => Watchful}
  end
  
  describe "DSL method #before" do  
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end
  
    it "should be equivalent to advice kind :before." do
      @aspects << DSLClass.advise(:before, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before(         :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after" do    
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after." do
      @aspects << DSLClass.advise(:after, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after(         :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after_raising" do    
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after_raising." do
      @aspects << DSLClass.advise(:after_raising, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after_raising(         :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end

    it "should be equivalent to advice kind :after_raising => exceptions, when used with the :exceptions argument." do
      @aspects << DSLClass.advise(:after_raising, :exceptions => [StandardError], :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after_raising(         :exceptions => [StandardError], :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << Aquarium::Aspects::Aspect.new(:after_raising => [StandardError], :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
      @aspects[2].specification[:after_raising].should == @aspects[0].specification[:after_raising]
    end
  end

  describe "DSL method #after_raising_within_or_returning_from" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after." do
      @aspects << DSLClass.after(                                 :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after_raising_within_or_returning_from(:noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after_returning" do      
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after_returning." do
      @aspects << DSLClass.advise(:after_returning, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after_returning(         :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after_returning_from" do      
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after_returning." do
      @aspects << DSLClass.advise(:after_returning, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.after_returning_from(    :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after_raising" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after_raising." do
      class ThrowsUp
        def tosses_cookies *args; raise Exception.new(args.inspect); end
      end
      @aspects << DSLClass.advise(:after_raising, :noop => true, :pointcut => {:sending_messages_to => :tosses_cookies, :in_type => ThrowsUp}, &@advice)
      @aspects << DSLClass.after_raising(         :noop => true, :pointcut => {:sending_messages_to => :tosses_cookies, :in_type => ThrowsUp}, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #after_raising_within" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :after_raising." do
      class ThrowsUp
        def tosses_cookies *args; raise Exception.new(args.inspect); end
      end
      @aspects << DSLClass.advise(:after_raising, :noop => true, :pointcut => {:sending_messages_to => :tosses_cookies, :in_type => ThrowsUp}, &@advice)
      @aspects << DSLClass.after_raising_within(  :noop => true, :pointcut => {:sending_messages_to => :tosses_cookies, :in_type => ThrowsUp}, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #before_and_after" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :before, :after." do
      @aspects << DSLClass.advise(:before, :after,  :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before_and_after(        :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #before_and_after_raising_within_or_returning_from" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :before and advice :after." do
      @aspects << DSLClass.advise(:before, :after,                           :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before_and_after_raising_within_or_returning_from(:noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #before_and_after_returning" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :before and advice :after_returning." do
      @aspects << DSLClass.advise(:before, :after_returning, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before_and_after_returning(       :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #before_and_after_returning_from" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :before and advice :after_returning." do
      @aspects << DSLClass.advise(:before, :after_returning, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before_and_after_returning_from(  :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #before_and_after_raising" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :before and advice :after_raising." do
      @aspects << DSLClass.advise(:before, :after_raising, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.before_and_after_raising(       :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #around" do    
    before :each do
      @dsl = DSLClass.new
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should be equivalent to advice kind :around." do
      @aspects << DSLClass.advise(:around, :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects << DSLClass.around(         :noop => true, :pointcut => @pointcut_opts, &@advice)
      @aspects[1].should == @aspects[0]
    end
  end

  describe "DSL method #advise, when determining the \"self\" to advise," do    
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end
  
    it "should ignore the default object \"self\" when an :object is specified." do
      class Watchful1
        include Aquarium::DSL
        def public_watchful_method; end
        @@watchful = Watchful1.new
        @@aspect = after(:invoking => :public_watchful_method, :on_object => @@watchful) {|jp, obj, *args|}
        def self.watchful; @@watchful; end
        def self.aspect; @@aspect; end
      end
      @aspects << Watchful1.after(:invoking => :public_watchful_method, :on_object => Watchful1.watchful) {|jp, obj, *args|}
      @aspects << Watchful1.aspect
      @aspects[0].join_points_matched.should_not be_empty
      @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
      @aspects[1].pointcuts.should == @aspects[0].pointcuts
    end

    it "should ignore the default object \"self\" when a :type is specified." do
      class Watchful2
        include Aquarium::DSL
        def public_watchful_method; end
        @@aspect = after(:calls_to => :public_watchful_method, :in_type => Watchful2) {|jp, obj, *args|}
        def self.aspect; @@aspect; end
      end
      @aspects << Watchful2.after(:calls_to => :public_watchful_method, :in_type => Watchful2) {|jp, obj, *args|}
      @aspects << Watchful2.aspect
      @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
      @aspects[1].pointcuts.should == @aspects[0].pointcuts
    end
  end

  describe "DSL method #advise, when determining the type or object to advise," do    
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    class WatchfulSelf
      include Aquarium::DSL
      @@aspect = nil
      def self.aspect; @@aspect; end
      def public_watchful_method; "public_watchful_method"; end
    end

    it "should infer the type as \"self\" when no :object, :type, or :pointcut is specified." do
      @aspects << WatchfulSelf.after(:calls_to => :public_watchful_method, :in_type => WatchfulSelf) {|jp, obj, *args|}
      class WatchfulSelf
        @@aspect = after(:method => :public_watchful_method) {|jp, obj, *args|}
      end
      @aspects << WatchfulSelf.aspect
      @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
      @aspects[1].pointcuts.should == @aspects[0].pointcuts
    end

    it "should infer the object as \"self\" when no :object, :type, or :pointcut is specified." do
      watchful_self = WatchfulSelf.new
      watchful_self.extend Aquarium::DSL
      @aspects << WatchfulSelf.advise(:after, :pointcut => {:invoking => :public_watchful_method, :on_object => watchful_self}) {|jp, obj, *args|}
      @aspects << watchful_self.after(:method => :public_watchful_method)  {|jp, obj, *args|}
      @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    end

    it "should infer no types or objects if a :pointcut => {...} parameter is used and it does not specify a type or object." do
      @aspects << DSLClass.after(:pointcut => {:method => /method/}, :ignore_no_matching_join_points=>true) {|jp, obj, *args|}
      @aspects[0].join_points_matched.size.should == 0 
    end
  end

  describe "DSL method #advise, when parsing the parameter list," do    
    class Watchful3
      include Aquarium::DSL
      def public_watchful_method; "public_watchful_method"; end
    end

    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should infer the first symbol parameter after the advice kind parameter to be the method name to advise if no other :method => ... parameter is used." do
      @aspects << Watchful3.after(:public_watchful_method) {|jp, obj, *args|}
      @aspects.each do |aspect|
        aspect.join_points_matched.size.should == 1 
        aspect.specification[:methods].should == Set.new([:public_watchful_method])
      end
    end
  end

  describe "DSL method #advise, when determining instance or class methods to advise," do    
    before :each do
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    it "should treat \"ClassName.advise\" as advising instance methods, by default." do
      class WatchfulExampleWithSeparateAdviseCall
        include Aquarium::DSL
        def public_watchful_method *args; end
      end
      advice_called = 0
      WatchfulExampleWithSeparateAdviseCall.advise :before, :public_watchful_method do |jp, obj, *args|
        advice_called += 1
      end
      WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a1, :a2
      WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a3, :a4
      advice_called.should == 2
    end
  
    it "should treat \"ClassName.advise\" as advising instance methods when the :instance method option is specified." do
      class WatchfulExampleWithSeparateAdviseCall2
        include Aquarium::DSL
        def self.class_public_watchful_method *args; end
        def public_watchful_method *args; end
      end
      advice_called = 0
      WatchfulExampleWithSeparateAdviseCall2.advise :before, :sending_messages_to => /public_watchful_method/, :on_types => WatchfulExampleWithSeparateAdviseCall2, :restricting_methods_to =>[:instance_methods] do |jp, obj, *args|
        advice_called += 1
      end
      WatchfulExampleWithSeparateAdviseCall2.class_public_watchful_method :a1, :a2
      WatchfulExampleWithSeparateAdviseCall2.class_public_watchful_method :a3, :a4
      advice_called.should == 0
      WatchfulExampleWithSeparateAdviseCall2.new.public_watchful_method :a1, :a2
      WatchfulExampleWithSeparateAdviseCall2.new.public_watchful_method :a3, :a4
      advice_called.should == 2
    end
  
    it "should treat \"ClassName.advise\" as advising class methods when the :class method option is specified." do
      class WatchfulExampleWithSeparateAdviseCall3
        include Aquarium::DSL
        def self.class_public_watchful_method *args; end
        def public_watchful_method *args; end
      end
      advice_called = 0
      WatchfulExampleWithSeparateAdviseCall3.advise :before, :calling => /public_watchful_method/, :restricting_methods_to =>[:class_methods] do |jp, obj, *args|
        advice_called += 1
      end
      WatchfulExampleWithSeparateAdviseCall3.class_public_watchful_method :a1, :a2
      WatchfulExampleWithSeparateAdviseCall3.class_public_watchful_method :a3, :a4
      advice_called.should == 2
      WatchfulExampleWithSeparateAdviseCall3.new.public_watchful_method :a1, :a2
      WatchfulExampleWithSeparateAdviseCall3.new.public_watchful_method :a3, :a4
      advice_called.should == 2
    end
  
    it "should invoke the type-based advise for all objects when the aspect is defined by calling #advise within the class definition." do
      class WatchfulExampleWithBeforeAdvice
        include Aquarium::DSL
        @@advice_called = 0
        def public_watchful_method *args; end
        before :public_watchful_method do |jp, obj, *args|
          @@advice_called += 1
        end
        def self.advice_called; @@advice_called; end
      end
      WatchfulExampleWithBeforeAdvice.new.public_watchful_method :a1, :a2
      WatchfulExampleWithBeforeAdvice.new.public_watchful_method :a3, :a4
      WatchfulExampleWithBeforeAdvice.advice_called.should == 2
    end
  end

  describe "DSL methods for the advice kind, when determining instance or class methods to advise," do    
    class Watchful4
      include Aquarium::DSL
      def public_watchful_method; "public_watchful_method"; end
    end

    before :each do
      @advice = proc {|jp, obj, *args| "advice"}
      @aspects = []
    end
    after :each do
      @aspects.each {|a| a.unadvise}
    end

    (Aquarium::Aspects::Advice.kinds + [:after_raising_within_or_returning_from]).each do |advice_kind|
      it "##{advice_kind} method should infer the first symbol parameter as the method name to advise if no other :method => ... parameter is used." do
        @aspects << Watchful4.method(advice_kind).call(:public_watchful_method, &@advice)
        @aspects.each do |aspect|
          aspect.join_points_matched.size.should == 1 
          aspect.specification[:methods].should == Set.new([:public_watchful_method])
        end
      end
    end
  end

  describe "Synonyms for :types" do
    Aquarium::Aspects::Aspect::CANONICAL_OPTIONS["types"].each do |key|
      it "should accept :#{key} as a synonym for :types." do
        advice = proc {|jp, obj, *args| "advice"}
        aspect1 = DSLClass.after :noop => true, :calls_to => :public_watchful_method, :types     => Watchful, &advice
        aspect2 = DSLClass.after :noop => true, :calls_to => :public_watchful_method, key.intern => Watchful, &advice
        aspect2.should == aspect1
        aspect1.unadvise
        aspect2.unadvise
      end
    end
  end

  describe "Synonyms for :objects" do
    Aquarium::Aspects::Aspect::CANONICAL_OPTIONS["objects"].each do |key|
      it "should accept :#{key} as a synonym for :objects." do
        watchful = Watchful.new
        advice = proc {|jp, obj, *args| "advice"}
        aspect1 = DSLClass.after :noop => true, :calls_to => :public_watchful_method, :objects   => watchful, &advice
        aspect2 = DSLClass.after :noop => true, :calls_to => :public_watchful_method, key.intern => watchful, &advice
        aspect2.should == aspect1
        aspect1.unadvise
        aspect2.unadvise
      end
    end
  end

  describe "Synonyms for :methods" do
    Aquarium::Aspects::Aspect::CANONICAL_OPTIONS["methods"].each do |key|
      it "should accept :#{key} as a synonym for :methods." do
        advice = proc {|jp, obj, *args| "advice"}
        aspect1 = DSLClass.after :noop => true, :methods   => :public_watchful_method, :in_types => Watchful, &advice
        aspect2 = DSLClass.after :noop => true, key.intern => :public_watchful_method, :in_types => Watchful, &advice
        aspect2.should == aspect1
        aspect1.unadvise
        aspect2.unadvise
      end
    end
  end

  describe "Synonyms for :pointcuts" do
    Aquarium::Aspects::Aspect::CANONICAL_OPTIONS["pointcuts"].each do |key|
      it "should accept :#{key} as a synonym for :pointcuts." do
        watchful = Watchful.new
        advice = proc {|jp, obj, *args| "advice"}
        aspect1 = DSLClass.after :noop => true, :pointcuts => {:calls_to => :public_watchful_method, :within_objects => watchful}, &advice
        aspect2 = DSLClass.after :noop => true, key.intern => {:calls_to => :public_watchful_method, :within_objects => watchful}, &advice
        aspect2.should == aspect1
        aspect1.unadvise
        aspect2.unadvise
      end
    end
  end

  describe "DSL method #advise (or synonyms) called within a type body" do
    it "will not advise a method whose definition hasn't been seen yet in the type body." do
      class WatchfulWithMethodAlreadyDefined
        include Aquarium::DSL
        @@advice_called = 0
        def public_watchful_method *args; end
        before :public_watchful_method do |jp, obj, *args|
          @@advice_called += 1
        end
        def self.advice_called; @@advice_called; end
      end
      WatchfulWithMethodAlreadyDefined.new.public_watchful_method :a1, :a2
      WatchfulWithMethodAlreadyDefined.new.public_watchful_method :a3, :a4
      WatchfulWithMethodAlreadyDefined.advice_called.should == 2
      class WatchfulWithMethodNotYetDefined
        include Aquarium::DSL
        @@advice_called = 0
        before(:public_watchful_method, :ignore_no_matching_join_points=>true) {|jp, obj, *args| @@advice_called += 1}
        def public_watchful_method *args; end
        def self.advice_called; @@advice_called; end
      end
      WatchfulWithMethodNotYetDefined.new.public_watchful_method :a1, :a2
      WatchfulWithMethodNotYetDefined.new.public_watchful_method :a3, :a4
      WatchfulWithMethodNotYetDefined.advice_called.should == 0
    end
  end

  describe "DSL method #pointcut" do
    class PC1; 
      def doit; end
    end
  
    it "should match equivalent join points as Pointcut.new" do
      pointcut1 = DSLClass.pointcut :type => PC1, :method => :doit
      pointcut2 = Aquarium::Aspects::Pointcut.new :type => PC1, :method => :doit
      pointcut1.join_points_matched.should     == pointcut2.join_points_matched
      pointcut1.join_points_not_matched.should == pointcut2.join_points_not_matched
    end
  
    it "should use self as the object if no object or type is specified." do
      class PC2
        include Aquarium::DSL
        POINTCUT = pointcut :method => :doit
      end
      pointcut2 = Aquarium::Aspects::Pointcut.new :type => PC2, :method => :doit
      PC2::POINTCUT.join_points_matched.should     == pointcut2.join_points_matched
      PC2::POINTCUT.join_points_not_matched.should == pointcut2.join_points_not_matched
    end
  end
end

class OldDSLClass
  include Aquarium::Aspects::DSL::AspectDSL
end
describe "DSL methods available through the old package Aquarium::Aspects::DSL::AspectDSL" do    
  before :each do
    @dsl = OldDSLClass.new
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advice kind :around." do
    @aspects << OldDSLClass.advise(:around, :noop => true, :pointcut => @pointcut_opts, &@advice)
    @aspects << OldDSLClass.around(         :noop => true, :pointcut => @pointcut_opts, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

