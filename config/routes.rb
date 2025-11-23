require "sidekiq/web"

Rails.application.routes.draw do
  # ✅ Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # ✅ Sidekiq dashboard
  mount Sidekiq::Web => "/sidekiq"

  # Callback endpoint for Spree to process order
  post "/razorpay/callback", to: "spree/razorpay#razor_response"

  # ✅ Spree routes and authentication setup
  Spree::Core::Engine.add_routes do
    # Storefront user authentication
    scope '(:locale)', locale: /#{Spree.available_locales.join('|')}/, defaults: { locale: nil } do
      devise_for(
        Spree.user_class.model_name.singular_route_key,
        class_name: Spree.user_class.to_s,
        path: :user,
        controllers: {
          sessions: 'spree/user_sessions',
          passwords: 'spree/user_passwords',
          registrations: 'spree/user_registrations'
        },
        router_name: :spree
      )
    end
    
    # 👉 Razorpay routes
    namespace :razorpay do
      post "checkout", to: "razorpay#checkout", as: :checkout
      post "callback", to: "razorpay#callback", as: :callback
    end
    
    # Admin authentication
    devise_for(
      Spree.admin_user_class.model_name.singular_route_key,
      class_name: Spree.admin_user_class.to_s,
      controllers: {
        sessions: 'spree/admin/user_sessions',
        passwords: 'spree/admin/user_passwords'
      },
      skip: :registrations,
      path: :admin_user,
      router_name: :spree
    )
  end

  # ✅ Mount Spree engine (main storefront + admin)
  mount Spree::Core::Engine, at: '/'

  # ✅ Default root path (Spree home)
  root "spree/home#index"
end
