
require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects'

include Aquarium::Aspects

# TODO Could refactor this whole file to use "behave_like", etc.
describe Aspect, "#new parameters that configure advice" do  
  it "should require the kind of advice as the first parameter." do
    lambda {Aspect.new(:pointcuts => {:type => Watchful, :methods => :public_watchful_method}) {|jp, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should at least one of :method(s), :pointcut(s), :type(s), or :object(s)." do
    lambda {Aspect.new(:after) {|jp, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should at least one of :pointcut(s), :type(s), or :object(s) unless :default_object => object is given." do
    aspect = Aspect.new(:after, :default_object => Watchful.new, :methods => :public_watchful_method) {|jp, *args| true}
    aspect.unadvise
  end

  it "should not contain :pointcut(s) and either :type(s) or :object(s)." do
    lambda {Aspect.new(:after, :pointcuts => {:type => Watchful, :methods => :public_watchful_method}, :type => Watchful, :methods => :public_watchful_method) {|jp, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda {Aspect.new(:after, :pointcuts => {:type => Watchful, :methods => :public_watchful_method}, :object => Watchful.new, :methods => :public_watchful_method) {|jp, *args| true}}.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should include an advice block or :advice => advice parameter." do
    lambda {Aspect.new(:after, :type => Watchful, :methods => :public_watchful_method)}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end
  
describe Aspect, "#new :pointcut parameter with a hash of :type(s), :object(s), and/or :method(s)" do  
  it "should accept a {:type(s) => [T1, ...], :methods = [...]} hash, indicating the types and methods to advise." do
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:type => [Watchful], :methods => :public_watchful_method} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a {:type(s) => T, :methods = [...]} hash, indicating the type and methods to advise." do
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  %w[public protected private].each do |protection|
    it "should accept a {:type(s) => T, :methods = [...], :method_options =>[:instance, #{protection}]} hash, indicating the type and #{protection} instance methods to advise." do
      advice_called = false
      aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => /watchful_method/, :method_options =>[:instance, protection.intern]} do |jp, *args|
        advice_called = true
        jp.should_not == nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      Watchful.new.method("#{protection}_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end
  end
  
  it "should accept a {:type(s) => T, :methods = [...], :method_options =>[:instance]} hash, indicating the type and (public) instance methods to advise." do
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  %w[public private].each do |protection|
    it "should accept a {:type(s) => T, :methods = [...], :method_options =>[:class, :#{protection}]} hash, indicating the type and #{protection} class methods to advise." do
      advice_called = false
      aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => /class_watchful_method$/, :method_options =>[:class, protection.intern]} do |jp, *args|
        advice_called = true
        jp.should_not == nil
        args.size.should == 4
        args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      end 
      Watchful.method("#{protection}_class_watchful_method".intern).call :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
      advice_called.should be_true
      aspect.unadvise
    end
  end
  
  it "should accept a {:type(s) => T, :methods = [...], :method_options =>:class} hash, indicating the type and (public) class methods to advise." do
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_class_watchful_method, :method_options =>:class} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a {:objects(s) => [O1, ...], :methods = [...]} hash, indicating the objects and methods to advise." do
    watchful1 = Watchful.new
    watchful2 = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:objects => [watchful1, watchful2], :methods => :public_watchful_method} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful1.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    watchful2.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a {:objects(s) => O, :methods = [...]} hash, indicating the objects and methods to advise." do
    watchful = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :pointcut => {:objects => watchful, :methods => :public_watchful_method} do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end  
end

describe Aspect, "#new :pointcut parameter with a PointCut object or an array of Pointcuts" do  
  it "should accept a single Pointcut object." do
    advice_called = false
    pointcut = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    aspect = Aspect.new :before, :pointcut => pointcut do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept an array of Pointcut objects." do
    advice_called = 0
    pointcut1 = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    pointcut2 = Pointcut.new :type => [Watchful], :methods => :public_class_watchful_method, :method_options => [:class]
    aspect = Aspect.new :before, :pointcut => [pointcut1, pointcut2] do |jp, *args|
      advice_called += 1
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should == 2
    aspect.unadvise
  end

  it "should treat an array of Pointcuts as if they are one Pointcut \"or'ed\" together." do
    advice_called = 0
    advice = Proc.new {|jp, *args|
      advice_called += 1
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    pointcut1 = Pointcut.new :type => [Watchful], :methods => :public_watchful_method
    pointcut2 = Pointcut.new :type => [Watchful], :methods => :public_class_watchful_method, :method_options => [:class]
    pointcut12 = pointcut1.or pointcut2
    aspect1 = Aspect.new :before, :pointcut => [pointcut1, pointcut2], :advice => advice
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should == 2
    aspect1.unadvise
    advice_called = 0
    aspect2 = Aspect.new :before, :pointcut => pointcut12, :advice => advice
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    Watchful.public_class_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should == 2
    aspect2.unadvise
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
  end
end

describe Aspect, "#new :type(s), :object(s), and :method(s) parameters" do  
  it "should accept :type(s) => [T1, ...] and :methods => [...] parameters indicating the types to advise." do
    advice_called = false
    aspect = Aspect.new :before, :types => [Watchful], :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :type(s) => T and :methods => [...] parameters indicating the types to advise." do
    advice_called = false
    aspect = Aspect.new :before, :type => Watchful, :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :type(s) => /regexp/ and :methods => [...] parameters indicating the types to advise." do
    advice_called = false
    aspect = Aspect.new :before, :type => /^Watchful/, :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    Watchful.new.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end
  
  it "should accept :object(s) => [O1, ...] and :methods => [...] parameters indicating the objects to advise." do
    watchful1 = Watchful.new
    watchful2 = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :object => [watchful1, watchful2], :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful1.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    watchful2.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :object(s) => O and :methods => [...] parameters indicating the objects to advise." do
    watchful = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept :object(s) => O and :methods => [...] parameters indicating the objects to advise." do
    watchful = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end
end

describe Aspect, "#new block parameter" do  
  it "should accept a block as the advice to use." do
    watchful = Watchful.new
    advice_called = false
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method do |jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    end 
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept an :advice => Proc parameter indicating the advice to use." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advice => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end
  
  it "should accept a :call => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :call => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a :invoke => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :invoke => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should accept a :advise_with => Proc parameter as a synonym for :advice." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advise_with => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should ignore all synonyms if there is an :advice => Proc parameter." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    advice2 = Proc.new {|jp, *args| raise "should not be called"}
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :invoke => advice2, :advice => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end

  it "should ignore all but the last :advice => Proc parameter." do
    watchful = Watchful.new
    advice_called = false
    advice = Proc.new {|jp, *args|
      advice_called = true
      jp.should_not == nil
      args.size.should == 4
      args.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    }
    advice2 = Proc.new {|jp, *args| raise "should not be called"}
    aspect = Aspect.new :before, :object => watchful, :methods => :public_watchful_method, :advice => advice2, :advice => advice
    watchful.public_watchful_method :a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2'
    advice_called.should be_true
    aspect.unadvise
  end
end

describe Aspect, "#new invoked for the private implementation methods inserted by other aspects" do  
  it "should have no affect." do
    class WithAspectLikeMethod
      def _aspect_foo; end
    end
    aspect = Aspect.new(:after, :pointcut => {:type => WithAspectLikeMethod, :methods => :_aspect_foo}) {|jp, *args| fail}
    WithAspectLikeMethod.new._aspect_foo
    aspect.unadvise
  end
end

describe Aspect, "#new modifications to the list of methods for the advised object or type" do  
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect.unadvise
  end
  
  it "should not include new public instance or class methods for the advised type." do
    all_public_methods_before = all_public_methods_of_type Watchful
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :method_options => :suppress_ancestor_methods}, :advice => @advice 
    (all_public_methods_of_type(Watchful) - all_public_methods_before).should == []
  end

  it "should not include new protected instance or class methods for the advised type." do
    all_protected_methods_before = all_protected_methods_of_type Watchful
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :method_options => :suppress_ancestor_methods}, :advice => @advice  
    (all_protected_methods_of_type(Watchful) - all_protected_methods_before).should == []
  end

  it "should not include new public methods for the advised object." do
    watchful = Watchful.new
    all_public_methods_before = all_public_methods_of_object Watchful
    @aspect = Aspect.new :after, :pointcut => {:object => watchful, :method_options => :suppress_ancestor_methods}, :advice => @advice  
    (all_public_methods_of_object(Watchful) - all_public_methods_before).should == []
  end

  it "should not include new protected methods for the advised object." do
    watchful = Watchful.new
    all_protected_methods_before = all_protected_methods_of_object Watchful
    @aspect = Aspect.new :after, :pointcut => {:object => watchful, :method_options => :suppress_ancestor_methods}, :advice => @advice  
    (all_protected_methods_of_object(Watchful) - all_protected_methods_before).should == []
  end
end

describe Aspect, "#new with :before advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :before
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.should == nil
  end

  it "should evaluate the advice before the method body and its block (if any)." do
    @aspect = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
end

describe Aspect, "#new with :after advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the return value when the method returns normally." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :after
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == block_called
    context.raised_exception.should == nil
  end

  it "should pass the context information to the advice, including self, the method parameters, and the rescued exception when an exception is raised." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == nil
    context.raised_exception.kind_of?(Watchful::WatchfulError).should be_true
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
  it "should ignore the value returned by the advice" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after, :type => ReturningValue, :method => :doit do |jp, *args|
      %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  it "should all the advice to assign a new return value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after, :type => ReturningValue, :method => :doit do |jp, *args|
      jp.context.returned_value = %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[aa a b c d e]
  end
end

describe Aspect, "#new with :after_returning advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the return value." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    context.advice_kind.should == :after_returning
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.returned_value.should == block_called
    context.raised_exception.should == nil
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private 
  end
  
  it "should ignore the value returned by the advice" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after_returning, :type => ReturningValue, :method => :doit do |jp, *args|
      %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  it "should all the advice to assign a new return value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :after_returning, :type => ReturningValue, :method => :doit do |jp, *args|
      jp.context.returned_value = %w[aa] + jp.context.returned_value + %w[e]
    end 
    ReturningValue.new.doit(ary).should == %w[aa a b c d e]
  end
end

describe Aspect, "#new with :after_raising advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self, the method parameters, and the rescued exception." do
    watchful = Watchful.new
    context = nil
    @aspect = Aspect.new :after_raising, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, *args|
      context = jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    context.advised_object.should == watchful
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.advice_kind.should == :after_raising
    context.returned_value.should == nil
    context.raised_exception.kind_of?(Watchful::WatchfulError).should be_true
  end

  it "should evaluate the advice after the method body and its block (if any)." do
    @aspect = Aspect.new :after_raising, :pointcut => {:type => Watchful, :methods => /public_watchful_method/} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private true
  end
  
  it "should not advise rescue clauses for raised exceptions of types that don't match the specified exception" do
    class MyError < StandardError; end
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => MyError, :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should not advise rescue clauses for raised exceptions of types that don't match the list of specified exceptions" do
    class MyError1 < StandardError; end
    class MyError2 < StandardError; end
    aspect_advice_invoked = false
    @aspect = Aspect.new(:after_raising => [MyError1, MyError2], :pointcut => {:type => Watchful, :methods => /public_watchful_method/}) {|jp, *args| aspect_advice_invoked = true}
    block_invoked = false
    watchful = Watchful.new
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3) {|*args| block_invoked = true}}.should raise_error(Watchful::WatchfulError)
    aspect_advice_invoked.should be_false
    block_invoked.should be_true
  end
  
  it "should advise all rescue clauses in the matched methods, if no specific exceptions are specified" do
    class ClassThatRaises
      class CTRException < Exception; end
      def raises
        raise CTRException
      end
    end
    aspect_advice_invoked = false
    @aspect = Aspect.new :after_raising, :pointcut => {:type => ClassThatRaises, :methods => :raises} do |jp, *args|
      aspect_advice_invoked = true
    end 
    aspect_advice_invoked.should be_false
    ctr = ClassThatRaises.new
    lambda {ctr.raises}.should raise_error(ClassThatRaises::CTRException)
    aspect_advice_invoked.should be_true
  end
