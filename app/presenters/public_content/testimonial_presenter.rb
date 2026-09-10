module PublicContent
  class TestimonialPresenter
    def self.wrap(records, locale:) = records.map { |record| new(record, locale:) }

    def initialize(record, locale:)
      (@record = record
       @locale = locale.to_s == "ar" ? "ar" : "en")
    end

    def quote = @record.public_send(:"quote_#{@locale}")
    def author_label = @record.author_name.presence || @record.relationship
    delegate :relationship, to: :@record
  end
end
