class CreatePublicInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :public_inquiries do |t|
      t.string :public_id, null: false
      t.string :inquiry_type, null: false
      t.string :name, null: false
      t.string :phone
      t.string :whatsapp_number
      t.string :email
      t.string :preferred_locale, null: false
      t.integer :student_age
      t.text :preferred_schedule_notes
      t.string :subject
      t.text :message
      t.string :status, null: false, default: "new"
      t.string :source, null: false, default: "public_website"
      t.datetime :submitted_at, null: false
      t.datetime :handled_at
      t.references :handled_by, foreign_key: { to_table: :users }
      t.text :internal_notes

      t.timestamps
    end

    add_index :public_inquiries, :public_id, unique: true
    add_index :public_inquiries, %i[inquiry_type status submitted_at]
    add_index :public_inquiries, :submitted_at
  end
end
