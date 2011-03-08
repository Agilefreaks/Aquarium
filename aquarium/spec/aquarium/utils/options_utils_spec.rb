
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
    object.noop.should be_false
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
    object.noop.should be_false
  end

  it "should return the value specified with :noop." do
    object = Aquarium::OptionsUtilsUser.new :noop => true
    object.noop.should be_true
  end
end

describe OptionsUtils, "#noop=" do
  it "should set the noop value." do
    object = Aquarium::OptionsUtilsUser.new :noop => true
    object.noop = false
    object.noop.should be_false
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

describe OptionsUtils, ".canonical_option_accessor" do
  it "should create a reader and writer method for each option" do
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:foos)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:bars)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:foos=)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:bars=)
  end
  it "should accept individual options" do
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:foos)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:bars)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:foos=)
    Aquarium::OptionsUtilsExampleWithAccessors.instance_methods.should include(:bars=)
  end
  it "should accept the CANONICAL_OPTIONS as an argument" do
    Aquarium::OptionsUtilsExampleWithCanonicalOptionsAccessors.instance_methods.should include(:foos)
    Aquarium::OptionsUtilsExampleWithCanonicalOptionsAccessors.instance_methods.should include(:bars)
    Aquarium::OptionsUtilsExampleWithCanonicalOptionsAccessors.instance_methods.should include(:foos=)
    Aquarium::OptionsUtilsExampleWithCanonicalOptionsAccessors.instance_methods.should include(:bars=)
  end
end
describe OptionsUtils, ".canonical_option_reader" do
  it "creates a reader method for each option" do
    Aquarium::OptionsUtilsExampleWithReaders.instance_methods.should include(:foos)
    Aquarium::OptionsUtilsExampleWithReaders.instance_methods.should include(:bars)
    Aquarium::OptionsUtilsExampleWithReaders.instance_methods.should_not include("foos=")
    Aquarium::OptionsUtilsExampleWithReaders.instance_methods.should_not include("bars=")
  end
  it "should create readers that return set values" do
    object = Aquarium::OptionsUtilsExampleWithReaders.new
    object.foos.class.should == Set
  end
end
describe OptionsUtils, ".canonical_option_writer" do
  it "creates a writer method for each option" do
    Aquarium::OptionsUtilsExampleWithWriters.instance_methods.should_not include("foos")
    Aquarium::OptionsUtilsExampleWithWriters.instance_methods.should_not include(:bars)
    Aquarium::OptionsUtilsExampleWithWriters.instance_methods.should include(:foos=)
    Aquarium::OptionsUtilsExampleWithWriters.instance_methods.should include(:bars=)
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
    lambda {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :unknown => true}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should not raise if a known canonical option is specified" do
    lambda {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :foos => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should not raise if a known canonical option synonym is specified" do
    lambda {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :foo1 => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should not raise if an known additional allowed option is specified" do
    lambda {Aquarium::OptionsUtilsExampleWithAdditionalAllowedOptions.new :baz => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
end
