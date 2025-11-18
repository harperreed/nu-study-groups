Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Admin Dashboard
  namespace :admin do
    get 'dashboard', to: 'admin#dashboard'
  end

  # Courses (admin only)
  resources :courses

  # Study Groups (students/teachers/admins can create, creator/admin can manage)
  resources :study_groups do
    member do
      post :join
    end

    # Study Sessions nested under study groups
    resources :study_sessions, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end

  # Study Group Memberships (approve/reject join requests)
  resources :study_group_memberships, only: [:index] do
    member do
      patch :approve
      patch :reject
    end
  end

  # Session RSVPs (separate resource, not nested)
  resources :session_rsvps, only: [:create, :update, :destroy]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
