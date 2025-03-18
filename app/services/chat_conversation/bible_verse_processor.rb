module ChatConversation
  class BibleVerseProcessor
    VERSE_REGEX = /\b(Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|1 Samuel|2 Samuel|1 Kings|2 Kings|1 Chronicles|2 Chronicles|Ezra|Nehemiah|Esther|Job|Psalm|Psalms|Proverbs|Ecclesiastes|Song of Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|1 Corinthians|2 Corinthians|Galatians|Ephesians|Philippians|Colossians|1 Thessalonians|2 Thessalonians|1 Timothy|2 Timothy|Titus|Philemon|Hebrews|James|1 Peter|2 Peter|1 John|2 John|3 John|Jude|Revelation)\s+(\d+):(\d+)(?:-(\d+))?/i

    def self.process_response(response_text, translation = "KJV")
      # Find all verse references in the response
      response_text.gsub(VERSE_REGEX) do |match|
        book, chapter, verse_start, verse_end = $1, $2.to_i, $3.to_i, $4&.to_i
        
        if verse_end
          # Handle verse range
          verses = (verse_start..verse_end).map do |v|
            fetch_verse(book, chapter, v, translation)
          end
          
          # Format the verse range with proper citation
          formatted_verses = verses.compact.map(&:content).join(" ")
          if formatted_verses.present?
            reference = "#{book} #{chapter}:#{verse_start}-#{verse_end}"
            create_verse_block(formatted_verses, reference, book, chapter, verse_start, verse_end, translation)
          else
            match # Keep original if verses not found
          end
        else
          # Handle single verse
          verse = fetch_verse(book, chapter, verse_start, translation)
          if verse
            reference = "#{book} #{chapter}:#{verse_start}"
            create_verse_block(verse.content, reference, book, chapter, verse_start, nil, translation)
          else
            match # Keep original if verse not found
          end
        end
      end
    end
    
    private
    
    def self.create_verse_block(content, reference, book, chapter, verse_start, verse_end = nil, translation = "KJV")
      # Create a link that will load the verse in a Turbo Frame
      verse_params = {
        book: book,
        chapter: chapter,
        verse_start: verse_start,
        translation: translation
      }
      verse_params[:verse_end] = verse_end if verse_end
      
      # Use HTML blockquote that will be preserved through markdown rendering
      <<~HTML
        <blockquote class="bible-verse">
          <p>#{content}</p>
          <p><strong><a href="/bible/show_verse?#{verse_params.to_query}" 
            class="bible-verse-link" 
            data-turbo-frame="verse_viewer" 
            data-controller="verse-link" 
            data-action="click->verse-link#showVerse">#{reference}</a></strong> (#{translation})</p>
        </blockquote>
      HTML
    end
    
    def self.fetch_verse(book, chapter, verse, translation)
      # Use the existing BibleVerse model to fetch the verse
      BibleVerse.find_verse(book, chapter, verse, translation)
    end
  end
end