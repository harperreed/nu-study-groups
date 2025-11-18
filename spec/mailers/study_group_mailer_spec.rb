# ABOUTME: RSpec tests for StudyGroupMailer email notifications
# ABOUTME: Tests join request submitted, approved, and rejected emails
require 'rails_helper'

RSpec.describe StudyGroupMailer, type: :mailer do
  let(:course) { create(:course) }
  let(:creator) { create(:user, name: 'Dr. Smith', email: 'smith@example.com') }
  let(:student) { create(:user, name: 'Jane Doe', email: 'jane@example.com') }
  let(:study_group) { create(:study_group, course: course, creator: creator, name: 'Advanced Algorithms Study Group') }

  describe '#join_request_submitted' do
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }
    let(:mail) { StudyGroupMailer.join_request_submitted(membership) }

    it 'sends email to group creator' do
      expect(mail.to).to eq([creator.email])
    end

    it 'has correct subject' do
      expect(mail.subject).to eq('New join request for Advanced Algorithms Study Group')
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes group name in body' do
      expect(mail.body.encoded).to include('Advanced Algorithms Study Group')
    end

    it 'includes course information in body' do
      expect(mail.body.encoded).to include(course.name)
    end
  end

  describe '#join_request_approved' do
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :approved, approved_by: creator) }
    let(:mail) { StudyGroupMailer.join_request_approved(membership) }

    it 'sends email to student' do
      expect(mail.to).to eq([student.email])
    end

    it 'has correct subject' do
      expect(mail.subject).to eq("You've been added to Advanced Algorithms Study Group")
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes group name in body' do
      expect(mail.body.encoded).to include('Advanced Algorithms Study Group')
    end

    it 'includes welcoming message in body' do
      expect(mail.body.encoded).to match(/approved|added|welcome/i)
    end
  end

  describe '#join_request_rejected' do
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :rejected, approved_by: creator) }
    let(:mail) { StudyGroupMailer.join_request_rejected(membership) }

    it 'sends email to student' do
      expect(mail.to).to eq([student.email])
    end

    it 'has correct subject' do
      expect(mail.subject).to eq('Update on your request for Advanced Algorithms Study Group')
    end

    it 'includes student name in body' do
      expect(mail.body.encoded).to include('Jane Doe')
    end

    it 'includes group name in body' do
      expect(mail.body.encoded).to include('Advanced Algorithms Study Group')
    end

    it 'has polite tone in body' do
      expect(mail.body.encoded).to match(/unfortunately|sorry|regret/i)
    end
  end
end
