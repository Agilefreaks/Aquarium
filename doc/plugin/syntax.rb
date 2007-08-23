require File.dirname(__FILE__) + "/aquarium_content"

class AquariumContentConverter < ContentConverters::DefaultContentConverter
  include ::Aquarium::SyntaxConverter
  
  infos(:name => "ContentConverter/Aquarium", 
        :author => "Aquarium / Dean Wampler", 
        :summary => "Redcloth + Ruby HTML tag syntax converter") 
        
  register_handler 'aquarium'
  
  def call(content)
    AquariumContent.new(content).to_html
  end
  
end
