Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Courses (admin only)
  resources :courses

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
