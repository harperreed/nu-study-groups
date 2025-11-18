# ABOUTME: Mailer for session-related notifications with .ics calendar attachments
# ABOUTME: Sends RSVP confirmations, session reminders, and new session announcements
class SessionMailer < ApplicationMailer
  include IcalendarHelper

  # Sends RSVP confirmation with .ics calendar attachment
  #
  # @param session_rsvp [SessionRsvp] The RSVP record
  def rsvp_confirmation(session_rsvp)
    @rsvp = session_rsvp
    @session = session_rsvp.session
    @user = session_rsvp.user
    @group = @session.study_group
    @course = @group.course

    attach_calendar_event(@session, @user, session_rsvp.status)

    mail(
      to: @user.email,
      subject: "#{@session.title} - #{@session.date.strftime('%B %d, %Y')}"
    )
  end

  # Sends 24-hour reminder with .ics calendar attachment
  #
  # @param session_rsvp [SessionRsvp] The RSVP record
  def session_reminder(session_rsvp)
    @rsvp = session_rsvp
    @session = session_rsvp.session
    @user = session_rsvp.user
    @group = @session.study_group
    @course = @group.course

    attach_calendar_event(@session, @user, session_rsvp.status)

    mail(
      to: @user.email,
      subject: "Reminder: #{@session.title} tomorrow"
    )
  end

  # Notifies group members when a new session is created
  #
  # @param session [Session] The newly created session
  # @param user [User] The group member to notify
  def new_session_created(session, user)
    @session = session
    @user = user
    @group = session.study_group
    @course = @group.course

    mail(
      to: user.email,
      subject: "New session scheduled for #{@group.name}"
    )
  end

  private

  # Attaches .ics calendar file to the email
  #
  # @param session [Session] The session to create calendar event for
  # @param user [User] The user receiving the calendar invite
  # @param rsvp_status [String] The user's RSVP status
  def attach_calendar_event(session, user, rsvp_status)
    calendar = generate_calendar_event(session, user, rsvp_status)

    attachments["session-#{session.id}.ics"] = {
      mime_type: 'text/calendar',
      content: calendar.to_ical
    }
  end
end
