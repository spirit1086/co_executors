module CoParticipants
    module Hooks
        class IssueShowDescriptionBottom < Redmine::Hook::ViewListener
            
          def view_issues_show_description_bottom(context={ })
               
                @issueUsers = getIssueUsers(context)
                assigned_users = assignedUsersJoin(@issueUsers) 
                context[:controller].send(:render_to_string, {
                  :partial => "issue/issues_show_description_bottom",
                  :locals => {assigned_users:assigned_users}
                })
          end 
          
          def getIssueUsers(context)
              issue_id = context[:issue].id
              @issueUser = IssueUser.new
              return @issueUser.getIssueAssignedUsers(issue_id)             
          end
          
          def assignedUsersJoin(issueUsers)
               selected=Array.new
             
               issueUsers.each do |item|
                 format = Setting.user_format.to_sym 
                 fio = link_to_user(item.user,{:format=>format})
                 selected.push(fio)        
               end
               
               return safe_join(selected, ",".html_safe) 
          end
          
        end # end class
    end
end          