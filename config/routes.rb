Rails.application.routes.draw do

  # CORS requests will send a pre-flight OPTIONS request that we need to handle
  match '*path', to: 'application#CORS', via: [:options]

  get  'health',     to: 'application#health'
  post 'error',      to: 'application#error'

  get  'auth/:action/callback', to: 'omniauth_callbacks'

  namespace :v1, defaults: { format: 'json' } do

    get 'simulation_count',  to: 'misc#simulation_count'

    resources :users, only: [:create] do
      collection do
        post    'sign_in',       to: 'sessions#create'
        delete  'sign_out',      to: 'sessions#destroy'
        post    'accept_terms',  to: 'users#details'
      end
    end

    resources :securities, only: [:index, :show]

  end

end
