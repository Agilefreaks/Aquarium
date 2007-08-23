require File.dirname(__FILE__) + '/../../aquarium/lib/aquarium/version'

class SvnTagTag < Tags::DefaultTag
  infos(:name => "CustomTag/SvnTagTag",
        :summary => "Puts the svn tag URL on the page")
        
  register_tag 'svn_tag'

  @@version_string = Aquarium::VERSION::STRING
  
  def process_tag(tag, node)
    return @@version_string
  end
end
