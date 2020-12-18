require_dependency 'journal'

module CoParticipants
  module Patches
    module JournalPatch
      
        def self.included(base)
              base.extend(ClassMethods)
              base.send(:include, InstanceMethods)  
          
              base.class_eval do  
                 unloadable
                 acts_as_activity_provider :type => 'issues',
                                           :author_key => :user_id,
                                           :scope => preload({:issue => :project}, :user).
                                                     joins("LEFT OUTER JOIN #{JournalDetail.table_name} ON #{JournalDetail.table_name}.journal_id = #{Journal.table_name}.id").
                                                     joins('LEFT JOIN issue_users ON issue_users.issue_id = issues.id').
                                                     where("#{Journal.table_name}.journalized_type = 'Issue' AND" +
                                                            " (#{JournalDetail.table_name}.prop_key = 'status_id' OR #{Journal.table_name}.notes <> '')").distinct
              end
        end
        
        module ClassMethods   
        end
        
        module InstanceMethods
        end #InstanceMethods
        
    end    
  end
end  