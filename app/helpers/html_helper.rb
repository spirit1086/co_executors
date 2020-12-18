module HtmlHelper
  
  def self.link_to_profile(user,options={}) 
     if user.is_a?(User)
       name = user.name(options[:format])
         if user.active? || (User.current.admin? && user.logged?)
           '<a href="/people/'+user.id.to_s+'"><b>'+name+'</b></a>'.html_safe
         else
            name
         end
     else
       user.to_s
     end
  end
end