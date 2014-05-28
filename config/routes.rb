Rails.application.routes.draw do

  # CORS requests will send a pre-flight OPTIONS request that we need to handle
  match '*path',  to: 'application#CORS', via: [:options]

  get  'health',  to: 'application#health'
  post 'error',   to: 'application#error'


  scope module: :v1, constraints: ApiConstraints.new(version: 1, default: :true), defaults: { format: 'json' } do

    get 'simulation_count',  to: 'misc#simulation_count'

    resources :users, only: [:create, :show] do
      collection do
        post 'accept_terms',  to: 'users#details'
        post 'add_oauth',     to: 'users#add_oauth'
      end
    end

    resource :session, only: [:create, :destroy] do
      collection do
        post 'check_oauth', to: 'sessions#check_oauth'
      end
    end

    resources :securities, only: [:index, :show]

    resources :authentications, only: [:index, :show]

  end # v1

end
