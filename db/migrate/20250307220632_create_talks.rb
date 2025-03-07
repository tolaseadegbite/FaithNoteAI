class CreateTalks < ActiveRecord::Migration[8.0]
  def change
    create_table :talks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :transcription
      t.text :summary
      t.string :language, default: "en"
      t.string :audio_url

      t.timestamps
    end
  end
end
