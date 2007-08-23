require File.dirname(__FILE__) + '/../../spec_helper.rb'
require File.dirname(__FILE__) + '/../../spec_example_classes'
require 'aquarium/aspects/dsl/aspect_dsl'

describe Object, "#before" do  
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end
  
  it "should be equivalent to advise :before." do
    @aspects << advise(:before, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after." do
    @aspects << advise(:after, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << after(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after_raising_within_or_returning_from" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after." do
    @aspects << after(                                 :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << after_raising_within_or_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after_returning" do      
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after_returning." do
    @aspects << advise(:after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << after_returning(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after_returning_from" do      
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after_returning." do
    @aspects << advise(:after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << after_returning_from(    :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after_raising" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after_raising." do
    class ThrowsUp
      def tosses_cookies *args; raise Exception.new(args.inspect); end
    end
    @aspects << advise(:after_raising, :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects << after_raising(         :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#after_raising_within" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :after_raising." do
    class ThrowsUp
      def tosses_cookies *args; raise Exception.new(args.inspect); end
    end
    @aspects << advise(:after_raising, :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects << after_raising_within(  :noop, :pointcut => {:type => ThrowsUp, :methods => :tosses_cookies}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#before_and_after" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :before, :after." do
    @aspects << advise(:before, :after,  :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before_and_after(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#before_and_after_raising_within_or_returning_from" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :before and advise :after." do
    @aspects << advise(:before, :after,  :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before_and_after_raising_within_or_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#before_and_after_returning" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :before and advise :after_returning." do
    @aspects << advise(:before, :after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before_and_after_returning(       :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#before_and_after_returning_from" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :before and advise :after_returning." do
    @aspects << advise(:before, :after_returning, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before_and_after_returning_from(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#before_and_after_raising" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :before and advise :after_raising." do
    @aspects << advise(:before, :after_raising, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << before_and_after_raising(:noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#around" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it "should be equivalent to advise :around." do
    @aspects << advise(:around, :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects << around(         :noop, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#advise (inferred arguments)" do    
  before :each do
    @watchful = Watchful.new
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end
  
  it "should ignore the default object \"self\" when an :object is specified." do
    class Watchful
      @@watchful = Watchful.new
      @@aspect = after(:object => @@watchful, :method => :public_watchful_method) {|jp,*args|}
      def self.watchful; @@watchful; end
      def self.aspect; @@aspect; end
    end
    @aspects << after(:object => Watchful.watchful, :method => :public_watchful_method) {|jp,*args|}
    @aspects << Watchful.aspect
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should ignore the default object \"self\" when a :type is specified." do
    class Watchful
      @@aspect = after(:type => Watchful, :method => :public_watchful_method) {|jp,*args|}
      def self.aspect; @@aspect; end
    end
    @aspects << after(:type => Watchful, :method => :public_watchful_method) {|jp,*args|}
    @aspects << Watchful.aspect
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should infer the type to advise as \"self\" when no :object, :type, or :pointcut is specified." do
    @aspects << after(:type => Watchful, :method => :public_watchful_method) {|jp,*args|}
    class Watchful
      @@aspect = after(:method => :public_watchful_method) {|jp,*args|}
      def self.aspect; @@aspect; end
    end
    @aspects << Watchful.aspect
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should treat \"ClassName.advise\" as advising instance methods, by default." do
    class WatchfulExampleWithSeparateAdviseCall
      def public_watchful_method *args; end
    end
    advice_called = 0
    WatchfulExampleWithSeparateAdviseCall.before :public_watchful_method do |jp, *args|
      advice_called += 1
    end
    WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a1, :a2
    WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a3, :a4
    advice_called.should == 2
  end
  
  it "should treat \"ClassName.advise\" as advising instance methods when the :instance method option is specified." do
    class WatchfulExampleWithSeparateAdviseCall2
      def self.class_public_watchful_method *args; end
      def public_watchful_method *args; end
    end
    advice_called = 0
    Aquarium::Aspects::Aspect.new :before, :type => WatchfulExampleWithSeparateAdviseCall2, :methods => /public_watchful_method/, :method_options =>[:instance] do |jp, *args|
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
    class WatchfulExampleWithSeparateAdviseCall
      def self.class_public_watchful_method *args; end
      def public_watchful_method *args; end
    end
    advice_called = 0
    WatchfulExampleWithSeparateAdviseCall.before :methods => /public_watchful_method/, :method_options =>[:class] do |jp, *args|
      advice_called += 1
    end
    WatchfulExampleWithSeparateAdviseCall.class_public_watchful_method :a1, :a2
    WatchfulExampleWithSeparateAdviseCall.class_public_watchful_method :a3, :a4
    advice_called.should == 2
    WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a1, :a2
    WatchfulExampleWithSeparateAdviseCall.new.public_watchful_method :a3, :a4
    advice_called.should == 2
  end
  
  it "should invoke the type-based advise for all objects when the aspect is defined by calling #advise within the class definition." do
    class WatchfulExampleWithBeforeAdvice
      @@advice_called = 0
      def public_watchful_method *args; end
      before :public_watchful_method do |jp, *args|
        @@advice_called += 1
      end
      def self.advice_called; @@advice_called; end
    end
    WatchfulExampleWithBeforeAdvice.new.public_watchful_method :a1, :a2
    WatchfulExampleWithBeforeAdvice.new.public_watchful_method :a3, :a4
    WatchfulExampleWithBeforeAdvice.advice_called.should == 2
  end

  it "should infer the object to advise as \"self\" when no :object, :type, or :pointcut is specified." do
    @aspects << @watchful.after(:method => :public_watchful_method)  {|jp,*args|}
    @aspects << advise(         :after, :pointcut => {:object => @watchful, :method => :public_watchful_method}) {|jp,*args|}
    @aspects[1].join_points_matched.should == @aspects[0].join_points_matched
    @aspects[1].pointcuts.should == @aspects[0].pointcuts
  end

  it "should infer no types or objects if a :pointcut => {...} parameter is used and it does not specify a type or object." do
    @aspects << after(:pointcut => {:method => /method/}) {|jp,*args|}
    @aspects[0].join_points_matched.size.should == 0 
  end

  it "should infer the first symbol parameter after the advice kind parameter is the method name to advise if no other :method => ... parameter is used." do
    @aspects << @watchful.after( :public_watchful_method) {|jp,*args|}
    @aspects.each do |aspect|
      aspect.join_points_matched.size.should == 1 
      aspect.specification[:methods].should == Set.new([:public_watchful_method])
    end
  end
end

describe Object, "advice kind convenience methods (inferred arguments)" do    
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @watchful = Watchful.new
    @aspects = []
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  (Aquarium::Aspects::Advice.kinds + [:after_raising_within_or_returning_from]).each do |advice_kind|
    it "##{advice_kind} method should infer the first symbol parameter as the method name to advise if no other :method => ... parameter is used." do
      @aspects << @watchful.method(advice_kind).call(:public_watchful_method, &@advice)
      @aspects.each do |aspect|
        aspect.join_points_matched.size.should == 1 
        aspect.specification[:methods].should == Set.new([:public_watchful_method])
      end
    end
  end
end

describe "Synonyms for :types" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @aspects = [after(:noop, :types => Watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":type is a synonym for :types" do
    @aspects << after(:noop, :type => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_types is a synonym for :types" do
    @aspects << after(:noop, :within_type => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_types is a synonym for :types" do
    @aspects << after(:noop, :within_types => Watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :objects" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @watchful = Watchful.new
    @aspects = [after(:noop, :objects => @watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":object is a synonym for :objects" do
    @aspects << after(:noop, :object => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_objects is a synonym for :objects" do
    @aspects << after(:noop, :within_object => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_objects is a synonym for :objects" do
    @aspects << after(:noop, :within_objects => @watchful, :methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :methods" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @watchful = Watchful.new
    @aspects = [after(:noop, :objects => @watchful, :methods => :public_watchful_method, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":method is a synonym for :methods" do
    @aspects << after(:noop, :object => @watchful, :method => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_methods is a synonym for :methods" do
    @aspects << after(:noop, :within_object => @watchful, :within_methods => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it ":within_methods is a synonym for :methods" do
    @aspects << after(:noop, :within_objects => @watchful, :within_method => :public_watchful_method, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe "Synonyms for :pointcut" do
  before :each do
    @advice = proc {|jp,*args| "advice"}
    @watchful = Watchful.new
    @aspects = [after(:noop, :pointcut => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)]
  end
  after :each do
    @aspects.each {|a| a.unadvise}
  end

  it ":pointcuts is a synonym for :pointcut" do
    @aspects << after(:noop, :pointcuts => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
  
  it "should accept :within_pointcuts as a synonym for :pointcut." do
    @aspects << after(:noop, :within_pointcuts => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end

  it "should accept :within_pointcut as a synonym for :pointcut." do
    @aspects << after(:noop, :within_pointcut => {:objects => @watchful, :methods => :public_watchful_method}, &@advice)
    @aspects[1].should == @aspects[0]
  end
end

describe Object, "#advise (or synonyms) called within a type body" do
  it "will not advise a method whose definition hasn't been seen yet in the type body." do
    class WatchfulWithMethodAlreadyDefined
      @@advice_called = 0
      def public_watchful_method *args; end
      before :public_watchful_method do |jp, *args|
        @@advice_called += 1
      end
      def self.advice_called; @@advice_called; end
    end
    WatchfulWithMethodAlreadyDefined.new.public_watchful_method :a1, :a2
    WatchfulWithMethodAlreadyDefined.new.public_watchful_method :a3, :a4
    WatchfulWithMethodAlreadyDefined.advice_called.should == 2
    class WatchfulWithMethodNotYetDefined
      @@advice_called = 0
      before(:public_watchful_method) {|jp, *args| @@advice_called += 1}
      def public_watchful_method *args; end
      def self.advice_called; @@advice_called; end
    end
    WatchfulWithMethodNotYetDefined.new.public_watchful_method :a1, :a2
    WatchfulWithMethodNotYetDefined.new.public_watchful_method :a3, :a4
    WatchfulWithMethodNotYetDefined.advice_called.should == 0
  end
end

describe Object, "#pointcut" do
  class PC1; 
    def doit; end
  end
  
  it "should match equivalent join points as Pointcut.new" do
    pointcut1 = pointcut :type => PC1, :method => :doit
    pointcut2 = Aquarium::Aspects::Pointcut.new :type => PC1, :method => :doit
    pointcut1.join_points_matched.should     == pointcut2.join_points_matched
    pointcut1.join_points_not_matched.should == pointcut2.join_points_not_matched
  end
  
  it "should use self as the object if no object or type is specified." do
    class PC1
      POINTCUT = pointcut :method => :doit
    end
    pointcut2 = Aquarium::Aspects::Pointcut.new :type => PC1, :method => :doit
    PC1::POINTCUT.join_points_matched.should     == pointcut2.join_points_matched
    PC1::POINTCUT.join_points_not_matched.should == pointcut2.join_points_not_matched
  end
end