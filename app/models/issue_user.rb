class IssueUser < ActiveRecord::Base
  
     belongs_to :user
     belongs_to :issue
  
    def addIssueAssigned(data)
        IssueUser.new
        IssueUser.create(data)
    end
    
    def delBeforeCreate(issue_id)
        sql = "DELETE 
                 FROM issue_users 
                WHERE issue_id=#{issue_id}"
        ActiveRecord::Base.connection.execute(sql)
    end
    
    def getIssueAssignedUsers(issue_id)
        return IssueUser.where(issue_id: issue_id)
    end
    
end
