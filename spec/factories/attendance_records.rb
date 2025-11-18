# ABOUTME: FactoryBot factory for creating test attendance records
# ABOUTME: Tracks actual attendance with notes and recorder
FactoryBot.define do
  factory :attendance_record do
    association :user
    association :session
    association :recorded_by, factory: [:user, :teacher]
    attended { true }
    notes { Faker::Lorem.sentence }
    recorded_at { Time.current }

    trait :absent do
      attended { false }
    end
  end
end
