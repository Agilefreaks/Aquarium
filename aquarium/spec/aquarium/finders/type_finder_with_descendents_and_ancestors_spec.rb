require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_classes'
require 'aquarium/finders/type_finder'

# TODO Mock out type_utils to speed it up!
  
def purge_actuals actuals
  # Remove extra stuff inserted by RSpec and Aquarium, possibly in other specs! (TODO undo those when finished...)
  actuals.matched_keys.reject do |t2| 
    t2.name.include?("Spec::") or t2.name =~ /Aquarium::(Utils|Extras|Examples|Aspects)/
  end
end

variant = ''
describe "#find with types, including descendents", :shared => true do
  it "should find the matching types and their descendent subclasses, even in different nested modules." do
    option = "#{variant}_and_descendents".intern
    Aquarium::Utils::TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find option => (t.name)
      actual_keys = purge_actuals actual
      actual_keys.sort{|x,y| x.name <=> y.name}.should == Aquarium::Utils::TypeUtils.sample_types_descendents[t].sort{|x,y| x.name <=> y.name}
      actual.not_matched_keys.should == []
    end
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with types, including descendents"
    end
  EOF
end

describe "#find with excluded types, including descendents", :shared => true do
  it "should find the matching types and their descendent subclasses, minus the excluded type hierarchies." do
    option = "#{variant}_and_descendents".intern
    exclude_option = "exclude_#{variant}_and_descendents".intern
    actual = Aquarium::Finders::TypeFinder.new.find option => ModuleForDescendents, exclude_option => D1ForDescendents
    actual_keys = purge_actuals actual
    expected = Aquarium::Utils::TypeUtils.sample_types_descendents[ModuleForDescendents].reject do |c|
      Aquarium::Utils::TypeUtils.sample_types_descendents[D1ForDescendents].include? c
    end
    actual.not_matched_keys.should == []
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :exclude_#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with excluded types, including descendents"
    end
  EOF
end


describe "#find with types, including ancestors", :shared => true do
  it "should find the matching types and their ancestors, even in different nested modules." do
    option = "#{variant}_and_ancestors".intern
    Aquarium::Utils::TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find option => (t.name)
      actual_keys = purge_actuals actual
      actual_keys.sort{|x,y| x.name <=> y.name}.should == Aquarium::Utils::TypeUtils.sample_types_ancestors[t].sort{|x,y| x.name <=> y.name}
      actual.not_matched_keys.should == []
    end
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :#{n}_and_ancestors used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with types, including ancestors"
    end
  EOF
end


describe "#find with excluded types, including ancestors", :shared => true do
  it "should find the matching types and their ancestors, minus the excluded types and ancestors." do
    option = "#{variant}_and_ancestors".intern
    exclude_option = "exclude_#{variant}_and_ancestors".intern
    actual = Aquarium::Finders::TypeFinder.new.find option => D1ForDescendents, exclude_option => ModuleForDescendents
    actual_keys = purge_actuals actual
    expected = Aquarium::Utils::TypeUtils.sample_types_ancestors[D1ForDescendents].reject do |c|
      Aquarium::Utils::TypeUtils.sample_types_ancestors[ModuleForDescendents].include? c
    end
    actual.not_matched_keys.should == []
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :exclude_#{n}_and_ancestors used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with excluded types, including ancestors"
    end
  EOF
end


describe "#find with types, including descendents and ancestors", :shared => true do
  it "should find the matching types, including their descendents and ancestors, even in different nested modules." do
    doption = "#{variant}_and_descendents".intern
    aoption = "#{variant}_and_ancestors".intern
    Aquarium::Utils::TypeUtils.sample_types.each do |t|
      actual = Aquarium::Finders::TypeFinder.new.find aoption => (t.name), doption => (t.name)
      actual_keys = purge_actuals actual
      expected = Aquarium::Utils::TypeUtils.sample_types_ancestors[t] + Aquarium::Utils::TypeUtils.sample_types_descendents[t]
      actual_keys.sort{|x,y| x.name <=> y.name}.should == expected.sort{|x,y| x.name <=> y.name}.uniq
      actual.not_matched_keys.should == []
    end
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :#{n}_and_ancestors and :#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with types, including descendents and ancestors"
    end
  EOF
