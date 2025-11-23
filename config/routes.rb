require "sidekiq/web"

Rails.application.routes.draw do
  # ---------------------------------------------------------
  # Health check
  # ---------------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check

  # ---------------------------------------------------------
  # Sidekiq dashboard
  # ---------------------------------------------------------
  mount Sidekiq::Web => "/sidekiq"

  # ---------------------------------------------------------
  # Razorpay callback (webhook)
  # ---------------------------------------------------------
  post "/razorpay/callback", to: "spree/razorpay#razor_response"

  # ---------------------------------------------------------
  # Spree Auth Routes (User + Admin)
  # ---------------------------------------------------------
  Spree::Core::Engine.add_routes do
    # Storefront User Authentication (for customers)
    scope '(:locale)',
      locale: /#{Spree.available_locales.join('|')}/,
      defaults: { locale: nil } do

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

    # Admin Authentication
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

  # ---------------------------------------------------------
  # Mount Spree
  # ---------------------------------------------------------
  mount Spree::Core::Engine, at: '/'

  # ---------------------------------------------------------
  # Root path → Spree home
  # ---------------------------------------------------------
  root "spree/home#index"
end
