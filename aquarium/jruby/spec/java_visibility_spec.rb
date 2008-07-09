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
 
%w[public protected private].each do |vis|
  if vis == "public"
    not_string = ""
    ignore_no_matches = false
	else
    not_string = "not "
    ignore_no_matches = true
  end
  
  describe "Advice on a #{vis} method in a Java type" do  
    before :each do
      @visibility = Java::example.visibility.Visibility.new
    end
  
    it "should #{not_string} advise #{vis} methods when the default public access is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
        :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      if vis == "public"
        aspect.join_points_matched.size.should eql(1)
        aspect.join_points_matched.each {|jp| jp.method_name.should eql("#{vis}_method".intern) }
      else
        aspect.join_points_matched.should be_empty
      end
      aspect.unadvise
    end

    it "should #{not_string} advise #{vis} methods, even when the same access method option specifier is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
        :method_options => [vis.intern], :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      if vis == "public"
        aspect.join_points_matched.size.should eql(1)
        aspect.join_points_matched.each {|jp| jp.method_name.should eql("#{vis}_method".intern) }
      else
        aspect.join_points_matched.should be_empty
      end
      aspect.unadvise
    end
  end

  describe "Advice on a #{vis} method in a Ruby type wrapping a Java type where the Ruby type is advised" do  
    before :each do
      @visibility = VisibilityWrapper.new
    end
  
    it "should #{not_string} advise #{vis} methods when the default public access is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
        :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      if vis == "public"
        aspect.join_points_matched.size.should eql(1)
        aspect.join_points_matched.each {|jp| jp.method_name.should eql("#{vis}_method".intern) }
      else
        aspect.join_points_matched.should be_empty
      end
      aspect.unadvise
    end

    it "should advise #{vis} methods when the same access method option specifier is used" do
      aspect = Aspect.new :around, :calls_to => "#{vis}_method", :in_object => @visibility, 
      :method_options => [vis.intern], :ignore_no_matching_join_points => ignore_no_matches do |jp|
      end
      aspect.join_points_matched.size.should eql(1)
      aspect.join_points_matched.each {|jp| jp.method_name.should eql("#{vis}_method".intern) }
      aspect.unadvise
    end
  end
end