end

describe Aspect, "#new with :before and :after advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the return value for the after-advice case." do
    contexts = []
    @aspect = Aspect.new :before, :after, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]} do |jp, *args|
      contexts << jp.context
    end 
    watchful = Watchful.new
    public_block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called += 1 }
    public_block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after
    contexts[0].returned_value.should == nil
    contexts[1].returned_value.should == 1
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.raised_exception.should == nil
    end

    %w[protected private].each do |protection|  
      block_called = 0
      watchful.send("#{protection}_watchful_method", :b1, :b2, :b3) {|*args| block_called += 1}
      block_called.should == 1
      contexts.size.should == 2
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private false, 2 
  end
end

describe Aspect, "#new with :before and :after_returning advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the return value for the after-advice case." do
    watchful = Watchful.new
    contexts = []
    @aspect = Aspect.new :before, :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      contexts << jp.context
    end 
    block_called = 0
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }
    block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after_returning
    contexts[0].returned_value.should == nil
    contexts[1].returned_value.should == block_called
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.raised_exception.should == nil
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after_returning, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private false, 2 
  end
end

describe Aspect, "#new with :before and :after_raising advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including self and the method parameters, plus the raised exception for the after-advice case." do
    watchful = Watchful.new
    contexts = []
    @aspect = Aspect.new :before, :after_raising, :pointcut => {:type => Watchful, :methods => :public_watchful_method_that_raises} do |jp, *args|
      contexts << jp.context
    end 
    block_called = 0
    lambda {watchful.public_watchful_method_that_raises(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| block_called += 1 }}.should raise_error(Watchful::WatchfulError)
    block_called.should == 1
    contexts.size.should == 2
    contexts[0].advice_kind.should == :before
    contexts[1].advice_kind.should == :after_raising
    contexts[0].raised_exception.should == nil
    contexts[1].raised_exception.kind_of?(Watchful::WatchfulError).should be_true
    contexts.each do |context|
      context.advised_object.should == watchful
      context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
      context.returned_value.should == nil
    end
  end

  it "should evaluate the advice before and after the method body and its block (if any)." do
    @aspect = Aspect.new :before, :after_raising, :pointcut => {:type => Watchful, :methods => :public_watchful_method_that_raises} do |jp, *args|
      @advice_called += 1
    end 
    do_watchful_public_protected_private true, 2 
  end
