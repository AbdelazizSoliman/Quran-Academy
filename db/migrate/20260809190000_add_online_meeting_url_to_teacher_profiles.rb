class AddOnlineMeetingUrlToTeacherProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :teacher_profiles, :online_meeting_url, :string
  end
end
