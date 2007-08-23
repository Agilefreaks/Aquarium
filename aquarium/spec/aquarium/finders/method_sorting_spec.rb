require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "Method Extension" do
  it "should compare methods by type and name." do
    actual = %w[send nil? clone gsub! ].map {|m| Kernel.method(m)} 
    actual << Module.method(:nesting)
    sorted = actual.sort_by {|method| method.to_s}
    sorted.should == [
      Kernel.method(:gsub!),
      Kernel.method(:clone),
      Kernel.method(:nil?),
      Kernel.method(:send),
      Module.method(:nesting)
    ]
  end
end
