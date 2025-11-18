# ABOUTME: AttendanceRecord model for tracking actual session attendance
# ABOUTME: Records whether students attended vs their RSVP status
class AttendanceRecord < ApplicationRecord
  belongs_to :session
end
