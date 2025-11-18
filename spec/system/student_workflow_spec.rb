# ABOUTME: System test for student workflow end-to-end
# ABOUTME: Tests browsing courses, joining groups, RSVPing to sessions
require 'rails_helper'

RSpec.describe 'Student Workflow', type: :system do
  let(:student) { create(:user, :student) }
  let(:teacher) { create(:user, :teacher) }
  let(:course) { create(:course) }
  let!(:study_group) { create(:study_group, course: course, creator: teacher) }

  before do
    sign_in_as(student)
  end

  describe 'browsing and discovering study groups' do
    it 'allows students to browse courses and view study groups' do
      visit root_path

      # Should see courses link
      click_link 'Courses'

      # Should see the course
      expect(page).to have_text(course.name)
      expect(page).to have_text(course.code)

      # Click on the course to view study groups
      click_link course.name

      # Should see the study group
      expect(page).to have_text(study_group.name)
      expect(page).to have_text(study_group.description)
    end
  end

  describe 'requesting to join a study group' do
    it 'allows students to request to join a group' do
      visit course_path(course)

      # Click on the study group
      click_link study_group.name

      # Request to join
      click_button 'Join Study Group'

      # Should see pending status
      expect(page).to have_text('Pending Approval')
      expect(page).to have_text('Your request to join is pending approval')

      # Verify membership was created
      membership = StudyGroupMembership.find_by(user: student, study_group: study_group)
      expect(membership).to be_present
      expect(membership.status).to eq('pending')
    end

    it 'shows error when trying to join twice' do
      # Create existing pending membership
      create(:study_group_membership, :pending, user: student, study_group: study_group)

      visit study_group_path(study_group)

      # Should see already pending message
      expect(page).to have_text('Pending Approval')
    end
  end

  describe 'getting approved and viewing sessions' do
    let!(:membership) { create(:study_group_membership, :approved, user: student, study_group: study_group) }
    let!(:session) { create(:study_session, study_group: study_group) }

    it 'shows approved status and allows viewing sessions' do
      visit study_group_path(study_group)

      # Should see member badge
      expect(page).to have_text('Member')

      # Should see sessions
      expect(page).to have_text('Sessions')
      expect(page).to have_text(session.title)

      # Click on the session
      click_link session.title

      # Should see session details
      expect(page).to have_text(session.description)
      expect(page).to have_text(session.location)
    end
  end

  describe 'RSVPing to a session' do
    let!(:membership) { create(:study_group_membership, :approved, user: student, study_group: study_group) }
    let!(:session) { create(:study_session, study_group: study_group) }

    it 'allows students to RSVP to a session', js: true do
      visit study_session_path(study_group, session)

      # RSVP as going
      click_button 'Going'

      # Should see confirmation
      expect(page).to have_text('You are going to this session')

      # Verify RSVP was created
      rsvp = SessionRsvp.find_by(user: student, session: session)
      expect(rsvp).to be_present
      expect(rsvp.status).to eq('going')
    end

    it 'allows students to change their RSVP status', js: true do
      # Create initial RSVP
      create(:session_rsvp, :going, user: student, session: session)

      visit study_session_path(study_group, session)

      # Should show current status
      expect(page).to have_text('You are going to this session')

      # Change to maybe
      click_button 'Maybe'

      # Should update status
      expect(page).to have_text('You might attend this session')

      # Verify RSVP was updated
      rsvp = SessionRsvp.find_by(user: student, session: session)
      expect(rsvp.status).to eq('maybe')
    end

    it 'shows capacity limits' do
      # Create a session with limited capacity
      limited_session = create(:study_session, study_group: study_group, max_capacity: 2)

      # Fill up the session
      other_student1 = create(:user, :student)
      other_student2 = create(:user, :student)
      create(:study_group_membership, :approved, user: other_student1, study_group: study_group)
      create(:study_group_membership, :approved, user: other_student2, study_group: study_group)
      create(:session_rsvp, :going, user: other_student1, session: limited_session)
      create(:session_rsvp, :going, user: other_student2, session: limited_session)

      visit study_session_path(study_group, limited_session)

      # Should show session is full
      expect(page).to have_text('2/2 spots filled')
      expect(page).to have_text('Session Full')
    end
  end

  describe 'complete student journey' do
    it 'completes the full workflow from browsing to RSVP', js: true do
      # Start from home page
      visit root_path

      # Browse courses
      click_link 'Courses'
      expect(page).to have_text(course.name)

      # View course study groups
      click_link course.name
      expect(page).to have_text(study_group.name)

      # View study group details
      click_link study_group.name

      # Request to join
      click_button 'Join Study Group'
      expect(page).to have_text('Pending Approval')

      # Simulate teacher approval (sign out, sign in as teacher, approve)
      click_button 'Logout'
      sign_in_as(teacher)

      visit study_group_memberships_path
      expect(page).to have_text(student.name)

      # Approve the request
      click_button 'Approve'
      expect(page).to have_text('Membership approved')

      # Create a session
      visit study_group_path(study_group)
      click_link 'Schedule Session'

      fill_in 'Title', with: 'Test Session'
      fill_in 'Description', with: 'Test description'
      fill_in 'Date', with: 1.day.from_now.strftime('%Y-%m-%d')
      fill_in 'Start time', with: '14:00'
      fill_in 'End time', with: '16:00'
      fill_in 'Location', with: 'Room 101'
      fill_in 'Max capacity', with: '10'

      click_button 'Create Session'
      expect(page).to have_text('Session created successfully')

      # Sign out and sign back in as student
      click_button 'Logout'
      sign_in_as(student)

      # Go back to study group and RSVP
      visit study_group_path(study_group)
      click_link 'Test Session'

      # RSVP to the session
      click_button 'Going'
      expect(page).to have_text('You are going to this session')

      # Verify the RSVP was created
      session = StudySession.find_by(title: 'Test Session')
      rsvp = SessionRsvp.find_by(user: student, session: session)
      expect(rsvp).to be_present
      expect(rsvp.status).to eq('going')
    end
  end
end
