# ABOUTME: Test suite for User model covering validations, associations, and OAuth authentication
# ABOUTME: Tests user roles (student, teacher, admin) and OAuth provider integration
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { User.new(email: 'test@example.com', name: 'Test', provider: 'google', uid: '123', role: 'student') }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
    it { should validate_uniqueness_of(:email) }

    it 'validates uniqueness of uid scoped to provider' do
      user = User.create!(
        email: 'test@example.com',
        name: 'Test User',
        provider: 'google',
        uid: '12345',
        role: 'student'
      )

      duplicate = User.new(
        email: 'other@example.com',
        name: 'Other User',
        provider: 'google',
        uid: '12345',
        role: 'student'
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uid]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(student: 0, teacher: 1, admin: 2) }
  end

  describe '.from_omniauth' do
    let(:auth_hash) do
      {
        'provider' => 'google',
        'uid' => '12345',
        'info' => {
          'email' => 'student@example.com',
          'name' => 'Jane Student'
        }
      }
    end

    context 'when user does not exist' do
      it 'creates a new user with student role by default' do
        expect {
          User.from_omniauth(auth_hash)
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('student@example.com')
        expect(user.name).to eq('Jane Student')
        expect(user.provider).to eq('google')
        expect(user.uid).to eq('12345')
        expect(user.role).to eq('student')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) do
        User.create!(
          email: 'student@example.com',
          name: 'Jane Student',
          provider: 'google',
          uid: '12345',
          role: 'student'
        )
      end

      it 'returns the existing user' do
        expect {
          User.from_omniauth(auth_hash)
        }.not_to change(User, :count)

        user = User.from_omniauth(auth_hash)
        expect(user.id).to eq(existing_user.id)
      end
    end
  end
end
