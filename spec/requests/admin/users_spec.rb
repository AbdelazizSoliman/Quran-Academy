require "rails_helper"

RSpec.describe "Admin user administration" do
  let(:admin) { create(:user, :admin) }

  it "redirects unauthenticated requests to sign in" do
    get admin_users_path

    expect(response).to redirect_to(new_user_session_path)
  end

  %i[staff teacher student].each do |role|
    it "forbids an active #{role}" do
      sign_in create(:user, role)
      get admin_users_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  %i[pending suspended disabled].each do |status|
    it "does not authenticate a #{status} administrator" do
      sign_in create(:user, :admin, status)
      get admin_users_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "renders a localized, filtered admin index and navigation" do
    admin.update!(preferred_locale: "en")
    sign_in admin
    create(:user, :student, first_name: "Unique", preferred_locale: "en")

    get admin_users_path, params: { query: "Unique", role: "student", preferred_locale: "en", locale: "en" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Unique", "User administration", 'dir="ltr"')
    expect(response.body).to include(admin_users_path)
    expect(response.body).not_to include("translation missing")
  end

  it "renders Arabic RTL and an empty state" do
    sign_in admin
    get admin_users_path, params: { query: "does-not-exist" }

    expect(response.body).to include('dir="rtl"', I18n.t("admin.users.empty.title", locale: :ar))
  end

  it "creates a user and audit event with strong parameters" do
    sign_in admin
    attributes = attributes_for(:user, :teacher).merge(
      password: "SecurePass123!", password_confirmation: "SecurePass123!",
      phone_number: "+20 100-123-4567", whatsapp_number: "", sign_in_count: 999,
      encrypted_password: "unsafe"
    )

    expect { post admin_users_path, params: { user: attributes } }.to change(User, :count).by(1)
    expect(UserAccountEvent.where(event_type: "created").count).to eq(1)
    user = User.order(:created_at).last
    expect(user.sign_in_count).to eq(0)
    expect(user.teacher_profile.whatsapp_number).to eq("+201001234567")
  end

  it "rejects duplicate email and weak passwords without an audit" do
    sign_in admin
    existing = create(:user)
    attributes = attributes_for(:user, email: existing.email, password: "weak", password_confirmation: "weak",
                                       phone_number: "+201001234567")

    expect do
      post admin_users_path, params: { user: attributes }
    end.not_to change(UserAccountEvent, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "renders localized contact errors without treating profile fields as User attributes" do
    sign_in admin

    post admin_users_path, params: {
      user: attributes_for(:user, :teacher).merge(phone_number: "invalid", whatsapp_number: "")
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("admin.users.errors.phone_number_invalid"))
  end

  it "updates safe fields but cannot mass assign security internals or status" do
    sign_in admin
    user = create(:user)

    patch admin_user_path(user), params: {
      user: { first_name: "Updated", preferred_locale: "en", time_zone: "London",
              status: "disabled", sign_in_count: 900 }
    }

    user.reload
    expect(user.first_name).to eq("Updated")
    expect(user.preferred_locale).to eq("en")
    expect(user.time_zone).to eq("London")
    expect(user).to be_active
    expect(user.sign_in_count).to eq(0)
  end

  it "allows only the designated administrator to force-delete another user" do
    privileged = create(:user, :admin, email: Admin::Users::ForceDelete::PRIVILEGED_EMAIL)
    target = create(:user, :pending)
    sign_in privileged

    expect { delete admin_user_path(target) }.to change(User, :count).by(-1)
    expect(response).to redirect_to(admin_users_path)
  end

  it "rejects force deletion by every other administrator" do
    sign_in admin
    target = create(:user, :pending)

    expect { delete admin_user_path(target) }.not_to change(User, :count)
    expect(response).to redirect_to(admin_user_path(target))
  end

  it "approves a pending user and shows audit history" do
    sign_in admin
    user = create(:user, :pending)

    patch approve_admin_user_path(user)
    get admin_user_path(user)

    expect(user.reload).to be_active
    expect(response.body).to include(I18n.t("admin.audit.events.approved", actor: admin.full_name))
    expect(response.body).to include('data-controller="dialog"')
  end

  it "handles all explicit transition endpoints and rejects repeated requests safely" do
    sign_in admin
    user = create(:user)

    patch suspend_admin_user_path(user)
    patch activate_admin_user_path(user)
    patch disable_admin_user_path(user)
    patch enable_admin_user_path(user)
    patch enable_admin_user_path(user)

    expect(response).to redirect_to(admin_user_path(user))
    follow_redirect!
    expect(response.body).to include(I18n.t("admin.users.errors.invalid_transition"))
  end

  it "resets another account password while GET remains read-only" do
    sign_in admin
    user = create(:user, password: "Original123!", password_confirmation: "Original123!")
    encrypted = user.encrypted_password

    get reset_password_admin_user_path(user)
    expect(user.reload.encrypted_password).to eq(encrypted)

    patch reset_password_admin_user_path(user), params: {
      user: { password: "Replacement123!", password_confirmation: "Replacement123!" }
    }
    expect(user.reload.valid_password?("Replacement123!")).to be(true)
    expect(user.account_events.last.metadata.to_s).not_to match(/password/i)
  end

  it "invalidates an existing target session after suspension" do
    target = create(:user)
    sign_in target
    get root_path
    original_version = target.session_version
    Admin::Users::TransitionStatus.new(actor: admin, user: target, action: :suspend).call

    get root_path

    expect(target.reload.session_version).to eq(original_version + 1)
    expect(response).to redirect_to(new_user_session_path)
  end

  it "has no destroy route and public registration remains unavailable" do
    delete admin_user_path(create(:user))
    expect(response).to have_http_status(:not_found)
    get "/account/sign-up"
    expect(response).to have_http_status(:not_found)
  end
end