end

describe Aspect, "#new with :around advice" do
  after(:each) do
    @aspect.unadvise if @aspect
  end

  it "should pass the context information to the advice, including the object, advice kind, the method invocation parameters, etc." do
    contexts = []
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]} do |jp, *args|
      contexts << jp.context
    end 
    watchful = Watchful.new
    public_block_called = false
    protected_block_called = false
    private_block_called = false
    watchful.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called = true }
    watchful.send(:protected_watchful_method, :b1, :b2, :b3) {|*args| protected_block_called = true}
    watchful.send(:private_watchful_method, :c1, :c2, :c3) {|*args| private_block_called = true}
    public_block_called.should be_false  # proceed is never called!
    protected_block_called.should be_true
    private_block_called.should be_true
    contexts.size.should == 1
    contexts[0].advised_object.should == watchful
    contexts[0].advice_kind.should == :around
    contexts[0].returned_value.should == nil
    contexts[0].parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    contexts[0].raised_exception.should == nil
  end

  it "should advise subclass invocations of methods advised in the superclass." do
    context = nil
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]} do |jp, *args|
      context = jp.context
    end 
    child = WatchfulChild.new
    public_block_called = false
    protected_block_called = false
    private_block_called = false
    child.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| fail }
    child.send(:protected_watchful_method, :b1, :b2, :b3) {|*args| protected_block_called = true}
    child.send(:private_watchful_method, :c1, :c2, :c3) {|*args| private_block_called = true}
    public_block_called.should be_false  # proceed is never called!
    protected_block_called.should be_true
    private_block_called.should be_true
    context.advised_object.should == child
    context.advice_kind.should == :around
    context.returned_value.should == nil
    context.parameters.should == [:a1, :a2, :a3, {:h1 => 'h1', :h2 => 'h2'}]
    context.raised_exception.should == nil
  end

  it "should not advise subclass overrides of superclass methods, when advising superclasses (but calls to superclass methods are advised)." do
    class WatchfulChild2 < Watchful
      def public_watchful_method *args
        @override_called = true
        yield(*args) if block_given?
      end
      attr_reader :override_called
      def initialize
        super
        @override_called = false
      end
    end
    @aspect = Aspect.new(:around, :pointcut => {:type => Watchful, :methods => [:public_watchful_method]}) {|jp, *args| fail}
    child = WatchfulChild2.new
    public_block_called = false
    child.public_watchful_method(:a1, :a2, :a3, :h1 => 'h1', :h2 => 'h2') { |*args| public_block_called = true }
    public_block_called.should be_true  # advice never called
  end

  it "should evaluate the advice and only evaluate the method body and its block (if any) when JoinPoint#proceed is called." do
    do_around_spec
  end
  
  it "should pass the block that was passed to the method by default if the block is not specified explicitly in the around advice in the call to JoinPoint#proceed." do
    do_around_spec
  end
  
  it "should pass the parameters and block that were passed to the method by default if JoinPoint#proceed is invoked without parameters and a block." do
    do_around_spec
  end
  
  it "should pass parameters passed explicitly to JoinPoint#proceed, rather than the original method parameters, but also pass the original block if a new block is not specified." do
    do_around_spec :a4, :a5, :a6
  end
  
  it "should pass parameters and a block passed explicitly to JoinPoint#proceed, rather than the original method parameters and block." do
    override_block_called = false
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      jp.proceed(:a4, :a5, :a6) {|*args| override_block_called = true}
    end 
    watchful = Watchful.new
    orig_block_called = false
    watchful.public_watchful_method(:a1, :a2, :a3) {|*args| orig_block_called = true}
    override_block_called.should be_true
    orig_block_called.should be_false
    watchful.public_watchful_method_args.should == [:a4, :a5, :a6]
  end
  
  it "should return the value returned by the advice, NOT the value returned by the advised join point!" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :around, :type => ReturningValue, :method => :doit do |jp, *args|
      jp.proceed
      %w[aa bb cc]
    end 
    ReturningValue.new.doit(ary).should == %w[aa bb cc]
  end

  it "should return the value returned by the advised join point only if the advice returns the value" do
    class ReturningValue
      def doit args
        args + ["d"]
      end
    end
    ary = %w[a b c]
    ReturningValue.new.doit(ary).should == %w[a b c d]
    @aspect = Aspect.new :around, :type => ReturningValue, :method => :doit do |jp, *args|
      begin
        jp.proceed
      ensure
        %w[aa bb cc]
      end
    end 
    ReturningValue.new.doit(ary).should == %w[a b c d]
  end

  def do_around_spec *args_passed_to_proceed
    @aspect = Aspect.new :around, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do |jp, *args|
      @advice_called += 1
      returned_value = args_passed_to_proceed.empty? ? jp.proceed : jp.proceed(*args_passed_to_proceed) 
      @advice_called += 1
      returned_value
    end 
    do_watchful_public_protected_private false, 2, (args_passed_to_proceed.empty? ? nil : args_passed_to_proceed)
  end
