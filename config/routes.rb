Rails.application.routes.draw do
  devise_for :users,
             path: "account",
             path_names: { sign_in: "sign-in", sign_out: "sign-out", password: "password" },
             skip: :registrations
  namespace :admin do
    resource :settings, only: %i[show edit update], controller: :academy_settings
    resources :teachers, except: :destroy do
      member do
        patch :verify
        patch :archive
        patch :restore
      end
    end
    resources :students, except: :destroy do
      member do
        patch :verify
        patch :archive
        patch :restore
      end
      resources :guardianships, only: %i[create update], controller: :student_guardianships do
        post :create_guardian, on: :collection
        member do
          patch :make_primary
          patch :end
          patch :restore
        end
      end
    end
    resources :guardians, except: :destroy do
      member do
        patch :archive
        patch :restore
      end
    end
    resources :users, except: :destroy do
      member do
        patch :approve
        patch :suspend
        patch :activate
        patch :disable
        patch :enable
        get :reset_password, action: :edit_password
        patch :reset_password, action: :update_password
      end
    end
  end
  namespace :teacher do
    resource :profile, only: %i[show edit update], controller: :profiles
  end
  namespace :student do
    resource :profile, only: %i[show edit update], controller: :profiles
  end
  root "dashboard#index"
  constraints LocalEnvironmentConstraint.new do
    get "ui", to: "ui#index", as: :ui
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
