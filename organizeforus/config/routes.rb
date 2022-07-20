Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks", :registrations => "users/registrations" }

  #Definita la route di sign_out:
  devise_scope :user do  
    get '/users/sign_out' => 'devise/sessions#destroy' 
    post '/user/auth/facebook/callback/after_social_connection' => 'users/after_auth#create'
 end

  resources :groups
  #get 'home/index'
  root 'home#index'
  get 'home/about'
  
  resources :groups do
    resources :members , only: [:new,:edit,:create]
  end 

 resources :partecipations , only:[:new,:create,:destroy]

  resources :groups do
    resources :roles, only: [:create]
  end 

  put 'groups/:id/partecipations/edit_driver', to: 'partecipations#edit_driver', as: 'edit_driver'
  get '/groups/:group_id/partecipations', to: 'partecipations#new', as: 'new_partecipations'
  get '/groups/:id/set_created', to: 'groups#set_created', as: 'set_created'

  get '/groups/:group_id/partecipations/:role/delete_role', to: 'partecipations#delete_role', as: 'delete_role'

  get '/groups/:group_id/partecipations/show', to: 'partecipations#show', as: 'show_p'
  put '/groups/:group_id/partecipations/:member_id/update_role', to: 'partecipations#update_role', as: 'update_role'

  get '/groups/:group_id/partecipations/:member_id/update', to: 'partecipations#update', as: 'update'

  get '/groups/:group_id/partecipations/:member_id/invite', to: 'partecipations#invite', as: 'invite'


  get 'partecipations/:id/accept', to: 'partecipations#accept', as: 'accept'
  get 'partecipations/:id/decline', to: 'partecipations#decline', as: 'decline'


  get 'partecipations/:id/destroy', to: 'partecipations#destroy', as: 'destroy_partecipation'
  get 'partecipations/new_role', to: 'partecipations#new_role', as: 'new_role'
  #get '/auth/:provider/callback' => 'sessions#omniauth'

  get '/groups/:group_id/surveys/user_id/new', to: 'surveys#new', as: 'new_survey'
  post '/groups/:group_id/surveys/create', to: 'surveys#create', as: 'new_surveys'


    
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
