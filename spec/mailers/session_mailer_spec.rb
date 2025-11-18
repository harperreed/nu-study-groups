# ABOUTME: RSpec tests for SessionMailer email notifications with .ics attachments
# ABOUTME: Tests RSVP confirmation, session reminders, and new session notifications
require 'rails_helper'

RSpec.describe SessionMailer, type: :mailer do
  let(:course) { create(:course, code: 'CS101', name: 'Introduction to Computer Science') }
  let(:creator) { create(:user, name: 'Dr. Smith', email: 'smith@example.com') }
  let(:student) { create(:user, name: 'Jane Doe', email: 'jane@example.com') }
  let(:study_group) { create(:study_group, course: course, creator: creator, name: 'Advanced Algorithms Study Group') }
  let(:session) do
    create(:session,
           study_group: study_group,
           title: 'Dynamic Programming Workshop',
           date: Date.tomorrow,
           start_time: Time.zone.parse('14:00'),
           end_time: Time.zone.parse('16:00'),
           location: 'Room 301',
           meeting_link: 'https://zoom.us/j/123456')
  end

  describe '#rsvp_confirmation' do
    let(:session_rsvp) { create(:session_rsvp, session: session, user: student, status: :going) }
    let(:mail) { SessionMailer.rsvp_confirmation(session_rsvp) }

    it 'sends email to student' do
      expect(mail.to).to eq([student.email])
    end

    it 'has correct subject with session title and date' do
      expect(mail.subject).to include('Dynamic Programming Workshop')
      expect(mail.subject).to include(session.date.strftime('%B %d, %Y'))
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes session title in body' do
      expect(mail.body.encoded).to include('Dynamic Programming Workshop')
    end

    it 'includes location in body' do
      expect(mail.body.encoded).to include('Room 301')
    end

    it 'includes meeting link in body' do
      expect(mail.body.encoded).to include('https://zoom.us/j/123456')
    end

    it 'attaches .ics calendar file' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments.first
      expect(attachment.filename).to eq("session-#{session.id}.ics")
      expect(attachment.content_type).to start_with('text/calendar')
    end

    it 'generates valid icalendar content' do
      attachment = mail.attachments.first
      ics_content = attachment.body.to_s
      expect(ics_content).to include('BEGIN:VCALENDAR')
      expect(ics_content).to include('BEGIN:VEVENT')
      expect(ics_content).to include('Dynamic Programming Workshop')
      expect(ics_content).to include('Room 301')
      expect(ics_content).to include('END:VEVENT')
      expect(ics_content).to include('END:VCALENDAR')
    end
  end

  describe '#session_reminder' do
    let(:session_rsvp) { create(:session_rsvp, session: session, user: student, status: :going) }
    let(:mail) { SessionMailer.session_reminder(session_rsvp) }

    it 'sends email to student' do
      expect(mail.to).to eq([student.email])
    end

    it 'has reminder subject' do
      expect(mail.subject).to include('Reminder')
      expect(mail.subject).to include('Dynamic Programming Workshop')
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes session details in body' do
      expect(mail.body.encoded).to include('Dynamic Programming Workshop')
      expect(mail.body.encoded).to include('Room 301')
    end

    it 'attaches .ics calendar file' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments.first
      expect(attachment.filename).to eq("session-#{session.id}.ics")
      expect(attachment.content_type).to start_with('text/calendar')
    end
  end

  describe '#new_session_created' do
    let(:mail) { SessionMailer.new_session_created(session, student) }

    it 'sends email to group member' do
      expect(mail.to).to eq([student.email])
    end

    it 'has correct subject' do
      expect(mail.subject).to include('New session scheduled')
      expect(mail.subject).to include('Advanced Algorithms Study Group')
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes session title in body' do
      expect(mail.body.encoded).to include('Dynamic Programming Workshop')
    end

    it 'includes session date and time in body' do
      expect(mail.body.encoded).to include(session.date.strftime('%B %d, %Y'))
    end

    it 'includes group name in body' do
      expect(mail.body.encoded).to include('Advanced Algorithms Study Group')
    end

    it 'does not attach .ics file for new session announcement' do
      expect(mail.attachments.count).to eq(0)
    end
  end
end
