require "rails_helper"

RSpec.describe "Design system showcase" do
  it "renders the reusable component variants in Arabic RTL" do
    get ui_path(locale: :ar)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')
    expect(response.body).to include('data-component="button"')
    expect(response.body).to include('data-variant="danger"')
    expect(response.body).to include('data-controller="dialog"')
    expect(response.body).to include('data-controller="dropdown"')
    expect(response.body).not_to include("translation missing")
  end

  it "renders the same showcase in English LTR" do
    get ui_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="en" dir="ltr">')
    expect(response.body).to include(I18n.t("ui.title", locale: :en))
  end
end
