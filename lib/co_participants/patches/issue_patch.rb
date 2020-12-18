require_dependency 'issue'
require_dependency 'issue_user'

module CoParticipants
  module Patches
    module IssuePatch
      
        def self.included(base)
              base.extend(ClassMethods)
              base.send(:include, InstanceMethods)  
          
              base.class_eval do  
                 unloadable

                 after_save :after_save_custom_issue

                 has_many :issue_users, :class_name => 'IssueUser', :foreign_key => 'issue_id', :dependent => :delete_all
        
                 def self.visible_condition(user, options={})
                                 Project.allowed_to_condition(user, :view_issues, options) do |role, user|
                                       sql = if user.id && user.logged?
                                               case role.issues_visibility
                                               when 'all'
                                                 '1=1'
                                               when 'default'
                                                 user_ids = [user.id] + user.groups.pluck(:id).compact
                                                 "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}))"
                                               when 'own'
                                                 user_ids = [user.id] + user.groups.pluck(:id).compact            
                                                 "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) OR   #{table_name}.id IN (SELECT issue_id FROM #{IssueUser.table_name} WHERE #{IssueUser.table_name}.user_id=#{user.id}) OR #{table_name}.id IN (SELECT watchable_id FROM watchers WHERE user_id=#{user.id} AND watchable_type = 'Issue'))"
                                               else
                                                 '1=0'
                                               end
                                             else
                                               "(#{table_name}.is_private = #{connection.quoted_false})"
                                             end
                                       unless role.permissions_all_trackers?(:view_issues)
                                         tracker_ids = role.permissions_tracker_ids(:view_issues)
                                         if tracker_ids.any?
                                           sql = "(#{sql} AND #{table_name}.tracker_id IN (#{tracker_ids.join(',')}))"
                                         else
                                           sql = '1=0'
                                         end
                                       end
                                       sql
                                 end
                 end
                 #Edit own issues:author, assigned_to, co-participants
                 def attributes_editable?(user=User.current)
                     user_tracker_permission?(user, :edit_issues)|| (
                     user_tracker_permission?(user, :edit_own_issues) && (author == user || assigned_to == user || IssueUser.where( issue_id: self.id, user_id: user).exists?)
                     )
                 end
          
                 # переопределяем базовые методы своими
                 alias_method :visible_without_patch?, :visible?
                 alias_method :visible?, :visible_with_patch?

                 alias_method :notified_users_without_patch, :notified_users
                 alias_method :notified_users, :notified_users_with_patch

                 alias_method :safe_attributes_without_safe_users_patch=, :safe_attributes=
                 alias_method :safe_attributes=, :safe_attributes_with_safe_users_patch=
              end
        end
        
        module ClassMethods   
        end
        
        module InstanceMethods
        
            def issue_co_participants
               format = Setting.user_format.to_sym
               co_participants = Array.new
               
               self.issue_users.each do |item|
                  user_fio = HtmlHelper.link_to_profile(item.user,{:format=>format})
                  co_participants.push(user_fio)
               end
               return co_participants.join(', ').html_safe    
            end  
        
            def safe_attributes_with_safe_users_patch=(attrs, user = User.current)
                  if attrs && attrs[:users_id]
                     users = attrs[:users_id].reject(&:empty?)
                     @users_id = users
                  end
                  self.safe_attributes_without_safe_users_patch=attrs
            end
               
            def after_save_custom_issue
                 usersRelation(self) 
            end
                
            def notified_users_with_patch
                 notified = notified_users_without_patch
                 notified +=getNotifyCoParticipiantsUsers(self)                      
                 logger.info 'LOG notified_users: '+self.id.to_s+'/'+notified.to_json
                 notified  
            end
            
            def getNotifyCoParticipiantsUsers(issue)
               users = Array.new
               issue.issue_users.each do |item|
                    users.push(item.user)        
               end
               logger.info 'copart_users:'+users.to_json
               users
            end
            
            def visible_with_patch?(usr=nil)
              return true if self.watched_by?(usr || User.current)
                (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
                  visible = if user.logged?
                              case role.issues_visibility
                              when 'all'
                                true
                              when 'default'
                                !self.is_private? || (self.author == user || user.is_or_belongs_to?(assigned_to) || checkCoParticipants(self.id,User.current))
                              when 'own'
                                self.author == user || user.is_or_belongs_to?(assigned_to) || checkCoParticipants(self.id,User.current) || self.watched_by?(usr || User.current)
                              else
                                false
                              end
                            else
                              !self.is_private?
                            end
                  unless role.permissions_all_trackers?(:view_issues)
                    visible &&= role.permissions_tracker_ids?(:view_issues, tracker_id)
                  end
                  visible
                end
            end 
          
            private 
          
              def usersRelation(issue)
                                     
                 if issue.author.id == User.current.id || issue.assigned_to_id == User.current.id
                     @issueUser = IssueUser.new
                     @issueUser.delBeforeCreate(issue.id)
                 
                     if @users_id.present?
                         relation = Array.new
                        
                         @users_id.each do |user_id|
                            item  = [:user_id=>user_id]
                            relation.push(item)        
                         end
                         
                         issue.issue_users.create(relation)
                     end
                 end 
                            
              end
            
              def checkCoParticipants(issue_id,current_user)
                    @issueUser = IssueUser.new
                    res = @issueUser.getIssueAssignedUsers(issue_id)
                                    
                    selected=Array.new
                    res.each do |item|
                       selected.push(item.user.id)        
                    end  
                                                   
                    bool_res  = selected.include?(current_user.id)                   
                   return bool_res                 
              end

        end #InstanceMethods
        
    end    
  end
end  