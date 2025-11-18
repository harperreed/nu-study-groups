Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Courses (admin only)
  resources :courses

  # Study Groups (students/teachers/admins can create, creator/admin can manage)
  resources :study_groups do
    member do
      post :join
    end
  end

  # Study Group Memberships (approve/reject join requests)
  resources :study_group_memberships, only: [:index] do
    member do
      patch :approve
      patch :reject
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
