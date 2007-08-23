require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/utils/array_utils'
require 'set'

describe Aquarium::Utils::HtmlEscaper, ".escape" do
  it "should replace < with &lt; and > with &gt;" do
    Aquarium::Utils::HtmlEscaper.escape("<html></html>").should == "&lt;html&gt;&lt;/html&gt;"
  end
end

describe Aquarium::Utils::HtmlEscaper, "#escape" do
  it "should replace < with &lt; and > with &gt;" do
    class Escaper
      include Aquarium::Utils::HtmlEscaper
    end
    Escaper.new.escape("<html></html>").should == "&lt;html&gt;&lt;/html&gt;"
  end
end
