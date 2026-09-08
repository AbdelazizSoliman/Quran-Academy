class AddLockVersionToAssessmentScores < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_scores, :lock_version, :integer, null: false, default: 0
  end
end
