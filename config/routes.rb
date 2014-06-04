Rails.application.routes.draw do

  # CORS requests will send a pre-flight OPTIONS request that we need to handle
  match '*path',  to: 'application#CORS', via: [:options]

  get  'health',  to: 'application#health'
  post 'error',   to: 'application#error'


  scope module: :v1, constraints: ApiConstraints.new(version: 1, default: :true), defaults: { format: 'json' } do

    get 'simulation_count',  to: 'misc#simulation_count'

    resources :users, only: [:create, :show, :update] do
      collection do
        post  'password_resets/new',      to: :new_password_reset
        post  'password_resets/request',  to: :request_password_reset
        post  :create_password
        post  :accept_terms
      end
    end

    resource :session, only: [:create, :destroy] do
      collection do
        post :check_oauth
      end
    end

    resources :securities, only: [:index, :show]

    resources :authentications, only: [:index, :create, :show, :destroy]

  end # v1

end
