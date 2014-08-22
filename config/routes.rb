Rails.application.routes.draw do

  match '*path',  to: 'misc#CORS', via: [:options]
  root            to: 'misc#home'
  get  'health',  to: 'misc#health'
  post 'error',   to: 'misc#error'

  scope 'api', module: :v1, constraints: ApiConstraints.new(version: 1, default: :true), defaults: { format: 'json' } do

    get  'simulation_count',  to: 'misc#simulation_count'
    post 'js_error',          to: 'misc#js_error'

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

    resources :assets, only: [:index, :show]
    resources :etfs, only: [:index, :show]

    # FIXME: `resource` as we aren't loading into ember data store. Perhaps change
    # to make consistent with everything else.
    resource  :efficient_frontier, only: [:show]

    resources :portfolios, only: [:index, :create, :show] do
      collection do
        get :selected_for_frontier
      end
    end

    resources :expenses, only: [:index, :create, :show, :update, :destroy] do
      collection do
        post :confirm
      end
    end

    # `resources` (rather than `resource` to make ember data happy)
    resources :simulation_inputs, only: [:index, :create, :show, :update]

    resource  :simulation, only: [:create, :show]

    resources :tracked_portfolios, only: [:create] do
      collection do
        get   :quotes
        post  :purchased_units
        post  :email_instructions
      end
    end

  end # v1

  namespace 'admin', defaults: { format: 'json' } do
    resources :sessions, only: [:create] do
      collection do
        delete '/', to: 'sessions#destroy'
      end
    end
    resources :users,           only: [:index]
    resources :questionnaires,  only: [:index]
    resources :portfolios,      only: [:index]
  end

end
