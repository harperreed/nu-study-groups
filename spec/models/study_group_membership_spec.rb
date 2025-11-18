# ABOUTME: Test suite for StudyGroupMembership model covering approval workflow
# ABOUTME: Tests pending, approved, rejected statuses and uniqueness constraints
require 'rails_helper'

RSpec.describe StudyGroupMembership, type: :model do
  describe 'validations' do
    subject { build(:study_group_membership) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:study_group_id).with_message('already has an active membership request') }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:study_group) }
    it { should belong_to(:approved_by).class_name('User').optional }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2) }
  end

  describe '#approve!' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user) }
    let(:study_group) { create(:study_group) }
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    it 'changes status to approved and records approver' do
      membership.approve!(teacher)

      expect(membership.reload.status).to eq('approved')
      expect(membership.approved_by).to eq(teacher)
      expect(membership.approved_at).to be_present
    end
  end

  describe '#reject!' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user) }
    let(:study_group) { create(:study_group) }
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    it 'changes status to rejected' do
      membership.reject!(teacher)

      expect(membership.reload.status).to eq('rejected')
      expect(membership.approved_by).to eq(teacher)
    end
  end
end
