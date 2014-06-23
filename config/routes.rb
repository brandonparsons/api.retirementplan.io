Rails.application.routes.draw do

  get  'health',  to: 'application#health'
  post 'error',   to: 'application#error'

  scope 'api', module: :v1, constraints: ApiConstraints.new(version: 1, default: :true), defaults: { format: 'json' } do

    get 'simulation_count',  to: 'misc#simulation_count'

    resources :users, only: [:create, :show, :update] do
      collection do
        post  :create_password
        get   :preferences
        put   '/preferences(/:id)', to: :set_preferences
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

    # FIXME: `resource` as we aren't loading into ember data store. Perhaps change
    # to make consistent with everything else.
    resource :session, only: [:create, :destroy] do
      collection do
        post :check_oauth
      end
    end

    resources :authentications, only: [:index, :create, :show, :destroy]

    # `resources` (rather than `resource` to make ember data happy)
    resources :questionnaires, only: [:index, :create, :show, :update]

    resources :securities, only: [:index, :show]

    # FIXME: `resource` as we aren't loading into ember data store. Perhaps change
    # to make consistent with everything else.
    resource  :efficient_frontier, only: [:show]

    # FIXME: `resource` as we aren't loading into ember data store. Perhaps change
    # to make consistent with everything else.
    resource  :portfolio, only: [:create, :show]

    resources :expenses, only: [:index, :create, :show, :update, :destroy] do
      collection do
        post :confirm
      end
    end

    # `resources` (rather than `resource` to make ember data happy)
    resources :simulation_inputs, only: [:index, :create, :show, :update]

    resource  :simulation, only: [:create, :show]

  end # v1

end
