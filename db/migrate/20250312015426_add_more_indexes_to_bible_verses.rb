class AddMoreIndexesToBibleVerses < ActiveRecord::Migration[8.0]
  def change
    # Add index for content searches
    add_index :bible_verses, :content, using: :gin, opclass: :gin_trgm_ops, name: 'index_bible_verses_on_content_trigram'
    
    # Add index for filtering by translation
    add_index :bible_verses, :translation
    
    # Add index for finding all verses in a chapter
    add_index :bible_verses, [:book, :chapter, :translation]
  end
end