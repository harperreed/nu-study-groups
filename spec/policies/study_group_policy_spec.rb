# ABOUTME: Policy specs for StudyGroup authorization rules
# ABOUTME: Tests creator, teacher, and admin permissions for groups
require 'rails_helper'

RSpec.describe StudyGroupPolicy do
  subject { described_class.new(user, study_group) }

  let(:creator) { build(:user, role: :student) }
  let(:study_group) { build(:study_group, creator: creator, group_type: :peer) }

  context 'when user is a student who did not create the group' do
    let(:user) { build(:user, role: :student) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
  end

  context 'when user is the creator of the group' do
    let(:user) { creator }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end

  context 'when user is a teacher' do
    let(:user) { build(:user, role: :teacher) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
  end

  context 'when user is an admin' do
    let(:user) { build(:user, role: :admin) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end
end
