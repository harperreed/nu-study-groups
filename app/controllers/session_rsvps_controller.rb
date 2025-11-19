# ABOUTME: Controller for managing session RSVPs with capacity checks
# ABOUTME: Handles RSVP create/update/destroy with Turbo Streams for dynamic updates
class SessionRsvpsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rsvp, only: [:update, :destroy]

  def create
    @session = Session.find(params[:session_rsvp][:session_id])
    @rsvp = @session.session_rsvps.build(rsvp_params)
    @rsvp.user = current_user
    @rsvp.rsvp_at = Time.current

    authorize @rsvp

    # Check capacity only for "going" status
    if @rsvp.status == 'going' && @session.full?
      redirect_to study_group_study_session_path(@session.study_group, @session),
                  alert: 'Sorry, this session is full.'
      return
    end

    if @rsvp.save
      # Send RSVP confirmation email with .ics attachment
      SessionMailer.rsvp_confirmation(@rsvp).deliver_later

      redirect_to study_group_study_session_path(@session.study_group, @session),
                  notice: "You've RSVP'd #{@rsvp.status.humanize} for this session."
    else
      redirect_to study_group_study_session_path(@session.study_group, @session),
                  alert: 'Unable to create RSVP.'
    end
  end

  def update
    authorize @rsvp

    # Check capacity only if updating to "going" status
    if rsvp_params[:status] == 'going' && @rsvp.session.full? && @rsvp.status != 'going'
      redirect_to study_group_study_session_path(@rsvp.session.study_group, @rsvp.session),
                  alert: 'Sorry, this session is now full.'
      return
    end

    if @rsvp.update(rsvp_params)
      redirect_to study_group_study_session_path(@rsvp.session.study_group, @rsvp.session),
                  notice: "Your RSVP has been updated to #{@rsvp.status.humanize}."
    else
      redirect_to study_group_study_session_path(@rsvp.session.study_group, @rsvp.session),
                  alert: 'Unable to update RSVP.'
    end
  end

  def destroy
    authorize @rsvp
    session = @rsvp.session
    @rsvp.destroy

    redirect_to study_group_study_session_path(session.study_group, session),
                notice: 'Your RSVP has been removed.'
  end

  private

  def set_rsvp
    @rsvp = SessionRsvp.find(params[:id])
  end

  def rsvp_params
    params.require(:session_rsvp).permit(:status, :session_id)
  end
end
