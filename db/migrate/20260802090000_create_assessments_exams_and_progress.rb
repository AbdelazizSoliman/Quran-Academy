class CreateAssessmentsExamsAndProgress < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_settings, :assessment_grade_boundaries, :jsonb, null: false,
                                                                        default: { "A+" => 95, "A" => 90,
                                                                                   "B+" => 85, "B" => 80,
                                                                                   "C" => 70, "D" => 60,
                                                                                   "F" => 0 }

    create_assessment_templates
    create_assessment_categories
    create_assessment_rubric_items
    create_student_assessments
    create_assessment_scores
    create_student_progresses
    create_exam_sessions
    create_certificates
    create_audit_tables
  end

  private

  def create_assessment_templates
    create_table :assessment_templates do |t|
      t.string :public_id, null: false
      t.string :name_ar, null: false
      t.string :name_en, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.integer :display_order, null: false, default: 0
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_templates, :public_id, unique: true
    add_index :assessment_templates, %i[status display_order]
    add_check_constraint :assessment_templates, "status IN ('active','inactive','archived')",
                         name: "assessment_template_status"
  end

  def create_assessment_categories
    create_table :assessment_categories do |t|
      t.string :public_id, null: false
      t.string :code, null: false
      t.string :name_ar, null: false
      t.string :name_en, null: false
      t.boolean :active, null: false, default: true
      t.integer :display_order, null: false, default: 0
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_categories, :public_id, unique: true
    add_index :assessment_categories, :code, unique: true
    add_index :assessment_categories, %i[active display_order]
  end

  def create_assessment_rubric_items
    create_table :assessment_rubric_items do |t|
      t.references :assessment_template, null: false, foreign_key: { on_delete: :restrict }
      t.references :assessment_category, null: false, foreign_key: { on_delete: :restrict }
      t.string :name_ar, null: false
      t.string :name_en, null: false
      t.string :scoring_type, null: false, default: "numeric"
      t.decimal :maximum_score, precision: 7, scale: 2, null: false, default: 100
      t.decimal :weight, precision: 7, scale: 2, null: false, default: 1
      t.integer :display_order, null: false, default: 0
      t.boolean :required, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_rubric_items, %i[assessment_template_id display_order],
              name: "idx_rubrics_template_order"
    add_check_constraint :assessment_rubric_items, "maximum_score > 0 AND weight > 0",
                         name: "rubric_positive_values"
    add_check_constraint :assessment_rubric_items, "scoring_type IN ('numeric','rating')",
                         name: "rubric_scoring_type"
  end

  def create_student_assessments
    create_table :student_assessments do |t|
      t.string :public_id, null: false
      t.references :enrollment, null: false, foreign_key: { on_delete: :restrict }
      t.references :student_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :scheduled_lesson, foreign_key: { on_delete: :restrict }
      t.references :assessment_template, null: false, foreign_key: { on_delete: :restrict }
      t.date :assessment_date, null: false
      t.string :status, null: false, default: "draft"
      t.decimal :overall_score, precision: 7, scale: 2
      t.string :letter_grade
      t.text :notes
      t.references :reviewer, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.datetime :published_at
      t.datetime :archived_at
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :student_assessments, :public_id, unique: true
    add_index :student_assessments, %i[student_profile_id assessment_date]
    add_index :student_assessments, %i[teacher_profile_id status assessment_date],
              name: "idx_assessments_teacher_status_date"
    add_index :student_assessments, %i[enrollment_id assessment_template_id assessment_date],
              name: "idx_assessments_enrollment_template_date"
    add_check_constraint :student_assessments, "overall_score IS NULL OR (overall_score BETWEEN 0 AND 100)",
                         name: "assessment_score_range"
    add_check_constraint :student_assessments,
                         "status IN ('draft','submitted','reviewed','published','archived')",
                         name: "student_assessment_status"
  end

  def create_assessment_scores
    create_table :assessment_scores do |t|
      t.references :student_assessment, null: false, foreign_key: { on_delete: :restrict }
      t.references :assessment_rubric_item, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :numeric_score, precision: 7, scale: 2
      t.string :rating
      t.text :comments
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_scores, %i[student_assessment_id assessment_rubric_item_id], unique: true,
                                                                                      name: "idx_unique_rubric_score"
    add_check_constraint :assessment_scores, "numeric_score IS NULL OR numeric_score >= 0",
                         name: "assessment_scores_nonnegative"
  end

  def create_student_progresses
    create_table :student_progresses do |t|
      t.references :student_profile, null: false, index: { unique: true }, foreign_key: { on_delete: :restrict }
      t.string :current_surah
      t.integer :current_page
      t.integer :current_ayah
      t.decimal :memorization_progress, precision: 7, scale: 2, null: false, default: 0
      t.decimal :revision_progress, precision: 7, scale: 2, null: false, default: 0
      t.decimal :completion_percentage, precision: 7, scale: 2, null: false, default: 0
      t.boolean :ijazah_ready, null: false, default: false
      t.date :last_evaluation_date
      t.decimal :average_score, precision: 7, scale: 2
      t.decimal :highest_score, precision: 7, scale: 2
      t.decimal :lowest_score, precision: 7, scale: 2
      t.references :strongest_category, foreign_key: { to_table: :assessment_categories, on_delete: :nullify }
      t.references :weakest_category, foreign_key: { to_table: :assessment_categories, on_delete: :nullify }
      t.references :latest_assessment, foreign_key: { to_table: :student_assessments, on_delete: :nullify }
      t.string :trend, null: false, default: "stable"
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :student_progresses, %i[trend average_score]
    add_check_constraint :student_progresses,
                         "current_page IS NULL OR current_page BETWEEN 1 AND 604", name: "progress_page_range"
    add_check_constraint :student_progresses,
                         "current_ayah IS NULL OR current_ayah >= 1", name: "progress_ayah_positive"
    add_check_constraint :student_progresses,
                         "memorization_progress BETWEEN 0 AND 100 AND revision_progress BETWEEN 0 AND 100 " \
                         "AND completion_percentage BETWEEN 0 AND 100", name: "progress_percentage_ranges"
    add_check_constraint :student_progresses, "trend IN ('improving','stable','needs_attention')",
                         name: "student_progress_trend"
  end

  def create_exam_sessions
    create_table :exam_sessions do |t|
      t.string :public_id, null: false
      t.string :title, null: false
      t.references :program, null: false, foreign_key: { on_delete: :restrict }
      t.references :course_offering, null: false, foreign_key: { on_delete: :restrict }
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: false
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :exam_sessions, :public_id, unique: true
    add_index :exam_sessions, %i[teacher_profile_id starts_at]
    add_index :exam_sessions, %i[status starts_at]
    add_check_constraint :exam_sessions, "duration_minutes BETWEEN 1 AND 480", name: "exam_duration_range"
    add_check_constraint :exam_sessions,
                         "status IN ('draft','scheduled','completed','reviewed','published','archived')",
                         name: "exam_session_status"
  end

  def create_certificates
    create_table :certificates do |t|
      t.string :public_id, null: false
      t.references :student_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :enrollment, foreign_key: { on_delete: :restrict }
      t.references :exam_session, foreign_key: { on_delete: :restrict }
      t.string :certificate_type, null: false
      t.date :issued_on, null: false
      t.references :issuer, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :verification_code, null: false
      t.string :qr_placeholder
      t.text :notes
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :certificates, :public_id, unique: true
    add_index :certificates, :verification_code, unique: true
    add_index :certificates, %i[student_profile_id issued_on]
    add_check_constraint :certificates,
                         "certificate_type IN ('program_completion','exam_completion','ijazah')",
                         name: "certificate_type"
  end

  def create_audit_tables
    create_audit_table(:student_assessment_events, :student_assessment)
    create_audit_table(:exam_session_events, :exam_session)
    create_audit_table(:certificate_events, :certificate)
  end

  def create_audit_table(table, aggregate)
    create_table table do |t|
      t.references aggregate, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index table, ["#{aggregate}_id", :created_at], name: "idx_#{table}_history"
  end
end
