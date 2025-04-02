module ChatConversation
  class BibleVerseProcessor
    VERSE_REGEX = /\b(Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|1 Samuel|2 Samuel|1 Kings|2 Kings|1 Chronicles|2 Chronicles|Ezra|Nehemiah|Esther|Job|Psalm|Psalms|Proverbs|Ecclesiastes|Song of Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|1 Corinthians|2 Corinthians|Galatians|Ephesians|Philippians|Colossians|1 Thessalonians|2 Thessalonians|1 Timothy|2 Timothy|Titus|Philemon|Hebrews|James|1 Peter|2 Peter|1 John|2 John|3 John|Jude|Revelation)\s+(\d+):(\d+)(?:-(\d+))?/i

    def self.process_response(response_text, translation = "KJV")
      # Find all verse references in the response
      processed_text = response_text.gsub(VERSE_REGEX) do |match|
        book, chapter, verse_start, verse_end = $1, $2.to_i, $3.to_i, $4&.to_i
        
        # Create the reference text and link
        reference = verse_end ? "#{book} #{chapter}:#{verse_start}-#{verse_end}" : "#{book} #{chapter}:#{verse_start}"
        verse_link = create_verse_link(book, chapter, verse_start, verse_end, translation)
        
        if verse_end
          # Handle verse range
          verses = (verse_start..verse_end).map do |v|
            fetch_verse(book, chapter, v, translation)
          end
          
          # Format the verse range with proper citation
          formatted_verses = verses.compact.map(&:content).join(" ")
          if formatted_verses.present?
            # Add styling to make verse content visually distinct
            "#{verse_link}: <span class=\"bible-verse-content\">#{formatted_verses}</span>"
          else
            verse_link # Just link the reference if verses not found
          end
        else
          # Handle single verse
          verse = fetch_verse(book, chapter, verse_start, translation)
          if verse
            # Add styling to make verse content visually distinct
            "#{verse_link}: <span class=\"bible-verse-content\">#{verse.content}</span>"
          else
            verse_link # Just link the reference if verse not found
          end
        end
      end
      
      return processed_text
    end
    
    private
    
    def self.fetch_verse(book, chapter, verse, translation)
      # Use the existing BibleVerse model to fetch the verse
      BibleVerse.find_verse(book, chapter, verse, translation)
    end
    
    def self.create_verse_link(book, chapter, verse_start, verse_end, translation)
      reference = verse_end ? "#{book} #{chapter}:#{verse_start}-#{verse_end}" : "#{book} #{chapter}:#{verse_start}"
      
      # Create URL to the verse show page, not the chapter page
      if verse_end
        url = "/bible/#{book}/#{chapter}/#{verse_start}?translation=#{translation}&verse_end=#{verse_end}&source=chat"
      else
        url = "/bible/#{book}/#{chapter}/#{verse_start}?translation=#{translation}&source=chat"
      end
      
      "<a href=\"#{url}\" class=\"bible-verse-link\" target=\"_blank\">#{reference}</a>"
    end
  end
end