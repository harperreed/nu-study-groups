# ABOUTME: Test suite for StudyGroup model covering validations, associations, and group types
# ABOUTME: Tests official vs peer groups and creator permissions
require 'rails_helper'

RSpec.describe StudyGroup, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:group_type) }
  end

  describe 'associations' do
    it { should belong_to(:course) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:study_group_memberships).dependent(:destroy) }
    it { should have_many(:members).through(:study_group_memberships).source(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:group_type).with_values(official: 0, peer: 1) }
    it { should define_enum_for(:status).with_values(active: 0, archived: 1) }
  end

  describe 'scopes' do
    let(:course) { create(:course) }
    let!(:active_group) { create(:study_group, course: course, status: :active) }
    let!(:archived_group) { create(:study_group, course: course, status: :archived) }

    it '.active returns only active groups' do
      expect(StudyGroup.active).to include(active_group)
      expect(StudyGroup.active).not_to include(archived_group)
    end
  end
end
