require File.dirname(__FILE__) + '/../../spec_helper.rb'
require File.dirname(__FILE__) + '/../../spec_example_classes'
require 'aquarium/aspects/dsl/aspect_dsl'

class DSLClass
  include Aquarium::Aspects::DSL::AspectDSL
end

describe "DSL method #before" do  
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end
  
  it "should be equivalent to advise :before." do
    @aspects << DSLClass.advise(:before, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "DSL method #after" do    
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after." do
    @aspects << DSLClass.advise(:after, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.after(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
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

  it "should be equivalent to advise :after." do
    @aspects << DSLClass.after(                                 :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.after_raising_within_or_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :after_returning." do
    @aspects << DSLClass.advise(:after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.after_returning(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :after_returning." do
    @aspects << DSLClass.advise(:after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.after_returning_from(    :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :after_raising." do
    class ThrowsUp
      def tosses_cookies *args; raise Exception.new(args.inspect); end
    end
    @aspects << DSLClass.advise(:after_raising, :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects << DSLClass.after_raising(         :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
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

  it "should be equivalent to advise :after_raising." do
    class ThrowsUp
      def tosses_cookies *args; raise Exception.new(args.inspect); end
    end
    @aspects << DSLClass.advise(:after_raising, :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects << DSLClass.after_raising_within(  :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
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

  it "should be equivalent to advise :before, :after." do
    @aspects << DSLClass.advise(:before, :after,  :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before_and_after(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :before and advise :after." do
    @aspects << DSLClass.advise(:before, :after,  :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before_and_after_raising_within_or_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :before and advise :after_returning." do
    @aspects << DSLClass.advise(:before, :after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before_and_after_returning(       :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :before and advise :after_returning." do
    @aspects << DSLClass.advise(:before, :after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before_and_after_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :before and advise :after_raising." do
    @aspects << DSLClass.advise(:before, :after_raising, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.before_and_after_raising(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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

  it "should be equivalent to advise :around." do
    @aspects << DSLClass.advise(:around, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << DSLClass.around(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
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
      include Aquarium::Aspects::DSL::AspectDSL
      @@watchful = Watchful1.new
      @@aspect = after(:object => @@watchful, :method => :public_watchful_method) {|jp, obj, *args|}
      def self.watchful; @@watchful; end
      def self.aspect; @@aspect; end
    end
    @aspects << DSLClass.after(:object => Watchful1.watchful, :method => :public_watchful_method) {|jp, obj, *args|}
    @aspects << Watchful1.aspect
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should ignore the default object \"self\" when a :type is specified." do
    class Watchful2
      include Aquarium::Aspects::DSL::AspectDSL
      @@aspect = after(:type => Watchful2, :method => :public_watchful_method) {|jp, obj, *args|}
      def self.aspect; @@aspect; end
    end
    @aspects << DSLClass.after(:type => Watchful2, :method => :public_watchful_method) {|jp, obj, *args|}
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
    include Aquarium::Aspects::DSL::AspectDSL
    @@aspect = nil
    def self.aspect; @@aspect; end
    def public_watchful_method; "public_watchful_method"; end
  end

  it "should infer the type as \"self\" when no :object, :type, or :pointcut is specified." do
    @aspects << DSLClass.after(:type => WatchfulSelf, :method => :public_watchful_method) {|jp, obj, *args|}
    class WatchfulSelf
      @@aspect = after(:method => :public_watchful_method) {|jp, obj, *args|}
    end
    @aspects << WatchfulSelf.aspect
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should infer the object as \"self\" when no :object, :type, or :pointcut is specified." do
    watchful_self = WatchfulSelf.new
    watchful_self.extend Aquarium::Aspects::DSL::AspectDSL
    @aspects << DSLClass.advise(:after, :pointcut => {:object => watchful_self, :method => :public_watchful_method}) {|jp, obj, *args|}
    @aspects << watchful_self.after(:method => :public_watchful_method)  {|jp, obj, *args|}
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should infer no types or objects if a :pointcut => {...} parameter is used and it does not specify a type or object." do
    @aspects << DSLClass.after(:pointcut => {:method => /method/}) {|jp, obj, *args|}
    @aspects[0].join_points_matched.size.should == 0 
  end
end

describe "DSL method #advise, when parsing the parameter list," do    
  class Watchful3
    include Aquarium::Aspects::DSL::AspectDSL
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
      include Aquarium::Aspects::DSL::AspectDSL
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
      include Aquarium::Aspects::DSL::AspectDSL
      def self.class_public_watchful_method *args; end
      def public_watchful_method *args; end
    end
    advice_called = 0
    WatchfulExampleWithSeparateAdviseCall2.advise :before, :type => WatchfulExampleWithSeparateAdviseCall2, :methods => /public_watchful_method/, :method_options =>[:instance] do |jp, obj, *args|
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
      include Aquarium::Aspects::DSL::AspectDSL
      def self.class_public_watchful_method *args; end
      def public_watchful_method *args; end
    end
    advice_called = 0
    WatchfulExampleWithSeparateAdviseCall3.advise :before, :methods => /public_watchful_method/, :method_options =>[:class] do |jp, obj, *args|
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
      include Aquarium::Aspects::DSL::AspectDSL
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
    include Aquarium::Aspects::DSL::AspectDSL
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
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = [DSLClass.after(:noop, :types => Watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":type is a synonym for :types" do
    @aspects << DSLClass.after(:noop, :type => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_types is a synonym for :types" do
    @aspects << DSLClass.after(:noop, :within_type => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_types is a synonym for :types" do
    @aspects << DSLClass.after(:noop, :within_types => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :objects" do
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = [DSLClass.after(:noop, :objects => @watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":object is a synonym for :objects" do
    @aspects << DSLClass.after(:noop, :object => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_objects is a synonym for :objects" do
    @aspects << DSLClass.after(:noop, :within_object => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_objects is a synonym for :objects" do
    @aspects << DSLClass.after(:noop, :within_objects => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :methods" do
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = [DSLClass.after(:noop, :objects => @watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":method is a synonym for :methods" do
    @aspects << DSLClass.after(:noop, :object => @watchful, :method => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_methods is a synonym for :methods" do
    @aspects << DSLClass.after(:noop, :within_object => @watchful, :within_methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_methods is a synonym for :methods" do
    @aspects << DSLClass.after(:noop, :within_objects => @watchful, :within_method => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :pointcut" do
  before :each do
    @advice = proc {|jp, obj, *args| "advice"}
    @aspects = [DSLClass.after(:noop, :pointcut => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":pointcuts is a synonym for :pointcut" do
    @aspects << DSLClass.after(:noop, :pointcuts => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
  
  it "should accept :within_pointcuts as a synonym for :pointcut." do
    @aspects << DSLClass.after(:noop, :within_pointcuts => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it "should accept :within_pointcut as a synonym for :pointcut." do
    @aspects << DSLClass.after(:noop, :within_pointcut => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "DSL method #advise (or synonyms) called within a type body" do
  it "will not advise a method whose definition hasn't been seen yet in the type body." do
    class WatchfulWithMethodAlreadyDefined
      include Aquarium::Aspects::DSL::AspectDSL
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
      include Aquarium::Aspects::DSL::AspectDSL
      @@advice_called = 0
      before(:public_watchful_method) {|jp, obj, *args| @@advice_called += 1}
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
      include Aquarium::Aspects::DSL::AspectDSL
      POINTCUT = pointcut :method => :doit
    end
    pointcut2 = Aquarium::Aspects::Pointcut.new :type => PC2, :method => :doit
    PC2::POINTCUT.join_points_matched.should     == pointcut2.join_points_matched
    PC2::POINTCUT.join_points_not_matched.should == pointcut2.join_points_not_matched
  end
end