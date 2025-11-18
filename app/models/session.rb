# ABOUTME: Session model for individual study group meeting sessions
# ABOUTME: Tracks date, time, location, capacity and manages RSVPs
class Session < ApplicationRecord
  belongs_to :study_group

  has_many :session_rsvps, dependent: :destroy
  has_many :attendees, through: :session_rsvps, source: :user
  has_many :session_resources, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :title, presence: true
  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  scope :upcoming, -> { where('date >= ?', Date.current).order(:date, :start_time) }
  scope :past, -> { where('date < ?', Date.current).order(date: :desc, start_time: :desc) }

  def full?
    return false if max_capacity.nil?

    session_rsvps.attending.count >= max_capacity
  end

  def spots_remaining
    return nil if max_capacity.nil?

    max_capacity - session_rsvps.attending.count
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
end
