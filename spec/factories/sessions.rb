# ABOUTME: FactoryBot factory for creating test sessions
# ABOUTME: Generates realistic session data with dates, times, locations
FactoryBot.define do
  factory :session do
    association :study_group
    sequence(:title) { |n| "Study Session #{n}" }
    date { 1.week.from_now.to_date }
    start_time { '14:00' }
    end_time { '16:00' }
    location { Faker::Address.full_address }
    meeting_link { Faker::Internet.url }
    description { Faker::Lorem.paragraph }
    max_capacity { 10 }
    prep_materials { Faker::Lorem.paragraph }

    trait :full do
      after(:create) do |session|
        create_list(:session_rsvp, session.max_capacity, session: session, status: :going)
      end
    end

    trait :past do
      date { 1.week.ago.to_date }
    end
  end
end
