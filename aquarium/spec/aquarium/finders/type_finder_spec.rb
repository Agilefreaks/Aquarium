require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/finders/type_finder'

describe Aquarium::Finders::TypeFinder, "#find" do

  it "should raise if an uknown option is specified." do
    lambda { Aquarium::Finders::TypeFinder.new.find :foo => 'bar', :baz => ''}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should raise if the input parameters do not form a hash." do
    lambda { Aquarium::Finders::TypeFinder.new.find "foo" }.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  
  it "should return no matched and no unmatched expressions by default (i.e., the input is empty)." do
    actual = Aquarium::Finders::TypeFinder.new.find
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should return no matched and no unmatched expressions if the input hash is empty." do
    actual = Aquarium::Finders::TypeFinder.new.find {}
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should trim leading and trailing whitespace in the specified types." do
    actual = Aquarium::Finders::TypeFinder.new.find :type => ["  \t ", "\t \n"]
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should ignore an empty string as the specified type." do
    actual = Aquarium::Finders::TypeFinder.new.find :type => "  \t "
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
  
  it "should ignore empty strings as the specified types in an array of types." do
    actual = Aquarium::Finders::TypeFinder.new.find :types => ["  \t ", "\t \n"]
    actual.matched.should == {}
    actual.not_matched.should == {}
  end
end

describe Aquarium::Finders::TypeFinder, "#is_recognized_option" do
  
  it "should be true for :names, :types, :name, :type (synonyms), as strings or symbols." do
    %w[name type names types].each do |s|
      Aquarium::Finders::TypeFinder.is_recognized_option(s).should == true
      Aquarium::Finders::TypeFinder.is_recognized_option(s.to_sym).should == true
    end
  end  
  
  it "should be false for unknown options." do
    %w[public2 wierd unknown string method object].each do |s|
      Aquarium::Finders::TypeFinder.is_recognized_option(s).should == false
      Aquarium::Finders::TypeFinder.is_recognized_option(s.to_sym).should == false
    end
  end
end

class Outside
  class Inside1; end
  class Inside2; end
end

describe Aquarium::Finders::TypeFinder, "#find with :type or :name used to specify a single type" do
  it "should find a type matching a simple name (without :: namespace delimiters) using its name." do
    actual = Aquarium::Finders::TypeFinder.new.find :type => :Object
    actual.matched_keys.should == [Object]
    actual.not_matched.should == {}
  end
  
  it "should return an empty match for a simple name (without :: namespace delimiters) that doesn't match an existing class." do
    actual = Aquarium::Finders::TypeFinder.new.find :name => :Unknown
    actual.matched.should == {}
    actual.not_matched_keys.should == [:Unknown]
  end
  
  it "should find a type matching a name with :: namespace delimiters using its name." do
    actual = Aquarium::Finders::TypeFinder.new.find :name => "Outside::Inside1"
    actual.matched_keys.should == [Outside::Inside1]
    actual.not_matched.should == {}
  end
end
  
describe Aquarium::Finders::TypeFinder, "#find with :types, :names, :type, and :name used to specify one or more names and/or regular expressions" do
  it "should find types matching simple names (without :: namespace delimiters) using their names." do
    expected_found_types  = [Class, Kernel, Module, Object]
    expected_unfound_exps = %w[TestCase Unknown1 Unknown2]
    actual = Aquarium::Finders::TypeFinder.new.find :types=> %w[Kernel Module Object Class TestCase Unknown1 Unknown2]
    actual.matched_keys.sort.should == expected_found_types.sort
    actual.not_matched_keys.should == expected_unfound_exps
  end
  
  it "should find types matching simple names (without :: namespace delimiters) using lists of regular expressions." do
    expected_found_types  = [Class, Kernel, Module, Object]
    expected_unfound_exps = [/Unknown2/, /^.*TestCase.*$/, /^Unknown1/]
    actual = Aquarium::Finders::TypeFinder.new.find :types => [/K.+l/, /^Mod.+e$/, /^Object$/, /Clas{2}/, /^.*TestCase.*$/, /^Unknown1/, /Unknown2/]
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.sort.should == expected_unfound_exps.sort
  end
  
  it "should find types with :: namespace delimiters using their names." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    expected_unfound_exps = %w[Foo::Bar::Baz]
    actual = Aquarium::Finders::TypeFinder.new.find :names => (expected_found_types.map {|t| t.to_s} + expected_unfound_exps)
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.sort.should == expected_unfound_exps.sort
  end
  
  it "should find types with :: namespace delimiters using lists of regular expressions." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    expected_unfound_exps = [/^.*Fo+::.*Bar+::Baz.$/]
    actual = Aquarium::Finders::TypeFinder.new.find :types => [/^.*Fo+::.*Bar+::Baz.$/, /Outside::.*1$/, "Out.*::In.*2"]
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.should == expected_unfound_exps
  end
