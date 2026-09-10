class CreatePublicAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :public_analytics_events do |t|
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.string :locale, null: false
      t.string :path, null: false
      t.string :source_path
      t.string :referrer
      t.string :target
      t.string :inquiry_type
      t.bigint :public_inquiry_id
      t.bigint :fee_plan_id
      t.string :visitor_token, null: false
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :utm_term
      t.string :utm_content
      t.timestamps
    end
    add_index :public_analytics_events, :occurred_at
    add_index :public_analytics_events, %i[event_type occurred_at]
    add_index :public_analytics_events, :visitor_token
    add_index :public_analytics_events, %i[utm_source occurred_at]
    add_index :public_analytics_events, :public_inquiry_id
    add_index :public_analytics_events, :fee_plan_id
    add_foreign_key :public_analytics_events, :public_inquiries, column: :public_inquiry_id
    add_foreign_key :public_analytics_events, :fee_plans, column: :fee_plan_id
  end
end
