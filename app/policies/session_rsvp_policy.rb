# ABOUTME: Authorization policy for SessionRsvp model
# ABOUTME: Users can only manage their own RSVPs if they're approved group members
class SessionRsvpPolicy < ApplicationPolicy
  def create?
    return false unless user.present?

    # User must be an approved member of the study group
    membership = record.session.study_group.study_group_memberships.find_by(user: user)
    membership&.approved?
  end

  def update?
    return false unless user.present?

    # User can only update their own RSVP
    record.user == user
  end

  def destroy?
    return false unless user.present?

    # User can only delete their own RSVP
    record.user == user
  end
end
