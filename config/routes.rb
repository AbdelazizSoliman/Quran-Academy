Rails.application.routes.draw do
  get "webhooks/whatsapp", to: "webhooks/whatsapp#verify"
  post "webhooks/whatsapp", to: "webhooks/whatsapp#receive"
  get "account/invitation/:token", to: "account_invitations#edit", as: :edit_account_invitation
  patch "account/invitation/:token", to: "account_invitations#update", as: :account_invitation
  get "account/invitation-success", to: "account_invitations#success", as: :account_invitation_success
  devise_for :users,
             path: "account",
             path_names: { sign_in: "sign-in", sign_out: "sign-out", password: "password" },
             skip: :registrations
  get "invoices/:token", to: "invoice_access#show", as: :invoice_access
  get "invoices/:token/print", to: "invoice_access#print", as: :print_invoice_access
  namespace :admin do
    resource :public_website, only: %i[edit update], controller: :public_website_settings
    namespace :website do
      resources :leads, only: %i[index show update]
      resources :programs, only: %i[index edit update]
      resources :fee_plans, path: "fees", only: %i[index edit update]
    end
    resources :whatsapp_conversations, only: %i[index show] do
      member do
        patch :archive
        patch :reopen
      end
    end
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
    get "financial_dashboard", to: "financial_dashboard#show"
    resources :finance_invoices, path: "finance/invoices", only: %i[index show new create edit update] do
      member do
        patch :issue
        patch :cancel
        post :deliver
        get :print
      end
      resources :payments, controller: :finance_payments, only: :create do
        patch :refund, on: :member
      end
    end
    resources :finance_expenses, path: "finance/expenses", only: %i[index show new create] do
      member do
        patch :approve
        patch :pay
        patch :cancel
      end
    end
    resources :finance_ledger_entries, path: "finance/ledger", only: :index
    resources :financial_reports, path: "finance/reports", only: %i[index show], param: :report do
      get :export, on: :member
    end
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
    resources :fee_plans, only: %i[index create edit update destroy]
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
      resources :lesson_schedules, only: %i[index new create show], controller: :enrollment_lesson_schedules do
        member do
          get :new_change
          post :apply_change
          patch :cancel
        end
      end
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
      collection do
        get :import
        post :import, action: :import_create
        get :export
      end
      member do
        patch :verify
        patch :archive
        patch :restore
      end
    end
    resources :students, except: :destroy do
      collection do
        get :import
        post :import, action: :import_create
        get :export
      end
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
    resources :users do
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
      member do
        get :evaluate
        patch :submit
      end
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
        get :join
        patch :check_in
        patch :start
        patch :complete
        get :attendance
        get :evaluations, to: "lesson_evaluations#show"
        patch :submit_evaluations, to: "lesson_evaluations#submit"
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
    resources :attendances, only: :index
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
    resources :invoices, only: %i[index show] do
      get :print, on: :member
    end
    resources :notifications, only: %i[index show]
    resources :assessments, only: %i[index show]
    resources :certificates, only: %i[index show]
    resource :transcript, only: :show
    resource :progress, only: :show
    resource :profile, only: %i[show edit update], controller: :profiles
    resources :enrollments, only: %i[index show]
    resources :schedule, only: %i[index show] do
      get :join, on: :member
    end
    resources :attendances, only: %i[index show]
    resources :reports, only: %i[index show]
  end
  namespace :parent, path: "guardian", as: "guardian" do
    resources :invoices, only: %i[index show] do
      get :print, on: :member
    end
    resource :profile, only: :show, controller: :profiles
    resources :students, only: %i[index show]
    resources :schedule, only: %i[index show]
    resources :attendances, only: :index
    resources :reports, only: :index
    resources :notifications, only: :index
  end
  get "dashboard", to: "dashboard#index", as: :dashboard
  root "public/home#show"
  get ":locale", to: "public/home#show", as: :localized_public_home,
                 constraints: { locale: /ar|en/ }
  scope ":locale", module: "public", as: :public, constraints: { locale: /ar|en/ } do
    get "programs", to: "programs#index", as: :programs
    get "programs/:slug", to: "programs#show", as: :program
    get "fees", to: "fees#index", as: :fees
    get "trial", to: "trial_requests#new", as: :trial
    post "trial", to: "trial_requests#create"
    get "contact", to: "contact_requests#new", as: :contact
    post "contact", to: "contact_requests#create"
  end
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
