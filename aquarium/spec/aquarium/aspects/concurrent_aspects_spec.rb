# Specifically tests behavior when two or more advices apply to the same join point(s).

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require File.dirname(__FILE__) + '/concurrently_accessed'
require 'aquarium/aspects'

include Aquarium::Aspects

module ConcurrentAspectsSpecSupport
  def add_m_then_remove_n_aspects_and_run iteration, for_type
    reset_attrs
    add_all_aspects_then_unadvise iteration, for_type
    invoke
    check_results_for iteration
    unadvise_remaining iteration
  end

  def reset_attrs
    @contexts = []
    @argss = []
    @aspects = []
    @advice_invocation_counts = []
    @accessed = nil
  end
  
  def add_all_aspects_then_unadvise number_to_unadvise, for_type
    @accessed = ConcurrentlyAccessed.new
    @advice_kinds.size.times do |n|
      make_aspect_for_index n, for_type
    end
    number_to_unadvise.times {|n| @aspects[n].unadvise}
  end

  def invoke accessed = @accessed, advice_kinds = @advice_kinds
    advice_kinds.size.times do |n|
      (advice_kinds[n] == :after_raising) ? do_invoke_raises(accessed) : do_invoke(accessed)
    end
  end
    
  def do_invoke_raises accessed
    lambda {accessed.invoke_raises :a1, :a2}.should raise_error(ConcurrentlyAccessed::Error)
  end

  def do_invoke accessed
    accessed.invoke :a1, :a2
  end

  def check_results_for iteration
    @accessed.invoked_count.should == @aspects.size 
    @accessed.invoked_args.should == [:a1, :a2]
    iteration.times do |n| 
      @advice_invocation_counts[n].should == 0
      @contexts[n].should be_nil
      @argss[n].should be_nil
    end
    (@aspects.size - iteration).times do |n| 
      n2 = n + iteration 
      @advice_invocation_counts[n2].should == expected_number_of_advice_invocations(@advice_kinds, n2)
      @contexts[n2].should_not be_nil
      @argss[n2].should == [:a1, :a2]
    end
  end

  def unadvise_remaining number_to_unadvise
    (@aspects.size - number_to_unadvise).times {|n| @aspects[n + number_to_unadvise].unadvise}
  end

  def make_aspect_for_index n, for_type
    method = @advice_kinds[n] == :after_raising ? :invoke_raises : :invoke
    @advice_invocation_counts[n] = 0
    if for_type 
      pointcut = Pointcut.new(:methods => method, :type => ConcurrentlyAccessed)
    else
      pointcut = Pointcut.new(:methods => method, :object => @accessed)
    end
    @aspects[n] = Aspect.new @advice_kinds[n], :pointcut => pointcut do |jp, obj, *args|
      @contexts[n] = jp.context
      @argss[n]    = *args
      @advice_invocation_counts[n] += 1
      jp.proceed if @advice_kinds[n] == :around
    end
  end
  
  # Because after_raising advice is invoked by calling ConcurrentlyAccessed#invoke_raises
  # instead of ConcurrentlyAccessed#invoke, we get a lower count, due to non-overlapping JPs.
  def expected_number_of_advice_invocations advice_kinds, n
    advice_kinds.size - after_raising_factor(advice_kinds, n)
  end

  def after_raising_factor advice_kinds, n
   raising, not_raising = advice_kinds.partition {|x| x == :after_raising}
   total = advice_kinds.size
   total - ((advice_kinds[n] == :after_raising) ? raising.size : not_raising.size)
  end
end

describe "concurrent advice", :shared => true do
  include ConcurrentAspectsSpecSupport
  
  before :all do
    @advice_kinds = []
  end
  
  it "should allow concurrent advice on the same join point, where type-based advices can be added and removed independently" do 
    (@advice_kinds.size+1).times do |n|
      add_m_then_remove_n_aspects_and_run n, true
    end
  end
  
  it "should allow concurrent advice on the same join point, where object-based advices can be added and removed independently" do 
    (@advice_kinds.size+1).times do |n|
      add_m_then_remove_n_aspects_and_run n, false
    end  
  end
