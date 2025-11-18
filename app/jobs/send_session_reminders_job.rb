# ABOUTME: Background job to send reminder emails for sessions happening in 24 hours
# ABOUTME: Finds sessions with date tomorrow and sends reminders to all "going" RSVPs
class SendSessionRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # Find all sessions happening tomorrow
    tomorrow_sessions = Session.where(date: Date.tomorrow)

    tomorrow_sessions.each do |session|
      # Send reminders to all "going" RSVPs
      session.session_rsvps.where(status: :going).each do |rsvp|
        SessionMailer.session_reminder(rsvp).deliver_later
      end
    end
  end
end
