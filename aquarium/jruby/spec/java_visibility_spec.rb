require File.dirname(__FILE__) + '/spec_helper'

include Aquarium::Aspects

# The Aquarium README summarizes the known bugs and limitations of the JRuby integration.

class VisibilityWrapper < Java::example.visibility.Visibility
  def public_method(s, i); super; end
  protected
  def protected_method(s, i); super; end
  private
  def private_method(s, i); super; end
end
 
describe "Matching on a private method in a Java type" do  
  before :each do
    @visibility = Java::example.visibility.Visibility.new
  end

  it "will not match on a private Java method when the default public access method option is used" do
    aspect = Aspect.new :around, :calls_to => "private_method", :in_object => @visibility, 
      :ignore_no_matching_join_points => true do |jp|
    end
    aspect.join_points_matched.to be_empty
    aspect.unadvise
  end

  it "will not match on a private Java method, even when the private method option specifier is used" do
    aspect = Aspect.new :around, :calls_to => "private_method", :in_object => @visibility, 
      :method_options => [:private], :ignore_no_matching_join_points => true do |jp|
    end
    aspect.join_points_matched.to be_empty
    aspect.unadvise
  end
end

describe "Matching on a protected method in a Java type" do  
  before :each do
    @visibility = Java::example.visibility.Visibility.new
  end

  it "will treat a protected Java method as publicly visible" do
    aspect = Aspect.new :around, :calls_to => "protected_method", :in_object => @visibility, 
      :ignore_no_matching_join_points => false do |jp|
    end
    aspect.join_points_matched.size.to eql(1)
    aspect.join_points_matched.each {|jp| jp.method_name.to eql(:protected_method) }
    aspect.unadvise
  end

  it "will NOT match on a protected Java method, even when the :protected method option specifier is used" do
    aspect = Aspect.new :around, :calls_to => "protected_method", :in_object => @visibility, 
      :method_options => [:protected], :ignore_no_matching_join_points => true do |jp|
    end
    aspect.join_points_matched.to be_empty
    aspect.unadvise
  end

end

describe "Matching on a public method in a Java type" do  
  before :each do
    @visibility = Java::example.visibility.Visibility.new
  end

  it "should match on a public method when the default public access is used" do
    aspect = Aspect.new :around, :calls_to => "public_method", :in_object => @visibility, 
      :ignore_no_matching_join_points => false do |jp|
    end
    aspect.join_points_matched.size.to eql(1)
    aspect.join_points_matched.each {|jp| jp.method_name.to eql(:public_method) }
    aspect.unadvise
  end

  it "should match on a public method when the public method option specifier is used" do
    aspect = Aspect.new :around, :calls_to => "public_method", :in_object => @visibility, 
      :method_options => [:public], :ignore_no_matching_join_points => false do |jp|
    end
    aspect.join_points_matched.size.to eql(1)
    aspect.join_points_matched.each {|jp| jp.method_name.to eql(:public_method) }
    aspect.unadvise
  end
end

%w[private protected public].each do |vis|
  if vis == "public"
    not_string = ""
    ignore_no_matches = false
	else
    not_string = "not "
    ignore_no_matches = true
  end

  describe "Matching on a #{vis} method in a Ruby type wrapping a Java type where the Ruby type is advised" do  
    before :each do
      @visibility = VisibilityWrapper.new
    end
  
    it "should #{not_string}advise #{vis} methods when the default public access is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
        :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      if vis == "public"
        aspect.join_points_matched.size.to eql(1)
        aspect.join_points_matched.each {|jp| jp.method_name.to eql("#{vis}_method".intern) }
      else
        aspect.join_points_matched.to be_empty
      end
      aspect.unadvise
    end

    it "should advise #{vis} methods when the same access method option specifier is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
      :method_options => [vis.intern], :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      aspect.join_points_matched.size.to eql(1)
      aspect.join_points_matched.each {|jp| jp.method_name.to eql("#{vis}_method".intern) }
      aspect.unadvise
    end
  end
end

