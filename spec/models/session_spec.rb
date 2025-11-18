# ABOUTME: Test suite for Session model covering validations and capacity management
# ABOUTME: Tests date/time validations and RSVP capacity tracking
require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }

    it 'validates end_time is after start_time' do
      session = build(:session, start_time: '14:00', end_time: '13:00')
      expect(session).not_to be_valid
      expect(session.errors[:end_time]).to include('must be after start time')
    end
  end

  describe 'associations' do
    it { should belong_to(:study_group) }
    it { should have_many(:session_rsvps).dependent(:destroy) }
    it { should have_many(:attendees).through(:session_rsvps).source(:user) }
    it { should have_many(:session_resources).dependent(:destroy) }
    it { should have_many(:attendance_records).dependent(:destroy) }
  end

  describe '#full?' do
    let(:session) { create(:session, max_capacity: 5) }

    context 'when RSVP count is below capacity' do
      before do
        create_list(:session_rsvp, 3, session: session, status: :going)
      end

      it 'returns false' do
        expect(session.full?).to be false
      end
    end

    context 'when RSVP count equals capacity' do
      before do
        create_list(:session_rsvp, 5, session: session, status: :going)
      end

      it 'returns true' do
        expect(session.full?).to be true
      end
    end

    context 'when capacity is nil' do
      let(:session) { create(:session, max_capacity: nil) }

      it 'returns false' do
        expect(session.full?).to be false
      end
    end
  end

  describe '#spots_remaining' do
    let(:session) { create(:session, max_capacity: 10) }

    before do
      create_list(:session_rsvp, 7, session: session, status: :going)
    end

    it 'returns the correct number of spots' do
      expect(session.spots_remaining).to eq(3)
    end
  end
end
