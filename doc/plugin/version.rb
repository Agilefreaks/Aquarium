require File.dirname(__FILE__) + '/../../aquarium/lib/aquarium/version'

class VersionTag < Tags::DefaultTag
  infos(:name => "CustomTag/VersionTag",
        :summary => "Puts the version on the page")
        
  register_tag 'version'

  @@version_string = Aquarium::VERSION::STRING
  
  def process_tag(tag, node)
    return @@version_string
  end
end
