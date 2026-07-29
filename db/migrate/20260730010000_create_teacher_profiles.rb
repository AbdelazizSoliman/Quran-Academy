class CreateTeacherProfiles < ActiveRecord::Migration[8.1]
  def up
    create_table :teacher_profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }
      t.string :public_id, null: false
      t.string :display_name
      t.text :bio
      t.string :gender, null: false, default: "unspecified"
      t.date :date_of_birth
      t.string :nationality
      t.string :country_of_residence
      t.string :city
      t.string :phone_number
      t.string :whatsapp_number
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.string :highest_qualification
      t.text :qualification_details
      t.integer :years_of_teaching_experience, null: false, default: 0
      t.integer :quran_teaching_experience_years, null: false, default: 0
      t.string :tajweed_qualification
      t.string :ijazah_status, null: false, default: "none"
      t.text :ijazah_details
      t.string :teaching_languages, array: true, null: false, default: []
      t.string :student_age_groups, array: true, null: false, default: []
      t.string :teaching_specializations, array: true, null: false, default: []
      t.string :employment_status, null: false, default: "candidate"
      t.string :engagement_type, null: false, default: "contractor"
      t.string :profile_status, null: false, default: "draft"
      t.date :joined_on
      t.date :left_on
      t.decimal :default_lesson_rate, precision: 12, scale: 2, null: false, default: 0
      t.string :compensation_currency, null: false, default: "EGP"
      t.string :compensation_unit, null: false, default: "per_lesson"
      t.text :internal_notes
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    add_index :teacher_profiles, :public_id, unique: true
    add_index :teacher_profiles, :employment_status
    add_index :teacher_profiles, :engagement_type
    add_index :teacher_profiles, :profile_status
    add_index :teacher_profiles, :joined_on
    add_index :teacher_profiles, :teaching_languages, using: :gin
    add_index :teacher_profiles, :student_age_groups, using: :gin
    add_index :teacher_profiles, :teaching_specializations, using: :gin
    add_check_constraint :teacher_profiles, "years_of_teaching_experience >= 0",
                         name: "teacher_profiles_experience_nonnegative"
    add_check_constraint :teacher_profiles, "quran_teaching_experience_years >= 0",
                         name: "teacher_profiles_quran_experience_nonnegative"
    add_check_constraint :teacher_profiles, "default_lesson_rate >= 0",
                         name: "teacher_profiles_rate_nonnegative"
    add_check_constraint :teacher_profiles, "left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on",
                         name: "teacher_profiles_date_order"

    create_table :teacher_profile_events do |t|
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :teacher_profile_events, %i[teacher_profile_id created_at]
    add_index :teacher_profile_events, :event_type
  end

  def down
    drop_table :teacher_profile_events
    drop_table :teacher_profiles
  end
end
