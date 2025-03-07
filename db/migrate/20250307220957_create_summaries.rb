class CreateSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :summaries do |t|
      t.references :talk, null: false, foreign_key: true
      t.string :format, null: false, default: "bullet_point"
      t.text :content, null: false

      t.timestamps
    end
  end
end
