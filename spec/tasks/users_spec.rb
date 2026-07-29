require "rails_helper"
require "rake"

RSpec.describe "users:create_admin" do
  subject(:task) { Rake::Task["users:create_admin"] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("users:create_admin")
    task.reenable
  end

  around do |example|
    original = ENV.to_h.slice("ADMIN_EMAIL", "ADMIN_PASSWORD", "ADMIN_FIRST_NAME", "ADMIN_LAST_NAME")
    example.run
  ensure
    %w[ADMIN_EMAIL ADMIN_PASSWORD ADMIN_FIRST_NAME ADMIN_LAST_NAME].each { |key| ENV.delete(key) }
    original.each { |key, value| ENV[key] = value }
  end

  it "creates an active Arabic administrator without printing the password" do
    set_admin_environment
    original_count = User.count

    expect { task.invoke }.to output(/\A(?!.*NotPrinted123!).*admin@example\.test.*\z/m).to_stdout
    expect(User.count).to eq(original_count + 1)

    user = User.find_by!(email: "admin@example.test")
    expect(user).to be_admin
    expect(user).to be_active
    expect(user.preferred_locale).to eq("ar")
    expect(user.time_zone).to eq("Cairo")
  end

  it "fails clearly when required values are missing" do
    expect { task.invoke }.to raise_error(RuntimeError, /Missing required environment variables/)
  end

  it "does not change an existing account or print a password" do
    set_admin_environment
    create(:user, email: ENV.fetch("ADMIN_EMAIL"))
    original_count = User.count

    expect { task.invoke }.to raise_error(RuntimeError, /already exists/)
    expect(User.count).to eq(original_count)
  end

  def set_admin_environment
    ENV.update(
      "ADMIN_EMAIL" => "admin@example.test",
      "ADMIN_PASSWORD" => "NotPrinted123!",
      "ADMIN_FIRST_NAME" => "Foundation",
      "ADMIN_LAST_NAME" => "Administrator"
    )
  end
end
