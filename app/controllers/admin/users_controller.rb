module Admin
  class UsersController < BaseController
    before_action :set_user, except: %i[index new create]
    rescue_from Users::Operation::Forbidden, with: :operation_forbidden

    def index
      scope = UsersQuery.new(params:).call
      @pagy, @users = pagy(:offset, scope, limit: 15)
    end

    def show
      @events = @user.account_events.includes(:actor).order(created_at: :desc).limit(20)
    end

    def new
      @user = User.new(status: :pending, time_zone: "Cairo")
    end

    def edit; end

    def create
      @user = Users::Create.new(actor: current_user, attributes: create_params).call
      if @user.persisted?
        redirect_to admin_user_path(@user), notice: t("admin.users.messages.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @user = Users::Update.new(actor: current_user, user: @user, attributes: update_params).call
      if @user.errors.empty?
        redirect_to admin_user_path(@user), notice: t("admin.users.messages.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    Users::TransitionStatus::TRANSITIONS.each_key do |transition|
      define_method(transition) do
        Users::TransitionStatus.new(actor: current_user, user: @user, action: transition).call
        event = Users::TransitionStatus::TRANSITIONS.fetch(transition)[:event]
        redirect_to admin_user_path(@user), notice: t("admin.users.messages.#{event}")
      end
    end

    def edit_password; end

    def update_password
      @user = reset_password
      if @user.errors.empty?
        redirect_to admin_user_path(@user), notice: t("admin.users.messages.password_reset")
      else
        render :edit_password, status: :unprocessable_content
      end
    end

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def create_params
      params.expect(user: %i[
                      first_name last_name email role preferred_locale time_zone phone_number whatsapp_number
                    ])
    end

    def update_params
      params.expect(user: %i[first_name last_name email role preferred_locale time_zone])
    end

    def password_params
      params.expect(user: %i[password password_confirmation])
    end

    def reset_password
      Users::ResetPassword.new(
        actor: current_user, user: @user,
        password: password_params[:password],
        password_confirmation: password_params[:password_confirmation]
      ).call
    end

    def operation_forbidden(error)
      redirect_to admin_user_path(@user), alert: t("admin.users.errors.#{error.reason}")
    end
  end
end
