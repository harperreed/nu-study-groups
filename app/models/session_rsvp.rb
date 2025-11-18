# ABOUTME: Join model for session RSVPs with going/maybe/not_going statuses
# ABOUTME: Tracks which users are attending which sessions
class SessionRsvp < ApplicationRecord
  belongs_to :user
  belongs_to :session

  enum status: { going: 0, maybe: 1, not_going: 2 }

  validates :user_id, uniqueness: { scope: :session_id }

  scope :attending, -> { where(status: [:going, :maybe]) }
end
