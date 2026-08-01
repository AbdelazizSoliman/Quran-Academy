class ExpandCommunicationExternalUrls < ActiveRecord::Migration[8.1]
  def up
    change_column :communication_logs, :external_url, :text
  end

  def down
    change_column :communication_logs, :external_url, :string
  end
end
