class CoParticipantsController < ApplicationController
  # respond_to :html, :js
  unloadable
  
  def is_show
    project_id = params[:project_id]
    @project = Project.find(project_id)
    result =false
    
    if !@project.nil? && @project.module_enabled?(:co_participants)
      result = true
    end
    
    render :json => result
  end
  
end