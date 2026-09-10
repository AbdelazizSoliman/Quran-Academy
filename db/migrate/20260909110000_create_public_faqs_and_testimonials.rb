class CreatePublicFaqsAndTestimonials < ActiveRecord::Migration[8.1]
  def change
    create_table :public_faqs do |t|
      t.string :question_ar
      t.string :question_en
      t.text :answer_ar
      t.text :answer_en
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.integer :public_display_order, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :public_faqs, %i[published public_display_order]
    add_check_constraint :public_faqs, "public_display_order >= 0", name: "public_faqs_nonnegative_order"

    create_table :public_testimonials do |t|
      t.string :author_name
      t.string :relationship, null: false
      t.text :quote_ar
      t.text :quote_en
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.integer :public_display_order, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :public_testimonials, %i[published public_display_order]
    add_check_constraint :public_testimonials, "public_display_order >= 0",
                         name: "public_testimonials_nonnegative_order"
  end
end
