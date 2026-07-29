class CreateStudentAndGuardianProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :student_profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }
      t.string :public_id, null: false
      t.string :display_name
      t.string :gender, null: false, default: "unspecified"
      t.date :date_of_birth
      t.string :nationality
      t.string :country_of_residence
      t.string :city
      t.string :phone_number
      t.string :whatsapp_number
      t.string :preferred_contact_method, null: false, default: "email"
      t.string :preferred_interface_locale, null: false, default: "en"
      t.string :preferred_learning_language
      t.string :native_language
      t.string :current_quran_level, null: false, default: "beginner"
      t.string :reading_level, null: false, default: "not_started"
      t.string :tajweed_level, null: false, default: "none"
      t.string :memorization_level, null: false, default: "none"
      t.text :memorized_surahs
      t.integer :memorized_juz_count
      t.text :learning_goals
      t.text :learning_notes
      t.text :special_learning_needs
      t.text :medical_notes
      t.text :safeguarding_notes
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.string :student_type, null: false, default: "adult"
      t.string :profile_status, null: false, default: "draft"
      t.string :learning_status, null: false, default: "prospective"
      t.date :joined_on
      t.date :left_on
      t.text :internal_notes
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :student_profiles, :public_id, unique: true
    add_index :student_profiles, :student_type
    add_index :student_profiles, :profile_status
    add_index :student_profiles, :learning_status
    add_index :student_profiles, :joined_on
    add_index :student_profiles, :date_of_birth
    add_index :student_profiles, :preferred_learning_language
    add_check_constraint :student_profiles, "memorized_juz_count IS NULL OR memorized_juz_count BETWEEN 0 AND 30",
                         name: "student_profiles_juz_range"
    add_check_constraint :student_profiles, "left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on",
                         name: "student_profiles_date_order"

    create_table :guardians do |t|
      t.string :public_id, null: false
      t.string :full_name, null: false
      t.string :gender, null: false, default: "unspecified"
      t.string :email
      t.string :phone_number
      t.string :whatsapp_number
      t.string :preferred_contact_method, null: false, default: "email"
      t.string :preferred_language, null: false, default: "ar"
      t.string :country
      t.string :city
      t.string :occupation
      t.string :status, null: false, default: "active"
      t.text :internal_notes
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :guardians, :public_id, unique: true
    add_index :guardians, :status
    add_index :guardians, :preferred_contact_method
    add_index :guardians, "lower(email)", name: "index_guardians_on_lower_email"

    create_table :student_guardianships do |t|
      t.references :student_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :guardian, null: false, foreign_key: { on_delete: :restrict }
      t.string :relationship_type, null: false
      t.string :custom_relationship
      t.boolean :primary_contact, null: false, default: false
      t.boolean :emergency_contact, null: false, default: false
      t.boolean :legal_guardian, null: false, default: false
      t.boolean :can_make_academic_decisions, null: false, default: false
      t.boolean :receives_academic_updates, null: false, default: true
      t.boolean :receives_billing_updates, null: false, default: false
      t.string :status, null: false, default: "active"
      t.date :starts_on
      t.date :ends_on
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :student_guardianships, %i[student_profile_id guardian_id status],
              name: "idx_guardianships_student_guardian_status"
    add_index :student_guardianships, %i[student_profile_id primary_contact],
              name: "idx_guardianships_primary_lookup"
    add_index :student_guardianships, :status
    add_index :student_guardianships, %i[student_profile_id guardian_id relationship_type],
              unique: true, where: "status = 'active'", name: "idx_unique_active_guardianship"
    add_index :student_guardianships, :student_profile_id,
              unique: true, where: "primary_contact AND status = 'active'",
              name: "idx_one_active_primary_guardian"
    add_check_constraint :student_guardianships,
                         "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on",
                         name: "student_guardianships_date_order"

    create_event_table :student_profile_events, :student_profile
    create_event_table :guardian_events, :guardian
    create_event_table :student_guardianship_events, :student_guardianship
  end

  private

  def create_event_table(table_name, target)
    create_table table_name do |t|
      t.references target, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index table_name, [:"#{target}_id", :created_at]
    add_index table_name, :event_type
  end
end
