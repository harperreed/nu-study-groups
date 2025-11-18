# ABOUTME: FactoryBot factory for creating test courses
# ABOUTME: Generates realistic course codes, names, and semester/year data
FactoryBot.define do
  factory :course do
    sequence(:code) { |n| "CS#{100 + n}" }
    name { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    semester { ['Fall', 'Spring', 'Summer'].sample }
    year { Time.current.year }
  end
end