end

describe Aquarium::Finders::TypeFinder, "#find" do
  it "should find types when types given." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    actual = Aquarium::Finders::TypeFinder.new.find :names => expected_found_types
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.should == []
  end
end

describe Aquarium::Finders::TypeFinder, "#find_all_by" do
  it "should find types with :: namespace delimiters using lists of regular expressions." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    expected_unfound_exps = [/^.*Fo+::.*Bar+::Baz.$/]
    actual = Aquarium::Finders::TypeFinder.new.find_all_by [/^.*Fo+::.*Bar+::Baz.$/, /Outside::.*1$/, "Out.*::In.*2"]
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.should == expected_unfound_exps
  end
  
  it "should find types with :: namespace delimiters using their names." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    expected_unfound_exps = %w[Foo::Bar::Baz]
    actual = Aquarium::Finders::TypeFinder.new.find_all_by(expected_found_types.map {|t| t.to_s} + expected_unfound_exps)
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.should == expected_unfound_exps
  end

  it "should find types when types given." do
    expected_found_types  = [Outside::Inside1, Outside::Inside2]
    actual = Aquarium::Finders::TypeFinder.new.find_all_by expected_found_types
    actual.matched_keys.sort_by {|x| x.to_s}.should == expected_found_types.sort_by {|x| x.to_s}
    actual.not_matched_keys.should == []
  end
end

describe Aquarium::Finders::TypeFinder, "#find_by_name" do
  it "should find a single type when given a single type name." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name("String")
    actual.matched_keys.should == [String]
    actual.not_matched_keys.should == []
    actual = tf.find_by_name("Kernel")
    actual.matched_keys.should == [Kernel]
    actual.not_matched_keys.should == []
    actual = tf.find_by_name("Module")
    actual.matched_keys.should == [Module]
    actual.not_matched_keys.should == []
  end

  it "should find a single type when given a valid type name with :: separators." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name "Outside::Inside1"
    actual.matched_keys.should == [Outside::Inside1]
    actual.not_matched_keys.should == []
  end

  it "should find a single type when given that type." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name Outside::Inside1
    actual.matched_keys.should == [Outside::Inside1]
    actual.not_matched_keys.should == []
  end

  it "should return no matches if the type can't be found." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name "UnknownClass1::UnknownClass2"
    actual.matched_keys.should == []
    actual.not_matched_keys.should == ["UnknownClass1::UnknownClass2"]
  end

  it "should return no matches if the type name is invalid." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name "$foo:bar"
    actual.matched_keys.should == []
    actual.not_matched_keys.should == ["$foo:bar"]
  end
end

describe Aquarium::Finders::TypeFinder, "#find_by_type" do
  it "is synonymous with find_by_name." do
    tf = Aquarium::Finders::TypeFinder.new
    actual = tf.find_by_name "Outside::Inside1"
    actual.matched_keys.should == [Outside::Inside1]
    actual.not_matched_keys.should == []
    actual = tf.find_by_name Outside::Inside1
    actual.matched_keys.should == [Outside::Inside1]
    actual.not_matched_keys.should == []
  end
end
 
  