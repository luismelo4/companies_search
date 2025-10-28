Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "companies#index"
  
  # Company search routes
  resources :companies, only: [:index] do
    collection do
      get :search
      get :autocomplete
    end
  end
  
  # Admin routes
  get '/admin', to: 'admin#index'
  post '/admin/import_csv', to: 'admin#import_csv'
  post '/admin/clear_data', to: 'admin#clear_data'
end
