# ABOUTME: AttendanceRecord model for tracking actual session attendance
# ABOUTME: Records whether students attended vs their RSVP status
class AttendanceRecord < ApplicationRecord
  belongs_to :user
  belongs_to :session
  belongs_to :recorded_by, class_name: 'User'

  validates :user_id, uniqueness: { scope: :session_id }
end
