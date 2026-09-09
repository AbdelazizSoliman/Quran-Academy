module Public
  class InquiriesController < BaseController
    private

    def new_inquiry(type)
      @inquiry = PublicInquiry.new(inquiry_type: type, preferred_locale: public_locale)
    end

    def submit_inquiry(type)
      @inquiry = PublicInquiry.new(inquiry_params.merge(
                                     inquiry_type: type, preferred_locale: public_locale,
                                     source: PublicInquiry::SOURCE
                                   ))
      return render("public/inquiries/success", status: :accepted) if @inquiry.website.present?
      return render("public/inquiries/success", status: :created) if @inquiry.save

      render :new, status: :unprocessable_content
    end

    def inquiry_params
      params.expect(public_inquiry: %i[
                      name phone whatsapp_number email student_age preferred_schedule_notes
                      subject message website
                    ])
    end
  end
end
