require "csv"

module Admin
  class TeachersCsvExport
    HEADERS = %w[
      public_id first_name last_name email display_name utilization_percentage assigned_students
      account_status employment_status profile_status gender country teaching_languages specializations
      compensation_unit default_lesson_rate compensation_currency
    ].freeze

    def initialize(profiles, metrics:)
      @profiles = profiles
      @metrics = metrics
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        @profiles.each do |profile|
          metric = @metrics.fetch(profile, {})
          csv << [
            profile.public_id, profile.user.first_name, profile.user.last_name, profile.user.email,
            profile.display_name, metric[:utilization_percentage], metric[:assigned_students_count],
            profile.user.status, profile.employment_status, profile.profile_status, profile.gender,
            profile.country_of_residence, profile.teaching_languages.join(";"),
            profile.teaching_specializations.join(";"), profile.compensation_unit,
            profile.default_lesson_rate, profile.compensation_currency
          ]
        end
      end
    end
  end
end
