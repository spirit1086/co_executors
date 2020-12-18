require_dependency 'issue_query'
require_dependency 'issue'
require_dependency 'issue_user'

module CoParticipants
  module Patches
    module IssueQueryPatch
    
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

           alias_method :available_filters_without_co_patch, :available_filters
           alias_method :available_filters, :available_filters_with_co_patch

           alias_method :statement_without_co_patch, :statement
           alias_method :statement, :statement_with_co_patch

           alias_method :available_columns_without_co_patch, :available_columns
           alias_method :available_columns, :available_columns_with_co_patch
  
        end
      end

      module InstanceMethods
       
        def available_columns_with_co_patch
          return @available_columns if @available_columns
               @available_columns = available_columns_without_co_patch
               index = @available_columns.find_index {|column| column.name == :author}
               index = (index ? index + 1 : -1)
               @available_columns.insert index, QueryColumn.new(:issue_co_participants,:caption => :co_part_users)
               @available_columns
        end
       
        def statement_with_co_patch
            filter  = filters.delete 'issue_user'
            clauses = statement_without_co_patch || ''
            
            if filter
              projects_parent = parentProjects(self.project_id.to_i)
              projects_sub = subProjects(self.project_id.to_i)
              projects_all = projects_parent+projects_sub
              projects_ids = projects_all.collect(&:id).uniq.join(',')
              filters['issue_user'] = filter
        
                op = operator_for('issue_user')
                values = values_for('issue_user').map { |x| x == 'me' ? User.current.id : x }
                values = values.join(',')
                case op
                    when '=' #все задачи проекта доступные мне, которые соответствует выбраным соучастнику или соучастникам
                       issues  = Issue.joins("INNER JOIN #{IssueUser.table_name} 
                                                      ON #{IssueUser.table_name}.issue_id = #{Issue.table_name}.id")
                                      .where("#{Issue.table_name}.project_id IN (#{projects_ids}) AND 
                                              #{IssueUser.table_name}.user_id IN (#{values})")
                      
                    when '!' # все задачи проекта доступные мне, которые не соответствует выбраным соучастнику или соучастникам 
                      issues  = Issue.joins("INNER JOIN #{IssueUser.table_name} 
                                                     ON #{IssueUser.table_name}.issue_id = #{Issue.table_name}.id")
                                      .where("#{Issue.table_name}.project_id IN (#{projects_ids}) AND 
                                              #{Issue.table_name}.id NOT IN (
                                                                           SELECT #{IssueUser.table_name}.issue_id 
                                                                             FROM #{IssueUser.table_name}
                                                                            WHERE #{IssueUser.table_name}.user_id  IN (#{values})                                                
                                                                                 )")
                    when '!*' # все задачи проекта доступные мне, в которых отсуствуют соучастники 
                      issues  = Issue.where("#{Issue.table_name}.project_id IN (#{projects_ids})") 
                                      .where("#{Issue.table_name}.id NOT IN (SELECT #{IssueUser.table_name}.issue_id FROM #{IssueUser.table_name})")
                    else # только задачи проекта доступные мне, только в которых есть соучастники 
                      issues  = Issue.where("#{Issue.table_name}.project_id IN (#{projects_ids})") 
                                      .where("#{Issue.table_name}.id IN (SELECT #{IssueUser.table_name}.issue_id FROM #{IssueUser.table_name})")
                end
        
                ids_list  = issues.collect(&:id).push(0).join(',')
                   
                clauses << ' AND ' unless clauses.empty?
                clauses << "( #{Issue.table_name}.id IN (#{ids_list}) ) "
            end
        
            clauses
        end

       
        def available_filters_with_co_patch
           available_filters_without_co_patch
           add_available_filter("issue_user",
                :type => :list_optional, name: l(:co_part_users),:values => lambda { assigned_to_values }
           )
        end
      
        private 
          def parentProjects(id)
            return  Project.where("#{Project.table_name}.id IN (SELECT #{Project.table_name}.parent_id 
                                                       FROM #{Project.table_name}
                                                      WHERE #{Project.table_name}.id=#{id}
                                                       ) or #{Project.table_name}.id = #{id}") 
          end

          def subProjects(id)
            return  Project.where("#{Project.table_name}.id IN (SELECT #{Project.table_name}.id 
                                                       FROM #{Project.table_name}
                                                      WHERE #{Project.table_name}.parent_id=#{id}
                                                       ) or #{Project.table_name}.id = #{id}")
          end
        
      end # end module
      
    end
  end
end

