module PublicCatalog
  # Wraps a Program row loaded through PublicCatalog::ProgramsQuery and exposes only the
  # attributes approved for public display, already localized for the requested locale.
  class ProgramPresenter
    def self.wrap(programs, locale:)
      programs.map { |program| new(program, locale:) }
    end

    def initialize(program, locale:)
      @program = program
      @locale = locale.to_s == "ar" ? "ar" : "en"
    end

    attr_reader :locale

    delegate :estimated_duration_weeks, to: :program

    def slug = localized(:slug)
    def name = localized(:name)
    def short_description = localized(:short_description)
    def description = localized(:description)
    def featured? = program.public_featured?
    def category_label = I18n.t("academic.catalogs.program_categories.#{program.category}")
    def entry_level_label = I18n.t("academic.catalogs.levels.#{program.entry_level}")
    def completion_level_label = I18n.t("academic.catalogs.levels.#{program.completion_level}")
    def lesson_duration_minutes = program.default_lesson_duration_minutes
    def lessons_per_week = program.recommended_lessons_per_week
    def placement_required? = program.requires_placement?

    def age_group_labels
      program.target_age_groups.map { |group| I18n.t("academic.catalogs.age_groups.#{group}") }
    end

    def language_labels
      program.supported_learning_languages.map { |language| I18n.t("public.programs.languages.#{language}") }
    end

    private

    attr_reader :program

    def localized(attribute) = program.public_send(:"#{attribute}_#{locale}").presence
  end
end
