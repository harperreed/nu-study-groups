# ABOUTME: Controller for managing study sessions (nested under study groups)
# ABOUTME: Handles CRUD operations with authorization for creator/admin to manage
class StudySessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_group
  before_action :set_session, only: [:show, :edit, :update, :destroy]

  def index
    # For policy authorization, we need to check against a session instance
    # We'll use a new session belonging to this study group
    authorize Session.new(study_group: @study_group)
    @sessions = @study_group.sessions.upcoming
  end

  def show
    authorize @session
    @current_user_rsvp = @session.session_rsvps.find_by(user: current_user)
  end

  def new
    @session = @study_group.sessions.build
    authorize @session
  end

  def create
    @session = @study_group.sessions.build(session_params)
    authorize @session

    if @session.save
      # Send notification to all group members about the new session
      @study_group.members.each do |member|
        SessionMailer.new_session_created(@session, member).deliver_now
      end

      redirect_to study_group_study_session_path(@study_group, @session), notice: 'Session was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @session
  end

  def update
    authorize @session

    if @session.update(session_params)
      redirect_to study_group_study_session_path(@study_group, @session), notice: 'Session was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @session
    @session.destroy
    redirect_to study_group_study_sessions_path(@study_group), notice: 'Session was successfully deleted.'
  end

  private

  def set_study_group
    @study_group = StudyGroup.find(params[:study_group_id])
  end

  def set_session
    @session = @study_group.sessions.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :title,
      :date,
      :start_time,
      :end_time,
      :location,
      :meeting_link,
      :description,
      :max_capacity,
      :prep_materials
    )
  end
end
