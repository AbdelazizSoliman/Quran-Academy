class CreateStudentLearningProfiles < ActiveRecord::Migration[8.1]
  SECTION_KEYS = %w[
    basic_information educational_quranic_background language_cultural_background faith_spiritual_context
    cognitive_traits_learning_preferences psychological_emotional_state self_regulation_behaviour
    personality_motivation interests_personal_culture family_social_context achievements_aspirations
    challenges_support_needs
  ].freeze
  COMPLETION_STATES = %w[not_started in_progress complete].freeze
  REVIEW_STATES = %w[unreviewed reviewed].freeze
  VALUE_TYPES = %w[text number boolean list date].freeze
  SENSITIVITY_LEVELS = %w[standard sensitive highly_sensitive].freeze
  VISIBILITY_LEVELS = %w[internal guardian_safe student_safe].freeze
  ITEM_SOURCES = %w[teacher_entry admin_entry observation].freeze
  OBSERVATION_CATEGORIES = %w[quran_reading memorization pronunciation tajweed attention engagement behaviour
                              motivation teaching_strategy other].freeze
  OBSERVATION_SOURCES = %w[teacher_entry admin_entry lesson].freeze
  EVENT_ACTIONS = %w[profile_created section_created section_updated item_created item_updated].freeze

  def change
    create_profiles
    create_sections
    create_items
    create_observations
    create_events
  end

  private

  def create_profiles
    create_table :student_learning_profiles do |t|
      t.string :public_id, null: false
      t.references :student_profile, null: false, foreign_key: true, index: { unique: true }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :student_learning_profiles, :public_id, unique: true
  end

  def create_sections
    create_table :student_learning_profile_sections do |t|
      t.references :student_learning_profile, null: false, foreign_key: true, index: false
      t.string :section_key, null: false
      t.string :completion_state, null: false, default: "not_started"
      t.string :review_state, null: false, default: "unreviewed"
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :student_learning_profile_sections, %i[student_learning_profile_id section_key],
              unique: true, name: "idx_learning_profile_sections_unique"
    add_check_constraint :student_learning_profile_sections, inclusion_constraint("section_key", SECTION_KEYS),
                         name: "learning_profile_sections_key"
    add_check_constraint :student_learning_profile_sections,
                         inclusion_constraint("completion_state", COMPLETION_STATES),
                         name: "learning_profile_sections_completion"
    add_check_constraint :student_learning_profile_sections, inclusion_constraint("review_state", REVIEW_STATES),
                         name: "learning_profile_sections_review"
    add_check_constraint :student_learning_profile_sections,
                         "(review_state = 'reviewed' AND reviewed_at IS NOT NULL AND reviewed_by_id IS NOT NULL) OR " \
                         "(review_state = 'unreviewed' AND reviewed_at IS NULL AND reviewed_by_id IS NULL)",
                         name: "learning_profile_sections_review_metadata"
  end

  def create_items
    create_table :student_learning_profile_items do |t|
      t.references :student_learning_profile_section, null: false, foreign_key: true, index: false
      t.string :field_key, null: false
      t.jsonb :value, null: false
      t.string :value_type, null: false
      t.string :sensitivity, null: false
      t.string :visibility, null: false
      t.string :source, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :student_learning_profile_items, %i[student_learning_profile_section_id field_key],
              unique: true, name: "idx_learning_profile_items_unique"
    add_check_constraint :student_learning_profile_items, inclusion_constraint("value_type", VALUE_TYPES),
                         name: "learning_profile_items_value_type"
    add_check_constraint :student_learning_profile_items, inclusion_constraint("sensitivity", SENSITIVITY_LEVELS),
                         name: "learning_profile_items_sensitivity"
    add_check_constraint :student_learning_profile_items, inclusion_constraint("visibility", VISIBILITY_LEVELS),
                         name: "learning_profile_items_visibility"
    add_check_constraint :student_learning_profile_items, inclusion_constraint("source", ITEM_SOURCES),
                         name: "learning_profile_items_source"
  end

  def create_observations
    create_table :student_observations do |t|
      t.references :student_profile, null: false, foreign_key: true, index: false
      t.references :teacher_profile, null: false, foreign_key: true, index: false
      t.references :scheduled_lesson, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :category, null: false
      t.text :observation, null: false
      t.datetime :observed_at, null: false
      t.string :visibility, null: false, default: "internal"
      t.string :sensitivity, null: false, default: "standard"
      t.string :source, null: false, default: "teacher_entry"
      t.timestamps
    end
    add_index :student_observations, %i[student_profile_id observed_at],
              name: "idx_student_observations_timeline"
    add_index :student_observations, %i[teacher_profile_id observed_at],
              name: "idx_teacher_observations_timeline"
    add_check_constraint :student_observations, inclusion_constraint("category", OBSERVATION_CATEGORIES),
                         name: "student_observations_category"
    add_check_constraint :student_observations, inclusion_constraint("sensitivity", SENSITIVITY_LEVELS),
                         name: "student_observations_sensitivity"
    add_check_constraint :student_observations, inclusion_constraint("visibility", VISIBILITY_LEVELS),
                         name: "student_observations_visibility"
    add_check_constraint :student_observations, inclusion_constraint("source", OBSERVATION_SOURCES),
                         name: "student_observations_source"
  end

  def create_events
    create_table :student_learning_profile_events do |t|
      t.references :student_learning_profile, null: false, foreign_key: true, index: false
      t.references :student_learning_profile_section, foreign_key: true
      t.references :student_learning_profile_item, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :field_key
      t.jsonb :previous_value
      t.jsonb :new_value
      t.string :source, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :student_learning_profile_events, %i[student_learning_profile_id created_at],
              name: "idx_learning_profile_events_history"
    add_check_constraint :student_learning_profile_events, inclusion_constraint("action", EVENT_ACTIONS),
                         name: "learning_profile_events_action"
    add_check_constraint :student_learning_profile_events, inclusion_constraint("source", ITEM_SOURCES),
                         name: "learning_profile_events_source"
  end

  def inclusion_constraint(column, values)
    quoted = values.map { |value| connection.quote(value) }.join(", ")
    "#{connection.quote_column_name(column)} IN (#{quoted})"
  end
end
