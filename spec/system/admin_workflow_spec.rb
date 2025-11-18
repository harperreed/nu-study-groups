# ABOUTME: System test for admin workflow end-to-end
# ABOUTME: Tests admin dashboard, course management, and platform oversight
require 'rails_helper'

RSpec.describe 'Admin Workflow', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user, :student) }

  before do
    sign_in_as(admin)
  end

  describe 'accessing admin dashboard' do
    it 'allows admins to access the admin dashboard' do
      visit root_path

      click_link 'Admin Dashboard'

      # Should see dashboard
      expect(page).to have_text('Admin Dashboard')
      expect(page).to have_text('Platform Statistics')
    end

    it 'shows platform statistics' do
      # Create some data
      course = create(:course)
      study_group = create(:study_group, course: course)
      create_list(:user, 5, :student)

      visit admin_dashboard_path

      # Should see statistics
      expect(page).to have_text('Total Courses')
      expect(page).to have_text('Total Study Groups')
      expect(page).to have_text('Total Users')
    end
  end

  describe 'managing courses' do
    it 'allows admins to create a new course' do
      visit courses_path

      click_link 'New Course'

      fill_in 'Name', with: 'Introduction to Computer Science'
      fill_in 'Code', with: 'CS101'
      fill_in 'Description', with: 'Fundamentals of programming and algorithms'
      fill_in 'Semester', with: 'Fall'
      fill_in 'Year', with: '2024'

      click_button 'Create Course'

      # Should see success message
      expect(page).to have_text('Course created successfully')
      expect(page).to have_text('Introduction to Computer Science')
      expect(page).to have_text('CS101')

      # Verify course was created
      course = Course.find_by(code: 'CS101')
      expect(course).to be_present
      expect(course.name).to eq('Introduction to Computer Science')
    end

    it 'allows admins to edit a course' do
      course = create(:course, name: 'Old Name')

      visit courses_path
      click_link 'Old Name'
      click_link 'Edit Course'

      fill_in 'Name', with: 'Updated Course Name'
      fill_in 'Description', with: 'Updated description'

      click_button 'Update Course'

      # Should see updated information
      expect(page).to have_text('Course updated successfully')
      expect(page).to have_text('Updated Course Name')

      # Verify course was updated
      course.reload
      expect(course.name).to eq('Updated Course Name')
    end

    it 'allows admins to delete a course' do
      course = create(:course)

      visit course_path(course)

      click_button 'Delete Course'

      # Should see success message
      expect(page).to have_text('Course deleted successfully')

      # Verify course was deleted
      expect(Course.find_by(id: course.id)).to be_nil
    end
  end

  describe 'viewing pending approvals across platform' do
    let!(:course) { create(:course) }
    let!(:study_group1) { create(:study_group, course: course) }
    let!(:study_group2) { create(:study_group, course: course) }
    let!(:pending1) { create(:study_group_membership, :pending, study_group: study_group1) }
    let!(:pending2) { create(:study_group_membership, :pending, study_group: study_group2) }

    it 'shows all pending approvals from all groups' do
      visit study_group_memberships_path

      # Should see all pending requests
      expect(page).to have_text(pending1.user.name)
      expect(page).to have_text(pending2.user.name)
      expect(page).to have_text(study_group1.name)
      expect(page).to have_text(study_group2.name)
    end
  end

  describe 'overseeing all study groups' do
    let!(:course) { create(:course) }
    let!(:official_group) { create(:study_group, :official, course: course, creator: teacher) }
    let!(:peer_group) { create(:study_group, :peer, course: course, creator: student) }

    it 'allows admins to view all study groups' do
      visit course_path(course)

      # Should see both types of groups
      expect(page).to have_text(official_group.name)
      expect(page).to have_text(peer_group.name)
      expect(page).to have_text('Official')
      expect(page).to have_text('Peer')
    end

    it 'allows admins to edit any study group' do
      visit study_group_path(official_group)

      click_link 'Edit Group'

      fill_in 'Name', with: 'Admin Updated Group'
      fill_in 'Description', with: 'Updated by admin'

      click_button 'Update Study Group'

      # Should see updated information
      expect(page).to have_text('Study group updated successfully')
      expect(page).to have_text('Admin Updated Group')
    end
  end

  describe 'complete admin journey' do
    it 'completes full workflow from creating course to managing groups', js: true do
      # Start from home
      visit root_path

      # Access admin dashboard
      click_link 'Admin Dashboard'
      expect(page).to have_text('Admin Dashboard')

      # Create a new course
      click_link 'Manage Courses'
      click_link 'New Course'

      fill_in 'Name', with: 'Data Structures'
      fill_in 'Code', with: 'CS201'
      fill_in 'Description', with: 'Advanced data structures and algorithms'
      fill_in 'Semester', with: 'Spring'
      fill_in 'Year', with: '2024'

      click_button 'Create Course'
      expect(page).to have_text('Course created successfully')

      # Create a study group as teacher (simulate)
      course = Course.find_by(code: 'CS201')
      study_group = create(:study_group, course: course, creator: teacher)

      # Create a pending membership (simulate student request)
      membership = create(:study_group_membership, :pending, user: student, study_group: study_group)

      # View pending approvals
      visit study_group_memberships_path
      expect(page).to have_text(student.name)
      expect(page).to have_text(study_group.name)

      # Approve the request as admin
      click_button 'Approve'
      expect(page).to have_text('Membership approved')

      # Verify approval
      membership.reload
      expect(membership.status).to eq('approved')
      expect(membership.approved_by).to eq(admin)
    end
  end

  describe 'non-admins cannot access admin features' do
    it 'prevents students from accessing admin dashboard' do
      click_button 'Logout'
      sign_in_as(student)

      visit admin_dashboard_path

      # Should see unauthorized message or redirect
      expect(page).to have_text('not authorized') || expect(page).to have_current_path(root_path)
    end

    it 'prevents teachers from accessing admin dashboard' do
      click_button 'Logout'
      sign_in_as(teacher)

      visit admin_dashboard_path

      # Should see unauthorized message or redirect
      expect(page).to have_text('not authorized') || expect(page).to have_current_path(root_path)
    end
  end
end
