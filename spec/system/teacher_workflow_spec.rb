# ABOUTME: System test for teacher workflow end-to-end
# ABOUTME: Tests creating groups, scheduling sessions, approving members
require 'rails_helper'

RSpec.describe 'Teacher Workflow', type: :system do
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user, :student) }
  let(:course) { create(:course) }

  before do
    sign_in_as(teacher)
  end

  describe 'creating a study group' do
    it 'allows teachers to create a study group for a course' do
      visit course_path(course)

      # Create new study group
      click_link 'Create Study Group'

      fill_in 'Name', with: 'Advanced CS Study Group'
      fill_in 'Description', with: 'Weekly review sessions for advanced topics'
      select 'Official', from: 'Group type'

      click_button 'Create Study Group'

      # Should see success message
      expect(page).to have_text('Study group created successfully')
      expect(page).to have_text('Advanced CS Study Group')

      # Verify study group was created
      study_group = StudyGroup.find_by(name: 'Advanced CS Study Group')
      expect(study_group).to be_present
      expect(study_group.creator).to eq(teacher)
      expect(study_group.group_type).to eq('official')
    end
  end

  describe 'scheduling sessions' do
    let!(:study_group) { create(:study_group, course: course, creator: teacher) }

    it 'allows teachers to schedule a session for their group' do
      visit study_group_path(study_group)

      click_link 'Schedule Session'

      fill_in 'Title', with: 'Week 1: Introduction'
      fill_in 'Description', with: 'Overview of course topics'
      fill_in 'Date', with: 1.week.from_now.strftime('%Y-%m-%d')
      fill_in 'Start time', with: '15:00'
      fill_in 'End time', with: '17:00'
      fill_in 'Location', with: 'Library Room 204'
      fill_in 'Meeting link', with: 'https://zoom.us/j/123456789'
      fill_in 'Max capacity', with: '20'
      fill_in 'Prep materials', with: 'Read chapter 1 before session'

      click_button 'Create Session'

      # Should see success message
      expect(page).to have_text('Session created successfully')
      expect(page).to have_text('Week 1: Introduction')

      # Verify session was created
      session = StudySession.find_by(title: 'Week 1: Introduction')
      expect(session).to be_present
      expect(session.study_group).to eq(study_group)
      expect(session.location).to eq('Library Room 204')
    end

    it 'allows teachers to edit a session' do
      session = create(:study_session, study_group: study_group)

      visit study_session_path(study_group, session)

      click_link 'Edit Session'

      fill_in 'Title', with: 'Updated Title'
      fill_in 'Location', with: 'New Location'

      click_button 'Update Session'

      # Should see updated information
      expect(page).to have_text('Session updated successfully')
      expect(page).to have_text('Updated Title')
      expect(page).to have_text('New Location')
    end

    it 'allows teachers to delete a session' do
      session = create(:study_session, study_group: study_group)

      visit study_session_path(study_group, session)

      click_button 'Delete Session'

      # Should see success message
      expect(page).to have_text('Session deleted successfully')

      # Verify session was deleted
      expect(StudySession.find_by(id: session.id)).to be_nil
    end
  end

  describe 'managing join requests' do
    let!(:study_group) { create(:study_group, course: course, creator: teacher) }
    let!(:membership) { create(:study_group_membership, :pending, user: student, study_group: study_group) }

    it 'shows pending join requests', js: true do
      visit study_group_memberships_path

      # Should see pending request
      expect(page).to have_text(student.name)
      expect(page).to have_text(student.email)
      expect(page).to have_text(study_group.name)
      expect(page).to have_button('Approve')
      expect(page).to have_button('Reject')
    end

    it 'allows teachers to approve join requests', js: true do
      visit study_group_memberships_path

      # Approve the request
      click_button 'Approve'

      # Should see success message
      expect(page).to have_text('Membership approved')

      # Verify membership was approved
      membership.reload
      expect(membership.status).to eq('approved')
      expect(membership.approved_by).to eq(teacher)
    end

    it 'allows teachers to reject join requests', js: true do
      visit study_group_memberships_path

      # Reject the request
      click_button 'Reject'

      # Should see success message
      expect(page).to have_text('Membership rejected')

      # Verify membership was rejected
      membership.reload
      expect(membership.status).to eq('rejected')
    end
  end

  describe 'viewing group members' do
    let!(:study_group) { create(:study_group, course: course, creator: teacher) }
    let!(:approved_member) { create(:study_group_membership, :approved, study_group: study_group) }
    let!(:pending_member) { create(:study_group_membership, :pending, study_group: study_group) }

    it 'shows all group members with their status' do
      visit study_group_path(study_group)

      # Should see members section
      expect(page).to have_text('Members')

      # Should see approved member
      expect(page).to have_text(approved_member.user.name)

      # Should not see pending members in the main members list
      # (they should be in the approval queue)
    end
  end

  describe 'complete teacher journey' do
    it 'completes the full workflow from creating group to approving members', js: true do
      # Start from home page
      visit root_path

      # Go to courses
      click_link 'Courses'
      click_link course.name

      # Create a study group
      click_link 'Create Study Group'
      fill_in 'Name', with: 'Complete Test Group'
      fill_in 'Description', with: 'Testing complete workflow'
      select 'Official', from: 'Group type'
      click_button 'Create Study Group'

      expect(page).to have_text('Study group created successfully')

      # Schedule a session
      click_link 'Schedule Session'
      fill_in 'Title', with: 'First Session'
      fill_in 'Description', with: 'Introduction session'
      fill_in 'Date', with: 1.week.from_now.strftime('%Y-%m-%d')
      fill_in 'Start time', with: '14:00'
      fill_in 'End time', with: '16:00'
      fill_in 'Location', with: 'Room 101'
      fill_in 'Max capacity', with: '15'
      click_button 'Create Session'

      expect(page).to have_text('Session created successfully')

      # Simulate student requesting to join
      study_group = StudyGroup.find_by(name: 'Complete Test Group')
      create(:study_group_membership, :pending, user: student, study_group: study_group)

      # Go to memberships page
      visit study_group_memberships_path

      # Approve the student
      expect(page).to have_text(student.name)
      click_button 'Approve'

      expect(page).to have_text('Membership approved')

      # Verify student is now a member
      membership = StudyGroupMembership.find_by(user: student, study_group: study_group)
      expect(membership.status).to eq('approved')
      expect(membership.approved_by).to eq(teacher)
    end
  end
end
