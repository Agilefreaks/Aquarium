
require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils'
require 'stringio'

include Aquarium::Utils

module Aquarium
  class OptionsUtilsUser
    include OptionsUtils
    def initialize hash = {}
      init_specification hash, {}, []
    end
  end
end
  
describe OptionsUtils, "with no 'universal' options specified" do
  it "should use the default logger." do
    object = Aquarium::OptionsUtilsUser.new
    object.logger.should == DefaultLogger.logger
  end

  it "should set noop to false." do
    object = Aquarium::OptionsUtilsUser.new
    object.noop.should be_falsey
  end
end

describe OptionsUtils, ":logger option" do
  it "should set the object's logger to the specified logger." do
    logger = Logger.new STDOUT
    object = Aquarium::OptionsUtilsUser.new :logger => logger
    object.logger.should == logger    
  end
end

describe OptionsUtils, ":severity option" do
  it "should set the level on the object's logger to the :severity value." do
    logger = Logger.new STDOUT
    object = Aquarium::OptionsUtilsUser.new :logger => logger, :severity => Logger::Severity::WARN
    object.logger.level.should == Logger::Severity::WARN    
  end
  
  it "should cause the creation of a unique logger if one was not specified." do
    object = Aquarium::OptionsUtilsUser.new :severity => Logger::Severity::WARN
    object.logger.should_not eql(DefaultLogger.logger)
  end
end

describe OptionsUtils, ":logger_stream option" do
  it "should set the output stream on the object's logger to the :logger_stream value." do
    stringio = StringIO.new
    object = Aquarium::OptionsUtilsUser.new :logger_stream => stringio
    object.logger << "message"
    stringio.string.should eql("message")
  end
  
  it "should cause the creation of a unique logger if one was not specified." do
    stringio = StringIO.new
    object = Aquarium::OptionsUtilsUser.new :logger_stream => stringio
    object.logger.should_not eql(DefaultLogger.logger)
  end
end

describe OptionsUtils, ":logger_stream option" do
  it "should set the output stream on the object's logger to the :logger_stream value." do
    logger = Logger.new STDOUT
    object = Aquarium::OptionsUtilsUser.new :logger => logger, :severity => Logger::Severity::WARN
    object.logger.level.should == Logger::Severity::WARN    
  end
  
  it "should cause the creation of a unique logger if one was not specified." do
    object = Aquarium::OptionsUtilsUser.new :severity => Logger::Severity::WARN
    object.logger.should_not eql(DefaultLogger.logger)
  end
end

describe OptionsUtils, "#logger" do
  it "should return the logger specified with the :logger => ... option." do
    logger = Logger.new STDOUT
    object = Aquarium::OptionsUtilsUser.new :logger => logger
    object.logger.should == logger    
  end

  it "should return the default logger if no :logger => ... option was specified." do
    logger = Logger.new STDOUT
    object = Aquarium::OptionsUtilsUser.new 
    object.logger.should == DefaultLogger.logger
  end
end

describe OptionsUtils, "#logger=" do
  it "should set a new logger." do
    logger1 = Logger.new STDOUT
    logger2 = Logger.new STDERR
    object = Aquarium::OptionsUtilsUser.new :logger => logger1
    object.logger = logger2
    object.logger.should == logger2    
  end
end

describe OptionsUtils, "#noop" do
  it "should return false if :noop was not specified." do
    object = Aquarium::OptionsUtilsUser.new 
    object.noop.should be_falsey
  end

  it "should return the value specified with :noop." do
    object = Aquarium::OptionsUtilsUser.new :noop => true
    object.noop.should be_truthy
  end
end

describe OptionsUtils, "#noop=" do
  it "should set the noop value." do
    object = Aquarium::OptionsUtilsUser.new :noop => true
    object.noop = false
    object.noop.should be_falsey
  end
end

module Aquarium
  class OptionsUtilsExample
    include OptionsUtils
    CANONICAL_OPTIONS = {
      "foos" => %w[foo foo1 foo2],
      "bars" => %w[bar bar1 bar2]
    }
    def initialize options = {}
      init_specification options, CANONICAL_OPTIONS
    end
  end
  
  class OptionsUtilsExampleWithCanonicalOptionsAccessors < OptionsUtilsExample
    canonical_option_accessor CANONICAL_OPTIONS
  end
  class OptionsUtilsExampleWithAccessors < OptionsUtilsExample
    canonical_option_accessor :foos, :bars
  end
  class OptionsUtilsExampleWithReaders < OptionsUtilsExample
    canonical_option_reader :foos, :bars
  end
  class OptionsUtilsExampleWithWriters < OptionsUtilsExample
    canonical_option_writer :foos, :bars
  end
  class OptionsUtilsExampleWithAdditionalAllowedOptions
    include OptionsUtils
    CANONICAL_OPTIONS = {
      "foos" => %w[foo foo1 foo2],
      "bars" => %w[bar bar1 bar2]
    }
    canonical_option_writer :foos, :bars
    def initialize options = {}
      init_specification options, CANONICAL_OPTIONS, [:baz, :bbb]
    end
  end
end

def method_checks which_type, has_methods, has_not_methods = []
  # Handle 1.8 vs. 1.9 difference; convert methods names uniformly to symbols
  methods = which_type.instance_methods.map {|m| m.intern}
  has_methods.each     {|m| methods.should include(m)}
  has_not_methods.each {|m| methods.should_not include(m)}
end

describe OptionsUtils, ".canonical_option_accessor" do
  
  it "should create a reader and writer method for each option" do
    method_checks Aquarium::OptionsUtilsExampleWithAccessors, [:foos, :bars, :foos=, :bars=]
  end
  it "should accept individual options" do
    method_checks Aquarium::OptionsUtilsExampleWithAccessors, [:foos, :bars, :foos=, :bars=]
  end
  it "should accept the CANONICAL_OPTIONS as an argument" do
    method_checks Aquarium::OptionsUtilsExampleWithCanonicalOptionsAccessors, [:foos, :bars, :foos=, :bars=]
  end
end

describe OptionsUtils, ".canonical_option_reader" do
  it "creates a reader method for each option" do
    method_checks Aquarium::OptionsUtilsExampleWithReaders, [:foos, :bars], [:foos=, :bars=]
  end
  it "should create readers that return set values" do
    object = Aquarium::OptionsUtilsExampleWithReaders.new
    object.foos.class.should == Set
  end
end

describe OptionsUtils, ".canonical_option_writer" do
  it "creates a writer method for each option" do
    method_checks Aquarium::OptionsUtilsExampleWithWriters, [:foos=, :bars=], [:foos, :bars]
  end
  it "should create writers that convert the input values to sets, if they aren't already sets" do
    object = Aquarium::OptionsUtilsExampleWithAccessors.new
    object.foos = "bar"
    object.foos.class.should == Set
  end
  it "should create writers that leave the input sets unchanged" do
    expected = Set.new([:b1, :b2])
    object = Aquarium::OptionsUtilsExampleWithAccessors.new
    object.foos = expected
    object.foos.should == expected
  end
end

describe OptionsUtils, "and options handling" do
  it "should raise if an unknown option is specified" do
    expect {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :unknown => true}.to raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should not raise if a known canonical option is specified" do
    expect {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :foos => true}.not_to raise_error
  end
  it "should not raise if a known canonical option synonym is specified" do
    expect {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :foo1 => true}.not_to raise_error
  end
  it "should not raise if an known additional allowed option is specified" do
    expect {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :baz => true}.not_to raise_error
  end
end
