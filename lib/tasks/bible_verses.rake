namespace :bible_verses do
  desc "Import KJV Bible verses from CSV"
  task import_kjv: :environment do
    require 'csv'
    
    puts "Importing KJV Bible verses..."
    start_time = Time.now
    
    # Delete existing KJV English verses to avoid duplicates
    BibleVerse.where(translation: "KJV", language: "en").delete_all
    
    # Path to your KJV CSV file
    csv_path = Rails.root.join('lib', 'data', 'kjv.csv')
    
    unless File.exist?(csv_path)
      puts "Error: KJV Bible CSV file not found at #{csv_path}"
      puts "Please download a KJV Bible dataset and place it at this location."
      exit
    end
    
    # Book mapping - convert book number to name
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
    
    # Import verses in batches for better performance
    verses_count = 0
    batch_size = 500
    verses_batch = []
    
    CSV.foreach(csv_path, headers: true) do |row|
      book_number = row['b'].to_i
      book_name = book_names[book_number]
      
      next unless book_name # Skip if book number is invalid
      
      verses_batch << {
        book: book_name,
        chapter: row['c'].to_i,
        verse: row['v'].to_i,
        content: row['t'],
        translation: "KJV",
        language: "en",
        created_at: Time.current,
        updated_at: Time.current
      }
      
      if verses_batch.size >= batch_size
        BibleVerse.insert_all(verses_batch)
        verses_count += verses_batch.size
        verses_batch = []
        print "."
      end
    end
    
    # Insert any remaining verses
    if verses_batch.any?
      BibleVerse.insert_all(verses_batch)
      verses_count += verses_batch.size
    end
    
    end_time = Time.now
    duration = (end_time - start_time).round(2)
    
    puts "\nImported #{verses_count} KJV Bible verses successfully in #{duration} seconds."
  end
end