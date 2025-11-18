# ABOUTME: FactoryBot factory for creating test session RSVPs
# ABOUTME: Supports going, maybe, not_going statuses
FactoryBot.define do
  factory :session_rsvp do
    association :user
    association :session
    status { :going }
    rsvp_at { Time.current }

    trait :maybe do
      status { :maybe }
    end

    trait :not_going do
      status { :not_going }
    end
  end
end
