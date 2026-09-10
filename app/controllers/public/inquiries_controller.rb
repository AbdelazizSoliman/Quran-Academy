module Public
  class InquiriesController < BaseController
    private

    def new_inquiry(type)
      @inquiry = PublicInquiry.new(inquiry_type: type, preferred_locale: public_locale)
    end

    # rubocop:disable Metrics/MethodLength
    def submit_inquiry(type)
      @inquiry = PublicInquiry.new(inquiry_params.merge(
                                     inquiry_type: type, preferred_locale: public_locale,
                                     source: PublicInquiry::SOURCE
                                   ))
      return render("public/inquiries/success", status: :accepted) if @inquiry.website.present?

      if @inquiry.save
        PublicAnalytics::Tracker.call(event_type: "#{type}_submitted", request:, session:,
                                      locale: public_locale, source_path: analytics_source_path,
                                      inquiry_type: type, public_inquiry: @inquiry)
        return render("public/inquiries/success", status: :created)
      end

      render :new, status: :unprocessable_content
    end
    # rubocop:enable Metrics/MethodLength

    def inquiry_params
      params.expect(public_inquiry: %i[
                      name phone whatsapp_number email student_age preferred_schedule_notes
                      subject message website
                    ])
    end
  end
end
