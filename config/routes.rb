Rails.application.routes.draw do
  get 'users/index'
  root 'users#index'
  post 'login', to: 'session#login', as: 'login'
  delete 'login', to: 'session#destroy', as: 'logout'
  resources :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
