require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/aspects/aspect'
require 'aquarium/aspects/dsl'

describe Object, "#advise with invalid invocation parameter list" do
  it "should contain at least one of :around, :before, :after, :after_returning, and :after_raising." do
    lambda { advise :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should contain no other advice types if :around advice specified." do
    lambda { advise :around, :before,          :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { advise :around, :after,           :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { advise :around, :after_returning, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { advise :around, :after_raising,   :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow only one of :after, :after_returning, or :after_raising advice to be specified." do
    lambda { advise :after, :after_returning, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { advise :after, :after_raising,   :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
    lambda { advise :after_returning, :after_raising, :pointcut => {:type => Watchful} }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Object, "#advise arguments can specify more than one advice types" do
  it "should allow :before to be specified with :after." do
    lambda { advise :before, :after, :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow :before to be specified with :after_returning." do
    lambda { advise :before, :after_returning, :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end

  it "should allow :before to be specified with :after_raising." do
    lambda { advise :before, :after_raising,   :pointcut => {:type => Watchful}, :noop => true }.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Object, "#advise arguments for specifying the types and methods" do
  it "should advise equivalent join points when :type => T and :method => m is used or :pointcut =>{:type => T, :method => m} is used." do
    advice = proc {|jp,*args| "advice"}
    aspect1 = advise :after, :type => Watchful, :method => :public_watchful_method, &advice
    aspect2 = advise :after, :pointcut => {:type => Watchful, :method => :public_watchful_method}, &advice
    # We don't use aspect1.should eql(aspect2) because the "specifications" are different.
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end

  it "should advise equivalent join points when :type => T and :method => m is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
    advice = proc {|jp,*args| "advice"}
    aspect1 = advise :after, :type => Watchful, :method => :public_watchful_method, &advice
    pointcut = Aquarium::Aspects::Pointcut.new :type => Watchful, :method => :public_watchful_method
    aspect2 = advise :after, :pointcut => pointcut, &advice
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end

  it "should advise equivalent join points when :pointcut =>{:type => T, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :type => T and :method => m." do
    advice = proc {|jp,*args| "advice"}
    aspect1 = advise :after, :pointcut => {:type => Watchful, :method => :public_watchful_method}, &advice
    pointcut = Aquarium::Aspects::Pointcut.new :type => Watchful, :method => :public_watchful_method
    aspect2 = advise :after, :pointcut => pointcut, &advice
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end
end

describe Object, "#advise arguments for specifying the objects and methods" do
  it "should advise equivalent join points when :object => o and :method => m is used or :pointcut =>{:object => o, :method => m} is used." do
    advice = proc {|jp,*args| "advice"}
    watchful = Watchful.new
    aspect1 = advise :after, :object => watchful, :method => :public_watchful_method, &advice
    aspect2 = advise :after, :pointcut => {:object => watchful, :method => :public_watchful_method}, &advice
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end

  it "should advise equivalent join points when :object => o and :method => m is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
    advice = proc {|jp,*args| "advice"}
    watchful = Watchful.new
    aspect1 = advise :after, :object => watchful, :method => :public_watchful_method, &advice
    pointcut = Aquarium::Aspects::Pointcut.new :object => watchful, :method => :public_watchful_method
    aspect2 = advise :after, :pointcut => pointcut, &advice
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end

  it "should advise equivalent join points when :pointcut =>{:object => o, :method => m} is used or :pointcut => pointcut is used, where pointcut matches :object => o and :method => m." do
    advice = proc {|jp,*args| "advice"}
    watchful = Watchful.new
    aspect1 = advise :after, :pointcut => {:object => watchful, :method => :public_watchful_method}, &advice
    pointcut = Aquarium::Aspects::Pointcut.new :object => watchful, :method => :public_watchful_method
    aspect2 = advise :after, :pointcut => pointcut, &advice
    aspect1.pointcuts.should           eql(aspect2.pointcuts)
    aspect1.join_points_matched.should eql(aspect2.join_points_matched)
    aspect1.advice.should              eql(aspect2.advice)
    aspect1.unadvise
  end
end