end

describe "#find with excluded types, including descendents and ancestors", :shared => true do
  it "should find the matching types, their descendents and ancestors, minus the excluded types, descendents and ancestors." do
    doption = "#{variant}_and_descendents".intern
    aoption = "#{variant}_and_ancestors".intern
    exclude_doption = "exclude_#{variant}_and_descendents".intern
    exclude_aoption = "exclude_#{variant}_and_ancestors".intern
    actual = Aquarium::Finders::TypeFinder.new.find aoption => Aquarium::ForDescendents::NestedD1ForDescendents, 
      doption => Aquarium::ForDescendents::NestedD1ForDescendents, 
      exclude_aoption => Aquarium::ForDescendents::NestedD2ForDescendents, 
      exclude_doption => Aquarium::ForDescendents::NestedD2ForDescendents
    actual_keys = purge_actuals actual
    expected = Aquarium::Utils::TypeUtils.sample_types_ancestors[D1ForDescendents].reject do |c|
      Aquarium::Utils::TypeUtils.sample_types_ancestors[ModuleForDescendents].include? c
    end
    actual.not_matched_keys.should == []
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find with :exclude_#{n}_and_ancestors and :exclude_#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with excluded types, including descendents and ancestors"
    end
  EOF
end


describe "#find with regular expressions, including descendents and ancestors", :shared => true do
  it "should find the matching types, including their descendents and ancestors, even in different nested modules." do
    doption = "#{variant}_and_descendents".intern
    aoption = "#{variant}_and_ancestors".intern
    regexs = [/ForDescendents$/, /Aquarium::ForDescendents::.*ForDescendents/]
    actual = Aquarium::Finders::TypeFinder.new.find aoption => regexs, doption => regexs
    actual_keys = purge_actuals actual
    expected = Aquarium::Utils::TypeUtils.sample_types_descendents_and_ancestors.keys + [Kernel, Object]
    actual_keys.size.should == expected.size
    expected.each do |t|
      actual_keys.should include(t)
    end
    actual.not_matched_keys.should == []
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find regexps with :#{n}_and_ancestors and :#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with regular expressions, including descendents and ancestors"
    end
  EOF
end


describe "#find with excluded regular expressions, including descendents and ancestors", :shared => true do
  it "should find the matching types, their descendents and ancestors, minus the excluded types, descendents and ancestors." do
    doption = "#{variant}_and_descendents".intern
    aoption = "#{variant}_and_ancestors".intern
    exclude_doption = "exclude_#{variant}_and_descendents".intern
    exclude_aoption = "exclude_#{variant}_and_ancestors".intern
    actual = Aquarium::Finders::TypeFinder.new.find aoption => /Aquarium::ForDescendents::.*D1ForDescendents/, 
      doption => /Aquarium::ForDescendents::.*D1ForDescendents/, 
      exclude_aoption => /Aquarium::ForDescendents::.*D2ForDescendents/, 
      exclude_doption => /Aquarium::ForDescendents::.*D2ForDescendents/
    actual_keys = purge_actuals actual
    expected = Aquarium::Utils::TypeUtils.sample_types_ancestors[D1ForDescendents].reject do |c|
      Aquarium::Utils::TypeUtils.sample_types_ancestors[ModuleForDescendents].include? c
    end
    actual.not_matched_keys.should == []
  end
end

%w[type types name names].each do |n|
  instance_eval <<-EOF
    describe Aquarium::Finders::TypeFinder, "#find regexps with :exclude_#{n}_and_ancestors and :exclude_#{n}_and_descendents used to specify one or more names" do
      variant = "#{n}"
      it_should_behave_like "#find with excluded regular expressions, including descendents and ancestors"
    end
  EOF
end
