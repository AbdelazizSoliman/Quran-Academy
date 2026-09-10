module PublicContent
  class FaqPresenter
    def self.wrap(records, locale:) = records.map { |record| new(record, locale:) }

    def initialize(record, locale:)
      (@record = record
       @locale = locale.to_s == "ar" ? "ar" : "en")
    end

    def question = @record.public_send(:"question_#{@locale}")
    def answer = @record.public_send(:"answer_#{@locale}")
  end
end