end

describe "Using two :before advices" do
  setup do
    @advice_kinds = [:before, :before]
  end
  it_should_behave_like "concurrent advice"
end
  
describe "Using two :after advices" do
  setup do
    @advice_kinds = [:after, :after]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_returning advices" do
  setup do
    @advice_kinds = [:after_returning, :after_returning]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_raising advices" do
  setup do
    @advice_kinds = [:after_raising, :after_raising]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :around advices" do
  setup do
    @advice_kinds = [:around, :around]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :before advice and :after advice" do
  setup do
    @advice_kinds = [:before, :after]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :before advice and :after_returning advice" do
  setup do
    @advice_kinds = [:before, :after_returning]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :before advice and :after_raising advice" do
  setup do
    @advice_kinds = [:before, :after_raising]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :before advice and :around advice" do
  setup do
    @advice_kinds = [:before, :around]
  end
  it_should_behave_like "concurrent advice"
end
  
describe "Using :after advice and :after_returning advice" do
  setup do
    @advice_kinds = [:after, :after_returning]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :after advice and :after_raising advice" do
  setup do
    @advice_kinds = [:after, :after_raising]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :after advice and :around advice" do
  setup do
    @advice_kinds = [:after, :around]
  end
  it_should_behave_like "concurrent advice"
end


describe "Using :after_returning advice and :after_raising advice" do
  setup do
    @advice_kinds = [:after_returning, :after_raising]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :after_returning advice and :around advice" do
  setup do
    @advice_kinds = [:after_returning, :around]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using :after_raising advice and :around advice" do
  setup do
    @advice_kinds = [:after_raising, :around]
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :before advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :before}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :before advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :before}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :after advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :after}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :after_returning advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :after_returning}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :after_raising advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :after_raising}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using three :around advices" do
  setup do
    3.times {|i| @advice_kinds[i] = :around}
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :before advices and one :after advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :before}
    @advice_kinds[2] = :after
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :before advices and one :after_returning advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :before}
    @advice_kinds[2] = :after_returning
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :before advices and one :after_raising advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :before}
    @advice_kinds[2] = :after_raising
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :before advices and one :around advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :before}
    @advice_kinds[2] = :around
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after advices and one :before advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after}
    @advice_kinds[2] = :before
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after advices and one :after_returning advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after}
    @advice_kinds[2] = :after_returning
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after advices and one :after_raising advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after}
    @advice_kinds[2] = :after_raising
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after advices and one :around advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after}
    @advice_kinds[2] = :around
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_returning advices and one :before advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_returning}
    @advice_kinds[2] = :before
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_returning advices and one :after advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_returning}
    @advice_kinds[2] = :after
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_returning advices and one :after_raising advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_returning}
    @advice_kinds[2] = :after_raising
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_returning advices and one :around advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_returning}
    @advice_kinds[2] = :around
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_raising advices and one :before advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_raising}
    @advice_kinds[2] = :before
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_raising advices and one :after advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_raising}
    @advice_kinds[2] = :after
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_raising advices and one :after_raising advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_raising}
    @advice_kinds[2] = :after_raising
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :after_raising advices and one :around advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :after_raising}
    @advice_kinds[2] = :around
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :around advices and one :before advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :around}
    @advice_kinds[2] = :before
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :around advices and one :after advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :around}
    @advice_kinds[2] = :after
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :around advices and one :after_returning advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :around}
    @advice_kinds[2] = :after_returning
  end
  it_should_behave_like "concurrent advice"
end

describe "Using two :around advices and one :after_raising advice" do
  setup do
    2.times {|i| @advice_kinds[i] = :around}
    @advice_kinds[2] = :after_raising
  end
  it_should_behave_like "concurrent advice"
end