end



describe Aspect, "#unadvise" do
  before(:all) do
    @advice = Proc.new {}
  end
  it "should do nothing for unadvised types." do
    expected_methods = Watchful.private_methods.sort
    aspect = Aspect.new :around, :type => Watchful, :method => /does_not_exist/, :advice => @advice
    (Watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (Watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (Watchful.private_methods.sort - expected_methods).should == []
  end
    
  it "should do nothing for unadvised objects." do
    watchful = Watchful.new
    expected_methods = Watchful.private_methods.sort
    aspect = Aspect.new :around, :type => Watchful, :method => /does_not_exist/, :advice => @advice
    (Watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (Watchful.private_methods.sort - expected_methods).should == []
    aspect.unadvise
    (Watchful.private_methods.sort - expected_methods).should == []
  end
    
  it "should remove all advice added by the aspect." do
    advice_called = false
    aspect = Aspect.new(:after, :pointcut => {:type => Watchful, :method_options => :suppress_ancestor_methods}) {|jp, *args| advice_called = true}
    aspect.unadvise
    watchful = Watchful.new

    %w[public protected private].each do |protection|
      advice_called = false
      block_called = false
      watchful.send("#{protection}_watchful_method".intern, :a1, :a2, :a3) {|*args| block_called = true}
      advice_called.should be_false
      block_called.should be_true
    end
  end
  
  it "should remove all advice overhead if all advices are removed." do
    class Foo
      def bar; end
    end
    before = Foo.private_instance_methods.sort
    aspect = Aspect.new(:after, :pointcut => {:type => Foo, :method_options => :suppress_ancestor_methods}) {|jp, *args| true}
    after  = Foo.private_instance_methods
    (after - before).should_not == []
    aspect.unadvise
    after  = Foo.private_instance_methods
    (after - before).should == []
  end
end

describe "invariant protection level of methods under advising and unadvising", :shared => true do
  it "should keep the protection level of an advised methods unchanged." do
    %w[public protected private].each do |protection|
      meta   = "#{protection}_instance_methods"
      method = "#{protection}_watchful_method"
      Watchful.send(meta).should include(method)
      aspect = Aspect.new(:after, :type => Watchful, :method => method.intern) {|jp, *args| true }
      Watchful.send(meta).should include(method)
      aspect.unadvise
      Watchful.send(meta).should include(method)
    end
  end  
end

describe Aspect, "Advising methods should keep the protection level of an advised methods unchanged." do
  it_should_behave_like("invariant protection level of methods under advising and unadvising")
end
describe Aspect, "Unadvising methods should restore the original protection level of the methods." do
  it_should_behave_like("invariant protection level of methods under advising and unadvising")
end

describe Aspect, "#eql?" do
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect1.unadvise
    @aspect2.unadvise
  end
  
  it "should return true if both aspects have the same specification and pointcuts." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice 
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice 
    @aspect1.should eql(@aspect2)
  end

  it "should return true if both aspects have the same specification and pointcuts, even if the advice procs are not equal." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do true end
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method} do false end
    @aspect1.should eql(@aspect2)
  end

  it "should return false if each aspect advises pointcuts in different objects, even if the the objects are equivalent." do
    @aspect1 = Aspect.new :before, :pointcut => {:object => Watchful.new, :methods => :public_watchful_method} do true end
    @aspect2 = Aspect.new :before, :pointcut => {:object => Watchful.new, :methods => :public_watchful_method} do false end
    @aspect1.should_not eql(@aspect2)
  end
end

describe Aspect, "#==" do
  before(:all) do
    @advice = Proc.new {}
  end
  after(:each) do
    @aspect1.unadvise
    @aspect2.unadvise
  end
  
  it "should be equivalent to #eql?." do
    @aspect1 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice
    @aspect2 = Aspect.new :before, :pointcut => {:type => Watchful, :methods => :public_watchful_method}, :advice => @advice
    @aspect1.specification.should == @aspect2.specification
    @aspect1.pointcuts.should == @aspect2.pointcuts
    @aspect1.should eql(@aspect2)
    @aspect1.should == @aspect2
  end
end

describe Aspect, "#advice_chain_inspect" do
  it "should return the string '[nil]' if passed a nil advice chain" do
    Aspect.advice_chain_inspect(nil).should == "[nil]"
    chain = NoAdviceChainNode.new({:aspect => nil}) 
    Aspect.advice_chain_inspect(chain).should include("NoAdviceChainNode")
  end
end

def all_public_methods_of_type type
  (type.public_methods + type.public_instance_methods).sort
end
def all_protected_methods_of_type type
  (type.protected_methods + type.protected_instance_methods).sort
end
def all_public_methods_of_object object
  object.public_methods.sort
end
def all_protected_methods_of_object object
  object.protected_methods.sort
end

def do_watchful_public_protected_private raises = false, expected_advice_called_value = 1, args_passed_to_proceed = nil
  %w[public protected private].each do |protection|
    do_watchful_spec protection, raises, expected_advice_called_value, args_passed_to_proceed
  end
end

def do_watchful_spec protection, raises, expected_advice_called_value, args_passed_to_proceed
  suffix = raises ? "_that_raises" : ""
  expected_advice_called = protection == "public" ? expected_advice_called_value : 0
  watchful = Watchful.new
  @advice_called = 0
  block_called = 0
  if raises
    lambda {watchful.send("#{protection}_watchful_method#{suffix}".intern, :a1, :a2, :a3) {|*args| block_called += 1}}.should raise_error(Watchful::WatchfulError)
  else
    watchful.send("#{protection}_watchful_method#{suffix}".intern, :a1, :a2, :a3) {|*args| block_called += 1}
  end
  @advice_called.should == expected_advice_called
  block_called.should == 1
  expected_args = (protection == "public" && !args_passed_to_proceed.nil?) ? args_passed_to_proceed : [:a1, :a2, :a3]
  watchful.instance_variable_get("@#{protection}_watchful_method#{suffix}_args".intern).should == expected_args
end