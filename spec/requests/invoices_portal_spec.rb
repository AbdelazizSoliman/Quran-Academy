require "rails_helper"

RSpec.describe "Invoice portals" do
  let(:admin) { create(:user, :admin) }
  let(:student_user) { create(:user, :student, preferred_locale: "en") }
  let(:student) { create(:student_profile, :complete, user: student_user) }
  let!(:invoice) { create(:finance_invoice, :issued, student_profile: student, created_by: admin, updated_by: admin) }

  it "lets the billed student view and print an issued invoice" do
    sign_in student_user

    get student_invoice_path(invoice)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(invoice.public_id)

    get print_student_invoice_path(invoice)
    expect(response).to have_http_status(:ok)
  end

  it "does not expose another student's invoice" do
    sign_in create(:user, :student)

    get student_invoice_path(invoice)
    expect(response).to have_http_status(:not_found)
  end

  it "lets an active linked guardian access the invoice through its signed delivery URL" do
    guardian_user = create(:user, :guardian)
    guardian = create(:guardian, user: guardian_user, email: guardian_user.email)
    create(:student_guardianship, guardian:, student_profile: student)
    sign_in guardian_user

    get invoice_access_path(invoice.signed_id(purpose: :invoice_access))
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(invoice.public_id)
  end

  it "rejects a valid signed URL for an unrelated guardian" do
    guardian_user = create(:user, :guardian)
    create(:guardian, user: guardian_user, email: guardian_user.email)
    sign_in guardian_user

    get invoice_access_path(invoice.signed_id(purpose: :invoice_access))
    expect(response).to have_http_status(:not_found)
  end
end
