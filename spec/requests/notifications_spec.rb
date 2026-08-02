require "rails_helper"

RSpec.describe "Notification Center" do
  it "allows administrators and read-only staff to view delivery history" do
    notification = create(:notification)
    sign_in notification.actor
    get admin_notifications_path
    expect(response).to have_http_status(:ok)

    sign_out notification.actor
    sign_in create(:user, :staff)
    get admin_notification_path(notification)
    expect(response).to have_http_status(:ok)
    get new_admin_notification_path
    expect(response).to have_http_status(:forbidden)
  end

  it "isolates student notification history" do
    student = create(:student_profile)
    own = create(:notification, recipient_user: student.user)
    other = create(:notification)
    sign_in student.user
    get student_notification_path(own)
    expect(response).to have_http_status(:ok)
    get student_notification_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "has no notification delete route" do
    expect { Rails.application.routes.recognize_path("/admin/notifications/1", method: :delete) }
      .to raise_error(ActionController::RoutingError)
  end
end
