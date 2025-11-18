# ABOUTME: Helper module for generating iCalendar (.ics) files for study sessions
# ABOUTME: Creates calendar events with session details, RSVP status, and attendee information
module IcalendarHelper
  # Generates an iCalendar object for a study session
  #
  # @param session [Session] The session to create a calendar event for
  # @param user [User] The user receiving the calendar invite
  # @param rsvp_status [String] The user's RSVP status: 'going', 'maybe', or 'not_going'
  # @return [Icalendar::Calendar] A calendar object containing the event
  def generate_calendar_event(session, user, rsvp_status)
    calendar = Icalendar::Calendar.new

    calendar.event do |event|
      # Basic event details
      event.dtstart = Icalendar::Values::DateTime.new(
        DateTime.new(
          session.date.year,
          session.date.month,
          session.date.day,
          session.start_time.hour,
          session.start_time.min,
          session.start_time.sec,
          Time.zone.formatted_offset
        )
      )

      event.dtend = Icalendar::Values::DateTime.new(
        DateTime.new(
          session.date.year,
          session.date.month,
          session.date.day,
          session.end_time.hour,
          session.end_time.min,
          session.end_time.sec,
          Time.zone.formatted_offset
        )
      )

      event.summary = session.title
      event.location = session.location

      # Build description with all relevant information
      description_parts = []
      description_parts << session.description if session.description.present?
      description_parts << "\nStudy Group: #{session.study_group.name}"
      description_parts << "Course: #{session.study_group.course.code} - #{session.study_group.course.name}"
      description_parts << "\nMeeting Link: #{session.meeting_link}" if session.meeting_link.present?

      event.description = description_parts.join("\n")

      # Set organizer (study group creator)
      event.organizer = Icalendar::Values::CalAddress.new(
        "mailto:#{session.study_group.creator.email}",
        cn: session.study_group.creator.name
      )

      # Set attendee with RSVP status
      partstat = case rsvp_status
                 when 'going'
                   'ACCEPTED'
                 when 'maybe'
                   'TENTATIVE'
                 when 'not_going'
                   'DECLINED'
                 else
                   'NEEDS-ACTION'
                 end

      event.attendee = Icalendar::Values::CalAddress.new(
        "mailto:#{user.email}",
        cn: user.name,
        partstat: partstat
      )

      # Generate a unique UID for the event based on session and user
      event.uid = "session-#{session.id}-user-#{user.id}@studygroup.example.com"

      # Set timestamp
      event.dtstamp = Icalendar::Values::DateTime.new(DateTime.now)
    end

    calendar
  end
end
