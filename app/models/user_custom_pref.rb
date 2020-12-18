class UserCustomPref < ActiveRecord::Base

  belongs_to :user
  
  def getuserPreference(user_id,type)
    UserCustomPref.where(user_id:user_id).where(ctype:type)
  end
  
  def setData(data)
    UserCustomPref.new
    UserCustomPref.create(data)
  end
  
end
