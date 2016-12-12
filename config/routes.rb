Rails.application.routes.draw do
  root 'gobierto_budgets/pages#home'

  if Rails.env.development?
    get '/sandbox' => 'sandbox#index'
    get '/sandbox/*template' => 'sandbox#show'
  end

  # user and session management
  get 'login' => 'sessions#new', as: :login
  post 'sessions'  => 'sessions#create'
  delete 'logout' => 'sessions#destroy', as: :logout
  resources :users, only: [:new, :create] do
    collection do
      post 'identify'
    end
    member do
      get 'verify'
    end
  end
  resource :user, only: [:edit, :update]
  resources :password_resets, only: [:new, :create, :update, :edit]

  get '/locale/:locale' => 'locale#update'

  namespace :gobierto_budgets, path: '/', module: 'gobierto_budgets' do
    resources :featured_budget_lines, only: [:show]

    namespace :api do
      get '/data/lines/:ine_code/:year/:what' => 'data#lines', as: :data_lines
      get '/data/compare/:ine_codes/:year/:what' => 'data#compare', as: :data_compare
      get '/data/lines/budget_line/:ine_code/:year/:what/:kind/:code/:area' => 'data#lines', as: :data_lines_budget_line
      get '/data/compare/budget_line/:ine_codes/:year/:what/:kind/:code/:area' => 'data#compare', as: :data_compare_budget_lines
      get '/data/widget/total_budget/:ine_code/:year' => 'data#total_budget', as: :data_total_budget
      get '/data/widget/total_budget_per_inhabitant/:ine_code/:year' => 'data#total_budget_per_inhabitant', as: :data_total_budget_per_inhabitant
      get '/data/widget/budget/:ine_code/:year/:code/:area/:kind' => 'data#budget', as: :data_budget
      get '/data/widget/budget_execution/:ine_code/:year/:code/:area/:kind' => 'data#budget_execution', as: :data_budget_execution
      get '/data/widget/budget_per_inhabitant/:ine_code/:year/:code/:area/:kind' => 'data#budget_per_inhabitant', as: :data_budget_per_inhabitant
      get '/data/widget/budget_percentage_over_total/:ine_code/:year/:code/:area/:kind' => 'data#budget_percentage_over_total', as: :data_budget_percentage_over_total
      get '/data/widget/budget_percentage_previous_year/:ine_code/:year/:code/:area/:kind' => 'data#budget_percentage_previous_year', as: :data_budget_percentage_previous_year
      get '/data/widget/population/:ine_code/:year' => 'data#population', as: :data_population
      get '/data/widget/ranking/:year/:kind/:area/:variable(/:code)' => 'data#ranking', as: :data_ranking
      get '/data/widget/total_widget_execution/:ine_code/:year' => 'data#total_budget_execution', as: :data_total_budget_execution
      get '/data/widget/budget_execution_deviation/:ine_code/:year/:kind' => 'data#budget_execution_deviation', as: :data_budget_execution_deviation
      get '/data/widget/debt/:ine_code/:year' => 'data#debt', as: :data_debt

      get '/data/widget/global_total_budget/:year' => 'global_data#total_budget', as: :global_data_total_budget
      get '/data/widget/global_total_budget_per_inhabitant/:year' => 'global_data#total_budget_per_inhabitant', as: :global_data_total_budget_per_inhabitant
      get '/data/widget/global_population/:year' => 'global_data#population', as: :global_data_population
      get '/data/widget/global_debt/:year' => 'global_data#debt', as: :global_data_debt
      get '/data/widget/global_total_budget_execution/:year' => 'global_data#total_budget_execution', as: :global_data_total_budget_execution

      get '/categories' => 'categories#index'
      get '/categories/:area/:kind' => 'categories#index'
      get '/places' => 'places#index'
      get '/data/:ine_code/:year/:kind/:area' => 'data#budgets'
      get '/data/debt/:year' => 'data#municipalities_debt'
      get '/data/population/:year' => 'data#municipalities_population'

      get '/intelligence/budget_lines/:ine_code/:years' => 'intelligence#budget_lines', as: :intelligence_budget_lines
      get '/intelligence/budget_lines_means/:ine_code/:year' => 'intelligence#budget_lines_means', as: :intelligence_budget_lines_means
    end

    # statics
    get 'about' => 'pages#about'
    get 'pro' => 'pages#pro'
    get 'request_access' => 'pages#request_access'
    get 'contact_pro' => redirect('/users/new')
    get 'contact_citizen' => redirect('/users/new')
    get 'faq' => 'pages#faq'
    get 'legal/cookies' => 'pages#legal_cookies'
    get 'legal/legal' => 'pages#legal_legal'
    get 'legal/privacy' => 'pages#legal_privacy'
    get 'en' => 'pages#en'

    get 'search' => 'search#index'
    get 'categories/:slug/:year/:area/:kind' => 'search#categories', as: :search_categories
    get 'geocoder' => 'geocoder#index', as: :geocoder
    get '/mapas/:year' => 'pages#map', as: :map

    get '/budget_lines/:slug/:year/:code/:kind/:area' => 'budget_lines#show', as: :budget_line
    get '/budget_lines/:slug/:year/:code/:kind/:area/feedback/:question_id' => 'budget_lines#feedback', as: :budget_line_feedback
    get '/places/:slug' => 'places#show'
    get '/places/:slug/inteligencia' => 'places#intelligence'
    get '/places/:slug/:year/execution' => 'places#execution', as: :place_execution
    get '/places/:slug/:year/debt' => 'places#debt_alive'
    get '/places/:slug/:year' => 'places#show', as: :place
    get '/places/:slug/:year/:kind/:area' => 'places#budget', as: :place_budget

    # compare
    get 'compare' => 'pages#compare', as: :compare
    get 'compare-new' => 'pages#compare-new'
    get '/compare/:slug_list/:year/:kind/:area' => 'places#compare', as: :places_compare

    get 'ranking' => 'pages#ranking'
    get '/ranking/:year/:kind/:area/:variable(/:code)' => 'places#ranking', as: :places_ranking
    get '/ranking/:year/population' => 'places#ranking', as: :population_ranking, defaults: {variable: 'population'}

    # feedback
    resources :answers, only: [:create]

    # follow place
    resources :subscriptions, only: [:create, :destroy]
  end
end
