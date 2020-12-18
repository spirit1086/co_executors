module CoParticipants
    module Hooks
        class MultipleAssigned < Redmine::Hook::ViewListener
           
          def view_issues_form_details_bottom(context={ })
                
               selected = getIssueAssignedUsers(context)
               options = getAllProjectUsers(context)
               disabled_status = disabledMultiSelect(context)
               Rails.logger.debug('CoParticipants init in form')
                context[:controller].send(:render_to_string, {
                  :partial => "issue/multiple_assigned",
                  :locals => {selected:selected,
                              options:options,
                              disabled_status:disabled_status}
                })
          end 
          
              
          def disabledMultiSelect(context)
              issue = context[:issue]
              if issue.author.id == User.current.id || issue.assigned_to_id == User.current.id
                false
              else
                true  
              end
          end
          
          def getAllProjectUsers(context)
             format = Setting.user_format.to_sym 
             
             return User.joins('LEFT JOIN members ON users.id = members.user_id')
                        .where("members.project_id=:project_id",{project_id:context[:issue].project_id})
                        .all.map { |u| [u.name(format), u.id] }
          end 
          
          def getIssueAssignedUsers(context)
             issue_id = context[:issue].id
                                             
             @issueUser = IssueUser.new
             @multiple_assigned = @issueUser.getIssueAssignedUsers(issue_id)
             
             selected=Array.new
             @multiple_assigned.each do |item|
               selected.push(item.user_id)        
             end 
                          
             return selected   
          end
          
        end
    end
end        