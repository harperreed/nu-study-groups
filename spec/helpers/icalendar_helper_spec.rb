# ABOUTME: Tests for IcalendarHelper which generates .ics calendar files
# ABOUTME: Verifies calendar events include all session details and correct RSVP status
require 'rails_helper'

RSpec.describe IcalendarHelper, type: :helper do
  let(:creator) { create(:user, name: 'Dr. Smith', email: 'smith@example.com') }
  let(:user) { create(:user, name: 'John Doe', email: 'john@example.com') }
  let(:course) { create(:course, code: 'CS101', name: 'Introduction to CS') }
  let(:study_group) { create(:study_group, course: course, creator: creator, name: 'Monday Study Group') }
  let(:session) do
    create(:session,
      study_group: study_group,
      title: 'Week 5 Review Session',
      date: Date.new(2025, 11, 25),
      start_time: Time.zone.parse('14:00'),
      end_time: Time.zone.parse('16:00'),
      location: 'Library Room 301',
      meeting_link: 'https://zoom.us/j/123456789',
      description: 'Review of chapters 5-7'
    )
  end

  describe '#generate_calendar_event' do
    it 'generates a valid Icalendar::Calendar object' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      expect(calendar).to be_a(Icalendar::Calendar)
    end

    it 'includes the session title' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.summary).to eq('Week 5 Review Session')
    end

    it 'includes the correct start and end times' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first

      expected_start = DateTime.new(2025, 11, 25, 14, 0, 0, Time.zone.formatted_offset)
      expected_end = DateTime.new(2025, 11, 25, 16, 0, 0, Time.zone.formatted_offset)

      expect(event.dtstart.to_datetime).to eq(expected_start)
      expect(event.dtend.to_datetime).to eq(expected_end)
    end

    it 'includes the location' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.location).to eq('Library Room 301')
    end

    it 'includes the description with meeting link' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.description).to include('Review of chapters 5-7')
      expect(event.description).to include('https://zoom.us/j/123456789')
    end

    it 'includes study group and course information in description' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.description).to include('Monday Study Group')
      expect(event.description).to include('CS101')
    end

    it 'sets the organizer to the group creator' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.organizer.to_s).to include('smith@example.com')
      expect(event.organizer.ical_params['cn']).to eq('Dr. Smith')
    end

    it 'sets the attendee to the user email' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      attendee = event.attendee.first
      expect(attendee.to_s).to include('john@example.com')
      expect(attendee.ical_params['cn']).to eq('John Doe')
    end

    context 'RSVP status handling' do
      it 'sets PARTSTAT to ACCEPTED for "going" status' do
        calendar = helper.generate_calendar_event(session, user, 'going')
        event = calendar.events.first
        attendee = event.attendee.first
        expect(attendee.ical_params['partstat']).to eq('ACCEPTED')
      end

      it 'sets PARTSTAT to TENTATIVE for "maybe" status' do
        calendar = helper.generate_calendar_event(session, user, 'maybe')
        event = calendar.events.first
        attendee = event.attendee.first
        expect(attendee.ical_params['partstat']).to eq('TENTATIVE')
      end

      it 'sets PARTSTAT to DECLINED for "not_going" status' do
        calendar = helper.generate_calendar_event(session, user, 'not_going')
        event = calendar.events.first
        attendee = event.attendee.first
        expect(attendee.ical_params['partstat']).to eq('DECLINED')
      end
    end

    it 'generates a unique UID for the event' do
      calendar1 = helper.generate_calendar_event(session, user, 'going')
      calendar2 = helper.generate_calendar_event(session, user, 'going')

      event1 = calendar1.events.first
      event2 = calendar2.events.first

      expect(event1.uid).to be_present
      expect(event1.uid).to eq(event2.uid) # Same session should have same UID
    end

    it 'includes a timestamp for when the event was created' do
      calendar = helper.generate_calendar_event(session, user, 'going')
      event = calendar.events.first
      expect(event.dtstamp).to be_present
    end

    context 'when session has no meeting link' do
      let(:session_without_link) do
        create(:session,
          study_group: study_group,
          title: 'In-person Only',
          date: Date.new(2025, 11, 25),
          start_time: Time.zone.parse('14:00'),
          end_time: Time.zone.parse('16:00'),
          location: 'Library Room 301',
          meeting_link: nil,
          description: 'In-person session'
        )
      end

      it 'does not include meeting link in description' do
        calendar = helper.generate_calendar_event(session_without_link, user, 'going')
        event = calendar.events.first
        expect(event.description).not_to include('Meeting Link')
      end
    end

    context 'when session has no description' do
      let(:session_without_description) do
        create(:session,
          study_group: study_group,
          title: 'Quick Session',
          date: Date.new(2025, 11, 25),
          start_time: Time.zone.parse('14:00'),
          end_time: Time.zone.parse('16:00'),
          location: 'Library Room 301',
          description: nil
        )
      end

      it 'still generates a valid calendar' do
        calendar = helper.generate_calendar_event(session_without_description, user, 'going')
        event = calendar.events.first
        expect(event.description).to be_present
        expect(event.description).to include('Monday Study Group')
      end
    end
  end
end
