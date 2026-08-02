Rails.application.routes.draw do
  get "account/invitation/:token", to: "account_invitations#edit", as: :edit_account_invitation
  patch "account/invitation/:token", to: "account_invitations#update", as: :account_invitation
  get "account/invitation-success", to: "account_invitations#success", as: :account_invitation_success
  devise_for :users,
             path: "account",
             path_names: { sign_in: "sign-in", sign_out: "sign-out", password: "password" },
             skip: :registrations
  namespace :admin do
    resources :notifications, only: %i[index show new create] do
      member { patch :retry_delivery }
      collection do
        post :send_account_invitation
        post :send_lesson_reminder
        post :send_lesson_report
        post :send_certificate
      end
    end
    resources :assessment_templates, except: :destroy do
      resources :rubric_items, only: %i[create update], controller: :assessment_rubric_items
    end
    resources :assessment_categories, except: :destroy
    resources :student_assessments, except: :destroy do
      member do
        patch :submit
        patch :review
        patch :publish
        patch :archive
      end
    end
    resources :exam_sessions, except: :destroy do
      member do
        patch :schedule
        patch :complete
        patch :review
        patch :publish
        patch :archive
      end
    end
    resources :certificates, only: %i[index show new create]
    resources :student_progresses, only: %i[index show update]
    get "academic_dashboard", to: "academic_dashboard#show"
    resources :account_invitations, only: %i[index show] do
      member do
        patch :resend
        patch :cancel
      end
    end
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
    resources :lesson_reports, only: %i[index show edit update] do
      member do
        patch :review
        patch :lock
        patch :reopen
        patch :relock
      end
      resources :student_reports, only: %i[edit update], controller: :lesson_student_reports
      resources :communications, only: :create, controller: :communications
    end
    resources :communication_logs, only: %i[index show] do
      member do
        patch :mark_opened
        patch :confirm_sent
        patch :cancel
      end
    end
    resources :teacher_payrolls, except: :destroy do
      member do
        patch :prepare
        patch :approve
        patch :mark_paid
        patch :reopen
        patch :cancel
      end
    end
    resources :operational_reports, only: %i[index show], param: :report do
      get :export, on: :member
    end
  end
  namespace :teacher do
    resources :notifications, only: %i[index show create]
    resources :assessments, controller: :student_assessments, except: :destroy do
      patch :submit, on: :member
    end
    resources :exams, controller: :exam_sessions, only: %i[index show] do
      patch :complete, on: :member
    end
    resource :academic_dashboard, only: :show
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
      resource :report, only: %i[show edit update], controller: :lesson_reports do
        patch :submit
        resources :students, only: %i[edit update], controller: :lesson_student_reports
        resources :communications, only: :create, controller: :communications
      end
    end
    resources :communication_logs, only: :show do
      member do
        patch :mark_opened
        patch :confirm_sent
        patch :cancel
      end
    end
    resources :payrolls, only: %i[index show]
    resource :reports, only: :show, controller: :reports
  end
  namespace :student do
    resources :notifications, only: %i[index show]
    resources :assessments, only: %i[index show]
    resources :certificates, only: %i[index show]
    resource :transcript, only: :show
    resource :progress, only: :show
    resource :profile, only: %i[show edit update], controller: :profiles
    resources :enrollments, only: %i[index show]
    resources :schedule, only: %i[index show]
    resources :attendances, only: %i[index show]
    resources :reports, only: %i[index show]
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
