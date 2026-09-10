module PublicContent
  class LegalPagePresenter
    TITLES = {
      "privacy" => { "en" => "Privacy Policy", "ar" => "سياسة الخصوصية" },
      "terms" => { "en" => "Terms & Conditions", "ar" => "الشروط والأحكام" },
      "refund" => { "en" => "Cancellation and Refund Policy", "ar" => "سياسة الإلغاء والاسترداد" }
    }.freeze

    def initialize(record, locale:)
      @record = record
      @locale = locale.to_s == "ar" ? "ar" : "en"
    end

    attr_reader :record

    delegate :page_type, :effective_date, to: :record

    def title = record.public_send(:"title_#{@locale}")
    def body = record.public_send(:"body_#{@locale}")

    def fallback_title = TITLES.fetch(page_type).fetch(@locale)
  end
end
