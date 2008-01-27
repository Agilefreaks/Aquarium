require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils/default_logger'
require 'logger'

include Aquarium::Utils

describe DefaultLogger, ".logger=" do
  before :each do
    @saved_logger = DefaultLogger.logger
  end
  after :each do
    DefaultLogger.logger= @saved_logger   # restore the original!
  end
  
  it "should set the global logger." do
    test_logger = Logger.new STDOUT
    DefaultLogger.logger = test_logger
    DefaultLogger.logger.should be_eql(test_logger)
  end
end

describe DefaultLogger, ".logger" do
  it "should get the global logger." do
    test_logger = Logger.new STDOUT
    DefaultLogger.logger = test_logger
    DefaultLogger.logger.should be_eql(test_logger)
  end
end
