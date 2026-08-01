Rails.application.routes.draw do
  devise_for :users,
             path: "account",
             path_names: { sign_in: "sign-in", sign_out: "sign-out", password: "password" },
             skip: :registrations
  namespace :admin do
    resources :programs, except: :destroy do
      member do
        patch :activate
        patch :deactivate
        patch :archive
        patch :restore
      end
    end
    resources :course_offerings, except: :destroy do
      member do
        patch :open
        patch :close
        patch :start
        patch :complete
        patch :cancel
        patch :archive
        patch :restore
      end
    end
    resources :enrollments, except: :destroy do
      member do
        patch :approve
        patch :waitlist
        patch :reject
        patch :activate
        patch :pause
        patch :resume
        patch :complete
        patch :withdraw
        patch :cancel
        patch :transfer
        patch :complete_placement
        patch :waive_placement
      end
    end
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
    resources :teacher_availabilities, except: :destroy do
      member do
        patch :activate
        patch :deactivate
        patch :archive
      end
    end
    resources :teacher_availability_exceptions, except: :destroy do
      member do
        patch :cancel
        patch :archive
      end
    end
    resources :scheduled_lessons, except: :destroy do
      member do
        patch :schedule
        patch :start
        patch :complete
        patch :cancel
        get :reschedule
        patch :apply_reschedule
        patch :archive
        patch :check_in_teacher
        patch :lock_attendance
        patch :reopen_attendance
        get :attendance
      end
      resources :participants, only: %i[create update], controller: :scheduled_lesson_participants
      resources :lesson_attendances, only: [] do
        member do
          patch :record_arrival
          patch :mark_present
          patch :mark_absent
          patch :excuse
          patch :record_departure
          patch :adjust
        end
      end
    end
    resources :lesson_attendances, only: :index
  end
  namespace :teacher do
    resource :profile, only: %i[show edit update], controller: :profiles
    resources :availabilities, only: %i[index new create edit update]
    resources :availability_exceptions, only: %i[index new create edit update]
    resources :schedule, only: %i[index show] do
      member do
        patch :check_in
        patch :start
        patch :complete
        get :attendance
      end
      resources :lesson_attendances, only: [], controller: :lesson_attendances do
        member do
          patch :record_arrival
          patch :mark_present
          patch :mark_absent
          patch :excuse
          patch :record_departure
        end
      end
    end
  end
  namespace :student do
    resource :profile, only: %i[show edit update], controller: :profiles
    resources :enrollments, only: %i[index show]
    resources :schedule, only: %i[index show]
    resources :attendances, only: %i[index show]
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
