require 'redmine'
require_dependency 'co_participants/hooks/multiple_assigned'
require_dependency 'co_participants/hooks/issues_show_description_bottom'
require_dependency 'co_participants/patches/extended_watchers_project_patch'
require_dependency 'co_participants/patches/extended_watchers_application_controller_patch'

class Hooks < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :partial => 'head/assets', :layout => false
end

Redmine::Plugin.register :co_participants do
  name 'Co-participants'
  author 'Arman Mambetov (KapTechnology)'
  description 'Плагин позволяет добавлять соучастников в задачи (issues)'
  version '0.0.1'

  project_module :co_participants do
    permission :show,issue: :new
  end
end
#if redmine will be update this permission unnecessary 
Redmine::AccessControl.map do |map|

    map.project_module :issue_tracking do |map|
        map.permission :edit_own_issues, {:issues => [:edit, :update, :bulk_edit, :bulk_update], :journals => [:new], :attachments => :upload}
    end
end
RedmineExtensions::Reloader.to_prepare do
    unless Issue.included_modules.include?(CoParticipants::Patches::IssuePatch)
      Issue.send(:include, CoParticipants::Patches::IssuePatch)
    end
    
    unless Journal.included_modules.include?(CoParticipants::Patches::JournalPatch)
       Journal.send(:include, CoParticipants::Patches::JournalPatch)
    end

    unless IssueQuery.included_modules.include?(CoParticipants::Patches::IssueQueryPatch)
      IssueQuery.send(:include, CoParticipants::Patches::IssueQueryPatch)
    end
end
