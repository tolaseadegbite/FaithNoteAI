namespace :bible_verses do
  desc "Check KJV CSV file for anomalies"
  task check_csv: :environment do
    require 'csv'
    
    puts "Analyzing KJV CSV file..."
    
    # Path to your KJV CSV file
    csv_path = Rails.root.join('lib', 'data', 'kjv.csv')
    
    unless File.exist?(csv_path)
      puts "Error: KJV Bible CSV file not found at #{csv_path}"
      exit
    end
    
    # Book mapping
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
    
    # Track statistics
    total_verses = 0
    verses_by_book = Hash.new(0)
    duplicate_ids = []
    unusual_verses = []
    
    # Track the last verse seen to detect duplicates
    last_book = nil
    last_chapter = nil
    last_verse = nil
    
    CSV.foreach(csv_path, headers: true) do |row|
      total_verses += 1
      
      book_num = row['b'].to_i
      chapter = row['c'].to_i
      verse = row['v'].to_i
      book_name = book_names[book_num] || "Unknown Book #{book_num}"
      
      verses_by_book[book_name] += 1
      
      # Check for unusual verse numbers
      if chapter <= 0 || verse <= 0
        unusual_verses << "#{book_name} #{chapter}:#{verse}"
      end
      
      # Check for potential duplicates (same book, chapter, verse)
      if book_num == last_book && chapter == last_chapter && verse == last_verse
        duplicate_ids << "#{book_name} #{chapter}:#{verse}"
      end
      
      last_book = book_num
      last_chapter = chapter
      last_verse = verse
    end
    
    puts "CSV Analysis Results:"
    puts "Total verses in CSV: #{total_verses}"
    puts "\nVerses by book:"
    verses_by_book.sort_by { |book, count| book_names.key(book) || 999 }.each do |book, count|
      puts "  #{book}: #{count}"
    end
    
    if duplicate_ids.any?
      puts "\nPotential duplicate verses:"
      duplicate_ids.each do |ref|
        puts "  #{ref}"
      end
    else
      puts "\nNo duplicate verses found."
    end
    
    if unusual_verses.any?
      puts "\nUnusual verse numbers:"
      unusual_verses.each do |ref|
        puts "  #{ref}"
      end
    else
      puts "\nNo unusual verse numbers found."
    end
    
    # Compare with expected counts
    expected_total = 31102
    if total_verses != expected_total
      puts "\nDiscrepancy detected: CSV has #{total_verses} verses, but expected #{expected_total}."
      puts "Difference: #{total_verses - expected_total}"
    else
      puts "\nTotal verse count matches expected count of #{expected_total}."
    end
  end
end