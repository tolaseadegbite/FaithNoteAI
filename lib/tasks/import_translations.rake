namespace :bible_verses do
  desc "Import additional Bible translations from CSV files"
  task import_translations: :environment do
    require 'csv'
    
    # Available translations in lib/data directory
    translations = {
      "ASV" => "american_standard.csv",
      "BBE" => "bible_in_basic_english.csv",
      "DARBY" => "darby_english_bible.csv",
      "WEBSTER" => "webster.csv",
      "WEB" => "world_english_bible.csv",
      "YLT" => "young_literal_translation.csv"
    }
    
    puts "Starting import of additional Bible translations..."
    
    translations.each do |code, filename|
      csv_path = Rails.root.join('lib', 'data', filename)
      
      if File.exist?(csv_path)
        puts "Importing #{code} translation from #{filename}..."
        import_translation(csv_path, code)
      else
        puts "Warning: File not found - #{csv_path}"
      end
    end
    
    puts "Import completed!"
  end
  
  def import_translation(file_path, translation_code)
    count = 0
    errors = 0
    
    # Try different encodings if needed
    encodings = ['UTF-8', 'Windows-1252', 'ISO-8859-1']
    
    encodings.each do |encoding|
      begin
        # Reset counters for retry
        count = 0
        errors = 0
        
        puts "Trying with #{encoding} encoding..."
        
        # Read the file with the specified encoding
        file_content = File.read(file_path, encoding: encoding)
        
        CSV.parse(file_content, headers: true) do |row|
          # Check if we have the expected columns
          if row['book'].nil? || row['chapter'].nil? || row['verse'].nil? || row['text'].nil?
            # Try to detect column names
            if row.headers.include?('b')
              book_col = 'b'
              chapter_col = 'c'
              verse_col = 'v'
              text_col = 't'
            else
              # If we can't determine columns, skip this row
              errors += 1
              next
            end
          else
            book_col = 'book'
            chapter_col = 'chapter'
            verse_col = 'verse'
            text_col = 'text'
          end
          
          # Extract data from CSV
          book_num = row[book_col]
          chapter = row[chapter_col].to_i
          verse = row[verse_col].to_i
          content = row[text_col]
          
          # Convert book number to name if needed
          book = if book_num.to_i.to_s == book_num.to_s
            # It's a number, convert to book name
            book_name_from_number(book_num.to_i)
          else
            # It's already a name
            book_num
          end
          
          # Skip if any required field is missing
          if book.blank? || chapter.blank? || verse.blank? || content.blank?
            errors += 1
            next
          end
          
          # Create or update the verse
          bible_verse = BibleVerse.find_or_initialize_by(
            book: book,
            chapter: chapter,
            verse: verse,
            translation: translation_code,
            language: 'en'
          )
          
          bible_verse.content = content
          
          if bible_verse.save
            count += 1
            print "." if count % 100 == 0
          else
            errors += 1
            puts "\nError saving #{book} #{chapter}:#{verse} - #{bible_verse.errors.full_messages.join(', ')}"
          end
        end
        
        puts "\nImported #{count} verses for #{translation_code} (#{errors} errors)"
        return # Successfully processed the file, exit the method
      rescue => e
        puts "Error with #{encoding} encoding: #{e.message}"
        # Continue to the next encoding
      end
    end
    
    puts "\nFailed to import #{translation_code} with any encoding"
  end
  
  def book_name_from_number(book_num)
    book_names = {
      1 => "Genesis", 2 => "Exodus", 3 => "Leviticus", 4 => "Numbers", 5 => "Deuteronomy",
      6 => "Joshua", 7 => "Judges", 8 => "Ruth", 9 => "1 Samuel", 10 => "2 Samuel",
      11 => "1 Kings", 12 => "2 Kings", 13 => "1 Chronicles", 14 => "2 Chronicles",
      15 => "Ezra", 16 => "Nehemiah", 17 => "Esther", 18 => "Job", 19 => "Psalms",
      20 => "Proverbs", 21 => "Ecclesiastes", 22 => "Song of Solomon", 23 => "Isaiah",
      24 => "Jeremiah", 25 => "Lamentations", 26 => "Ezekiel", 27 => "Daniel",
      28 => "Hosea", 29 => "Joel", 30 => "Amos", 31 => "Obadiah", 32 => "Jonah",
      33 => "Micah", 34 => "Nahum", 35 => "Habakkuk", 36 => "Zephaniah", 37 => "Haggai",
      38 => "Zechariah", 39 => "Malachi", 40 => "Matthew", 41 => "Mark", 42 => "Luke",
      43 => "John", 44 => "Acts", 45 => "Romans", 46 => "1 Corinthians", 47 => "2 Corinthians",
      48 => "Galatians", 49 => "Ephesians", 50 => "Philippians", 51 => "Colossians",
      52 => "1 Thessalonians", 53 => "2 Thessalonians", 54 => "1 Timothy", 55 => "2 Timothy",
      56 => "Titus", 57 => "Philemon", 58 => "Hebrews", 59 => "James", 60 => "1 Peter",
      61 => "2 Peter", 62 => "1 John", 63 => "2 John", 64 => "3 John", 65 => "Jude",
      66 => "Revelation"
    }
    
    book_names[book_num] || "Unknown Book #{book_num}"
  end
end