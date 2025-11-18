# ABOUTME: Preview class for StudyGroupMailer emails in development
# ABOUTME: View previews at http://localhost:3000/rails/mailers/study_group_mailer
class StudyGroupMailerPreview < ActionMailer::Preview
  # Preview for join request submitted email
  # Accessible at /rails/mailers/study_group_mailer/join_request_submitted
  def join_request_submitted
    membership = StudyGroupMembership.pending.first || create_sample_pending_membership
    StudyGroupMailer.join_request_submitted(membership)
  end

  # Preview for join request approved email
  # Accessible at /rails/mailers/study_group_mailer/join_request_approved
  def join_request_approved
    membership = StudyGroupMembership.approved.first || create_sample_approved_membership
    StudyGroupMailer.join_request_approved(membership)
  end

  # Preview for join request rejected email
  # Accessible at /rails/mailers/study_group_mailer/join_request_rejected
  def join_request_rejected
    membership = StudyGroupMembership.rejected.first || create_sample_rejected_membership
    StudyGroupMailer.join_request_rejected(membership)
  end

  private

  def create_sample_pending_membership
    course = Course.first || Course.create!(
      name: 'Introduction to Computer Science',
      code: 'CS101',
      description: 'Fundamentals of programming',
      semester: 'Fall',
      year: 2024
    )

    creator = User.find_or_create_by!(email: 'teacher@example.com') do |u|
      u.name = 'Dr. Smith'
      u.role = :teacher
      u.provider = 'google'
      u.uid = 'teacher123'
    end

    student = User.find_or_create_by!(email: 'student@example.com') do |u|
      u.name = 'Jane Doe'
      u.role = :student
      u.provider = 'google'
      u.uid = 'student123'
    end

    group = StudyGroup.find_or_create_by!(
      name: 'Advanced Algorithms Study Group',
      course: course,
      creator: creator
    ) do |g|
      g.description = 'Weekly study sessions for advanced algorithms'
      g.group_type = :official
      g.status = :active
    end

    StudyGroupMembership.create!(
      user: student,
      study_group: group,
      status: :pending,
      requested_at: Time.current
    )
  end

  def create_sample_approved_membership
    membership = create_sample_pending_membership
    membership.update!(
      status: :approved,
      approved_by: membership.study_group.creator,
      approved_at: Time.current
    )
    membership
  end

  def create_sample_rejected_membership
    membership = create_sample_pending_membership
    membership.update!(
      status: :rejected,
      approved_by: membership.study_group.creator
    )
    membership
  end
end
