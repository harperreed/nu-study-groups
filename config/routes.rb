Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Courses (admin only)
  resources :courses

  # Study Groups (students/teachers/admins can create, creator/admin can manage)
  resources :study_groups

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
