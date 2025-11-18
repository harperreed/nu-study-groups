# ABOUTME: Test suite for SessionRsvp model covering RSVP status management
# ABOUTME: Tests going, maybe, not_going statuses and uniqueness constraints
require 'rails_helper'

RSpec.describe SessionRsvp, type: :model do
  describe 'validations' do
    subject { build(:session_rsvp) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:session_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:session) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(going: 0, maybe: 1, not_going: 2) }
  end

  describe 'scopes' do
    let(:session) { create(:session) }
    let!(:going_rsvp) { create(:session_rsvp, session: session, status: :going) }
    let!(:maybe_rsvp) { create(:session_rsvp, session: session, status: :maybe) }
    let!(:not_going_rsvp) { create(:session_rsvp, session: session, status: :not_going) }

    it '.attending returns going and maybe RSVPs' do
      attending = session.session_rsvps.attending
      expect(attending).to include(going_rsvp, maybe_rsvp)
      expect(attending).not_to include(not_going_rsvp)
    end
  end
end
