module Teacher
  # Profile workspaces intentionally coordinate several registry-backed resources.
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  class StudentLearningProfilesController < BaseController
    before_action :set_student
    before_action :load_workspace, only: :show

    def show; end

    def update_section
      profile = StudentLearningProfiles::EnsureExists.new(actor: current_user, student_profile: @student).call
      return head(:forbidden) unless profile.errors.empty?

      section_key = params[:section_key].to_s
      section = StudentLearningProfiles::UpsertSection.new(actor: current_user, profile:, section_key:,
                                                           attributes: section_params).call
      persist_items(profile, section_key, section)
      if section.errors.empty?
        redirect_to teacher_student_learning_profile_path(@student, section: section_key),
                    notice: t("learning_profile.saved")
      else
        @profile = profile
        load_workspace
        flash.now[:alert] = section.errors.full_messages.to_sentence
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_student
      @student = StudentLearningProfiles::Access.new(current_user).student_scope.find(params.expect(:student_id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def load_workspace
      @profile = @student.student_learning_profile
      @section_key = params[:section].presence || StudentLearningProfileSectionRegistry.keys.first
      unless StudentLearningProfileSectionRegistry.fetch(@section_key)
        @section_key = StudentLearningProfileSectionRegistry.keys.first
      end
      @section_definition = StudentLearningProfileSectionRegistry.fetch(@section_key)
      @section = @profile&.sections&.find_by(section_key: @section_key)
      @items = @section ? @section.items.index_by(&:field_key) : {}
      @summary_items = if @profile
                         @profile.items.where(visibility: "internal")
                                 .where(field_key: %w[learning_preferences teaching_strategy support_needs
                                                      learning_challenges])
                                 .index_by(&:field_key)
                       else
                         {}
                       end
      @fields = StudentLearningProfileFieldRegistry.keys_for(@section_key).map do |key|
        [key, StudentLearningProfileFieldRegistry.fetch(@section_key, key)]
      end
      @observations = @student.student_observations.includes(:teacher_profile,
                                                             :scheduled_lesson).order(observed_at: :desc).limit(10)
      started = @profile ? @profile.sections.where.not(completion_state: "not_started").count : 0
      completed = @profile ? @profile.sections.where(completion_state: "complete").pluck(:section_key) : []
      required = StudentLearningProfileSectionRegistry::DEFINITIONS.count { |_key, value| value[:importance] == "must" }
      @completion = { started:, total: StudentLearningProfileSectionRegistry.keys.length,
                      required_completed: completed.count do |key|
                        StudentLearningProfileSectionRegistry.fetch(key)[:importance] == "must"
                      end, required: }
    end

    def persist_items(profile, section_key, section_record)
      values = params.fetch(:items, {}).permit(*StudentLearningProfileFieldRegistry.keys_for(section_key)).to_h
      section = profile.sections.find_by!(section_key:)
      values.each do |field_key, raw|
        type = StudentLearningProfileFieldRegistry.fetch(section_key, field_key).fetch(:value_type)
        value = type == "list" ? raw.to_s.split(/\s*,\s*|\n/).compact_blank : raw
        value = %w[1 true].include?(raw) if type == "boolean"
        next if value.blank? && value != false && value != 0

        item = StudentLearningProfiles::UpsertItem.new(actor: current_user, section:, field_key:,
                                                       attributes: { value: }).call
        section_record.errors.add(:base, item.errors.full_messages.to_sentence) if item.errors.any?
      end
    end

    def section_params
      params.fetch(:section, {}).permit(:completion_state)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
end
