require "rails_helper"

RSpec.describe "Admin website public content" do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "renders FAQ and testimonial list, new, and edit screens" do
    faq = create(:public_faq)
    testimonial = create(:public_testimonial)
    [admin_website_faqs_path, new_admin_website_faq_path, edit_admin_website_faq_path(faq),
     admin_website_testimonials_path, new_admin_website_testimonial_path,
     edit_admin_website_testimonial_path(testimonial)].each do |path|
      get path
      expect(response).to have_http_status(:ok)
    end
  end

  it "creates, edits, publishes, reorders, unpublishes, and deletes an FAQ" do
    post admin_website_faqs_path,
         params: { public_faq: { question_ar: "س", question_en: "Q", answer_ar: "ج", answer_en: "A", published: "1",
                                 public_display_order: 4, created_by_id: -1 } }
    faq = PublicFaq.last
    expect(response).to redirect_to(admin_website_faqs_path)
    expect(faq).to have_attributes(published: true, public_display_order: 4, created_by: admin, updated_by: admin)
    patch admin_website_faq_path(faq),
          params: { public_faq: { question_en: "Updated", published: "0", public_display_order: 1, updated_by_id: -1 } }
    expect(faq.reload).to have_attributes(question_en: "Updated", published: false, public_display_order: 1,
                                          updated_by: admin)
    expect { delete admin_website_faq_path(faq) }.to change(PublicFaq, :count).by(-1)
  end

  # rubocop:disable RSpec/ExampleLength
  it "creates and safely updates a testimonial without accepting internal associations" do
    post admin_website_testimonials_path,
         params: {
           public_testimonial: {
             author_name: "Parent A.", relationship: "Parent", quote_ar: "رأي", quote_en: "Quote",
             published: "1", public_display_order: 3, created_by_id: -1, guardian_id: 99
           }
         }
    testimonial = PublicTestimonial.last
    expect(testimonial).to have_attributes(created_by: admin, updated_by: admin, published: true)
    patch admin_website_testimonial_path(testimonial),
          params: {
            public_testimonial: { author_name: "", relationship: "Guardian", published: "0", public_display_order: 1,
                                  updated_by_id: -1 }
          }
    expect(testimonial.reload).to have_attributes(author_name: "", relationship: "Guardian", published: false,
                                                  public_display_order: 1, updated_by: admin)
    expect { delete admin_website_testimonial_path(testimonial) }.to change(PublicTestimonial, :count).by(-1)
  end
  # rubocop:enable RSpec/ExampleLength

  it "rejects incomplete bilingual publication" do
    post admin_website_faqs_path,
         params: { public_faq: { question_ar: "س", question_en: "", answer_ar: "ج", answer_en: "A", published: "1" } }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_website_testimonials_path,
         params: { public_testimonial: { relationship: "Parent", quote_ar: "رأي", quote_en: "", published: "1" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  %i[staff teacher student guardian].each do |role|
    it "forbids #{role} access" do
      sign_out admin
      sign_in create(:user, role)
      get admin_website_faqs_path
      expect(response).to have_http_status(:forbidden)
      get admin_website_testimonials_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "redirects anonymous access to sign in" do
    sign_out admin
    get admin_website_faqs_path
    expect(response).to redirect_to(new_user_session_path)
    get admin_website_testimonials_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
