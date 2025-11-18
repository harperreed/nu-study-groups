# ABOUTME: Test suite for SessionResource model
# ABOUTME: Tests file attachment and resource type validation
require 'rails_helper'

RSpec.describe SessionResource, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should belong_to(:session) }
    it { should belong_to(:uploaded_by).class_name('User') }
  end

  describe 'enums' do
    it { should define_enum_for(:resource_type).with_values(prep: 0, notes: 1, recording: 2) }
  end
end
