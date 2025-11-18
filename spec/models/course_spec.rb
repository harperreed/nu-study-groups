# ABOUTME: Test suite for Course model covering validations and associations
# ABOUTME: Tests course-teacher relationships and basic CRUD operations
require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'validations' do
    subject { build(:course) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).scoped_to(:semester, :year) }
  end

  describe 'associations' do
    # StudyGroup will be created in Task 7
    # it { should have_many(:study_groups) }
    it { should have_many(:course_teachers).dependent(:destroy) }
    it { should have_many(:teachers).through(:course_teachers).source(:user) }
  end

  describe 'scopes' do
    let!(:current_course) { create(:course, semester: 'Fall', year: 2025) }
    let!(:past_course) { create(:course, semester: 'Spring', year: 2024) }

    it 'orders by year and semester by default' do
      courses = Course.all
      expect(courses.first).to eq(current_course)
      expect(courses.last).to eq(past_course)
    end
  end
end
