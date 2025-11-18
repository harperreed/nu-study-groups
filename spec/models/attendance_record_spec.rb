# ABOUTME: Test suite for AttendanceRecord model
# ABOUTME: Tests actual attendance tracking vs RSVP status
require 'rails_helper'

RSpec.describe AttendanceRecord, type: :model do
  describe 'validations' do
    subject { build(:attendance_record) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:session_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:session) }
    it { should belong_to(:recorded_by).class_name('User') }
  end
end
