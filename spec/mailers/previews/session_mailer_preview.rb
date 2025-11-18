# ABOUTME: Preview class for SessionMailer emails in development
# ABOUTME: View previews at http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  # Preview for RSVP confirmation email
  # Accessible at /rails/mailers/session_mailer/rsvp_confirmation
  def rsvp_confirmation
    session_rsvp = SessionRsvp.going.first || create_sample_rsvp
    SessionMailer.rsvp_confirmation(session_rsvp)
  end

  # Preview for session reminder email
  # Accessible at /rails/mailers/session_mailer/session_reminder
  def session_reminder
    session_rsvp = SessionRsvp.going.first || create_sample_rsvp
    SessionMailer.session_reminder(session_rsvp)
  end

  # Preview for new session created email
  # Accessible at /rails/mailers/session_mailer/new_session_created
  def new_session_created
    session = Session.first || create_sample_session
    user = User.students.first || create_sample_student
    SessionMailer.new_session_created(session, user)
  end

  private

  def create_sample_session
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

    group = StudyGroup.find_or_create_by!(
      name: 'Advanced Algorithms Study Group',
      course: course,
      creator: creator
    ) do |g|
      g.description = 'Weekly study sessions for advanced algorithms'
      g.group_type = :official
      g.status = :active
    end

    Session.create!(
      study_group: group,
      title: 'Dynamic Programming Workshop',
      description: 'Learn dynamic programming techniques with hands-on examples',
      date: Date.tomorrow,
      start_time: Time.zone.parse('14:00'),
      end_time: Time.zone.parse('16:00'),
      location: 'Room 301, Computer Science Building',
      meeting_link: 'https://zoom.us/j/123456789',
      max_capacity: 20,
      prep_materials: 'Read Chapter 15 on Dynamic Programming before the session'
    )
  end

  def create_sample_student
    User.find_or_create_by!(email: 'student@example.com') do |u|
      u.name = 'Jane Doe'
      u.role = :student
      u.provider = 'google'
      u.uid = 'student123'
    end
  end

  def create_sample_rsvp
    session = create_sample_session
    student = create_sample_student

    SessionRsvp.create!(
      session: session,
      user: student,
      status: :going,
      rsvp_at: Time.current
    )
  end
end
