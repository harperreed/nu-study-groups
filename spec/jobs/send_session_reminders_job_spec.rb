# ABOUTME: RSpec tests for SendSessionRemindersJob background job
# ABOUTME: Tests finding sessions in 24h and sending reminder emails to "going" RSVPs
require 'rails_helper'

RSpec.describe SendSessionRemindersJob, type: :job do
  let(:creator) { create(:user, name: 'Dr. Smith', email: 'smith@example.com') }
  let(:student1) { create(:user, name: 'Jane Doe', email: 'jane@example.com') }
  let(:student2) { create(:user, name: 'John Smith', email: 'john@example.com') }
  let(:course) { create(:course) }
  let(:study_group) { create(:study_group, course: course, creator: creator) }

  # Session tomorrow at 2pm (within 24h)
  let!(:session_tomorrow) do
    create(:session,
           study_group: study_group,
           date: Date.tomorrow,
           start_time: Time.zone.parse('14:00'))
  end

  # Session in 2 days (outside 24h)
  let!(:session_in_two_days) do
    create(:session,
           study_group: study_group,
           date: 2.days.from_now.to_date,
           start_time: Time.zone.parse('14:00'))
  end

  # Session yesterday (past)
  let!(:session_yesterday) do
    create(:session,
           study_group: study_group,
           date: Date.yesterday,
           start_time: Time.zone.parse('14:00'))
  end

  before do
    # Create RSVPs for tomorrow's session
    create(:session_rsvp, session: session_tomorrow, user: student1, status: :going)
    create(:session_rsvp, session: session_tomorrow, user: student2, status: :maybe)

    # Create RSVP for future session
    create(:session_rsvp, session: session_in_two_days, user: student1, status: :going)
  end

  describe '#perform' do
    it 'sends reminder emails only to "going" RSVPs for sessions within 24 hours' do
      expect {
        SendSessionRemindersJob.perform_now
      }.to have_enqueued_email(SessionMailer, :session_reminder).exactly(1).times
    end

    it 'does not send reminders for "maybe" RSVPs' do
      SendSessionRemindersJob.perform_now

      # Check that only the "going" RSVP gets a reminder
      enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      reminder_jobs = enqueued_jobs.select { |job|
        job[:job] == ActionMailer::MailDeliveryJob &&
        job[:args][0] == 'SessionMailer' &&
        job[:args][1] == 'session_reminder'
      }

      expect(reminder_jobs.count).to eq(1)
    end

    it 'does not send reminders for sessions outside 24 hour window' do
      SendSessionRemindersJob.perform_now

      # Verify no reminder for session in 2 days
      enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      reminder_jobs = enqueued_jobs.select { |job|
        job[:job] == ActionMailer::MailDeliveryJob &&
        job[:args][0] == 'SessionMailer' &&
        job[:args][1] == 'session_reminder'
      }

      # Should only have 1 reminder (for tomorrow's session)
      expect(reminder_jobs.count).to eq(1)
    end

    it 'does not send reminders for past sessions' do
      SendSessionRemindersJob.perform_now

      # No reminder should be sent for yesterday's session
      enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      reminder_jobs = enqueued_jobs.select { |job|
        job[:job] == ActionMailer::MailDeliveryJob &&
        job[:args][0] == 'SessionMailer' &&
        job[:args][1] == 'session_reminder'
      }

      expect(reminder_jobs.count).to eq(1)
    end
  end
end
