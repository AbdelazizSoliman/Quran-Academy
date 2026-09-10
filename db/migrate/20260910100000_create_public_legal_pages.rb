class CreatePublicLegalPages < ActiveRecord::Migration[8.1]
  def change
    create_table :public_legal_pages do |t|
      t.string :page_type, null: false
      t.string :title_ar
      t.string :title_en
      t.text :body_ar
      t.text :body_en
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.date :effective_date
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :public_legal_pages, :page_type, unique: true
  end
end
