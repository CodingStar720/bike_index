Bikeindex::Application.routes.draw do

  get "dashboard/show"
  
  resources :organizations, only: [:show, :edit, :update, :destroy] do 
    member do
      get :embed
      get :embed_create_success
    end
    resources :memberships, only: [:edit, :update, :destroy]
    resources :organization_invitations, only: [:new, :create]
  end

  root to: 'welcome#index'

  match 'update_browser', to: 'welcome#update_browser'
  match 'user_home', to: 'welcome#user_home'
  match 'choose_registration', to: 'welcome#choose_registration'
  match 'goodbye', to: 'welcome#goodbye'
  
  resource :session, only: [:new, :create, :destroy]
  match 'logout', to: 'sessions#destroy'

  resource :charges, only: [:new, :create]
  resources :documentation, only: [:index] do
    collection { get :api_v1 }
  end


  resources :ownerships, only: [:show]
  resources :memberships, only: [:update, :destroy]

  resources :stolen_notifications, only: [:create, :new]

  resources :feedbacks, only: [:create, :new]
  match 'vendor_signup', to: 'feedbacks#vendor_signup'
  match 'contact', to: 'feedbacks#new'
  match 'contact_us', to: 'feedbacks#new'
  match 'help', to: 'feedbacks#index'

  resources :users, only: [:new, :create, :show, :edit, :update] do
    collection do
      get 'confirm'
      get 'request_password_reset'
      post 'password_reset'
      get 'password_reset'
      get 'update_password'
    end
  end
  match 'my_account', to: 'users#edit'
  match 'accept_vendor_terms', to: 'users#accept_vendor_terms'
  match "accept_terms", to: "users#accept_terms"  
  resources :bike_token_invitations, only: [:create]
  resources :user_embeds, only: [:show]

  resources :blogs, only: [:show, :index]
  match 'blog', to: redirect("/blogs")

  resources :public_images, only: [:create, :show, :edit, :update, :index, :destroy] do 
    collection do
      post :order
    end
  end
  
  resources :bikes do
    collection { get :scanned }
    member do
     get 'spokecard'
     get 'scanned'
     get 'pdf'
   end
  end
  resources :locks

  namespace :admin do
    root :to => 'dashboard#index'
    match 'invitations', to: 'dashboard#invitations'
    match 'maintenance', to: 'dashboard#maintenance'
    match 'bust_z_cache', to: 'dashboard#bust_z_cache'
    match 'destroy_example_bikes', to: 'dashboard#destroy_example_bikes'
    resources :discounts, :memberships, :bikes, :organizations, :bike_token_invitations, :organization_invitations
    match 'duplicate_bikes', to: 'bikes#duplicates'
    resources :flavor_texts, only: [:destroy, :create]
    resources :graphs, only: [:index, :show]
    resources :failed_bikes, only: [:index, :show]
    resources :ownerships, only: [:edit, :update]
    resources :stolen_notifications
    match 'recover_organization', to: 'organizations#recover' 
    match 'show_deleted_organizations', to: 'organizations#show_deleted' 
    resources :blogs, only: [:new, :create, :index, :edit, :update, :destroy]
    resources :ctypes, only: [:new, :create, :index, :edit, :update, :destroy] do 
      collection { post :import }
    end
    resources :manufacturers do 
      collection { post :import }
    end
    resources :users, only: [:index, :edit, :update, :destroy] do
      get :bike_tokens
      post :add_bike_tokens
    end
  end

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :bikes, only: [:index, :show, :create] do
        collection { get 'search_tags' }
      end
      resources :cycle_types, only: [:index]
      resources :wheel_sizes, only: [:index]
      resources :component_types, only: [:index]
      resources :colors, only: [:index]
      resources :handlebar_types, only: [:index]
      resources :frame_materials, only: [:index]
      resources :manufacturers, only: [:index]
      resources :users do 
        collection { get 'current' }
      end
    end
  end

  resources :manufacturers, only: [:show, :index]
  match 'manufacturers_mock_csv', to: 'manufacturers#mock_csv'

  resources :organization_deals, only: [:create, :new]
  resource :integrations, only: [:create]
  match '/auth/:provider/callback', :to => "integrations#create"

  %w[stolen_bikes protect_your_bike privacy terms serials about where roadmap security vendor_terms resources spokecard].each do |page|
    get page, controller: 'info', action: page
  end

  get 'sitemap.xml.gz' => redirect("https://s3.amazonaws.com/bikeindex/sitemaps/sitemap_index.xml.gz")
  # Somehow the redirect drops the .gz extension, which ruins it so this redirect is handled by Cloudflare
  # get "sitemaps/(*all)" => redirect("https://s3.amazonaws.com/bikeindex/sitemaps/%{all}")
  
  match '/400', to: 'errors#bad_request'
  match '/404', to: 'errors#not_found'
  match '/422', to: 'errors#unprocessable_entity'
  match '/500', to: 'errors#server_error'
  
  mount Resque::Server.new, :at => '/resque', :constraints => AdminRestriction
end
