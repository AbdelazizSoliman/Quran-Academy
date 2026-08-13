require "csv"

module Admin
  class TeachersCsvImport
    Result = Data.define(:created_count, :errors)
    ALLOWED_KEYS = Admin::TeachersController::ONBOARDING_KEYS.flat_map { |key| key.is_a?(Hash) ? key.keys : key }
                                                              .map(&:to_s).freeze

    def initialize(actor:, io:)
      @actor = actor
      @io = io
    end

    def call
      created_count = 0
      errors = []

      CSV.new(@io, headers: true, header_converters: ->(header) { header.to_s.strip.downcase }).each.with_index(2) do |row, line|
        attributes = normalized_attributes(row.to_h.slice(*ALLOWED_KEYS).compact_blank)
        profile = Admin::Onboarding::CreateTeacher.new(actor: @actor, attributes:).call
        if profile.persisted? && profile.errors.empty?
          created_count += 1
        else
          errors << { line:, messages: profile.errors.full_messages }
        end
      rescue CSV::MalformedCSVError => e
        errors << { line:, messages: [e.message] }
      end

      Result.new(created_count:, errors:)
    end

    private

    def normalized_attributes(attributes)
      return attributes unless attributes["work_days"].present?

      attributes.merge("work_days" => attributes["work_days"].split(/[;,|]/).map(&:strip).reject(&:blank?))
    end
  end
end
