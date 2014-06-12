Rails.application.routes.draw do

  # CORS requests will send a pre-flight OPTIONS request that we need to handle
  match '*path',  to: 'application#CORS', via: [:options]

  get  'health',  to: 'application#health'
  post 'error',   to: 'application#error'


  scope module: :v1, constraints: ApiConstraints.new(version: 1, default: :true), defaults: { format: 'json' } do

    get 'simulation_count',  to: 'misc#simulation_count'

    resources :users, only: [:create, :show, :update] do
      collection do
        post  :create_password
        get   :preferences
        put  '/preferences(/:id)', to: :set_preferences
        post  :accept_terms
      end
    end

    resources :password_resets, only: [:create] do
      collection do
        post :reset
      end
    end

    resources :email_confirmations, only: [:create] do
      collection do
        post :confirm
      end
    end

    resource :session, only: [:create, :destroy] do
      collection do
        post :check_oauth
      end
    end

    resources :authentications, only: [:index, :create, :show, :destroy]

    resources :questionnaires, only: [:index, :create, :show, :update]

    resources :securities, only: [:index, :show]

  end # v1

end
