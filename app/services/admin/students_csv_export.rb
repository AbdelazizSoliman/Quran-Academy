require "csv"

module Admin
  class StudentsCsvExport
    HEADERS = %w[
      public_id first_name last_name email display_name learning_status assigned_teacher country
      gender quran_level phone whatsapp guardian guardian_phone profile_completion
    ].freeze

    def initialize(profiles)
      @profiles = profiles
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        @profiles.find_each do |profile|
          guardian = primary_guardian(profile)
          csv << [
            profile.public_id, profile.user.first_name, profile.user.last_name, profile.user.email,
            profile.display_name, profile.learning_status, profile.assigned_teacher_profile&.display_name,
            profile.country_of_residence, profile.gender, profile.current_quran_level, profile.phone_number,
            profile.whatsapp_number, guardian&.full_name, guardian&.phone_number, profile.completion_percentage
          ]
        end
      end
    end

    private

    def primary_guardian(profile)
      link = profile.student_guardianships.find { |guardianship| guardianship.active? && guardianship.primary_contact? }
      link&.guardian
    end
  end
end
