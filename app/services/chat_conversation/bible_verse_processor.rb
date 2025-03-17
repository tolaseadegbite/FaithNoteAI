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
          
          # Format the verse range with proper citation and add link
          formatted_verses = verses.compact.map(&:content).join(" ")
          if formatted_verses.present?
            verse_link = create_verse_link(book, chapter, verse_start, verse_end, translation)
            "> #{formatted_verses}\n>\n> **#{verse_link}** (#{translation})"
          else
            match # Keep original if verses not found
          end
        else
          # Handle single verse
          verse = fetch_verse(book, chapter, verse_start, translation)
          if verse
            verse_link = create_verse_link(book, chapter, verse_start, nil, translation)
            "> #{verse.content}\n>\n> **#{verse_link}** (#{translation})"
          else
            match # Keep original if verse not found
          end
        end
      end
    end
    
    private
    
    def self.fetch_verse(book, chapter, verse, translation)
      # Use the existing BibleVerse model to fetch the verse
      BibleVerse.find_verse(book, chapter, verse, translation)
    end
    
    def self.create_verse_link(book, chapter, verse_start, verse_end, translation)
      reference = verse_end ? "#{book} #{chapter}:#{verse_start}-#{verse_end}" : "#{book} #{chapter}:#{verse_start}"
      url = "/bible/#{book}/#{chapter}/#{verse_start}?translation=#{translation}&source=chat"
      "<a href=\"#{url}\" class=\"bible-verse-link\" target=\"_blank\">#{reference}</a>"
    end
  end
end