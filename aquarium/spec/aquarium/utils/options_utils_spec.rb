
require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils'

include Aquarium::Utils

module Aquarium
  class OptionsUtilsUser
    include OptionsUtils
    def initialize hash = {}
      init_specification hash, {}
    end
    def all_allowed_option_symbols
      []
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