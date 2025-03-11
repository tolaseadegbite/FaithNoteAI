namespace :bible_verses do
  desc "Verify imported Bible verses with some sample queries"
  task verify: :environment do
    puts "Verifying Bible verses..."
    
    # Array of famous verses to check
    verses_to_check = [
      { book: "John", chapter: 3, verse: 16 },
      { book: "Genesis", chapter: 1, verse: 1 },
      { book: "Psalms", chapter: 23, verse: 1 },
      { book: "Romans", chapter: 8, verse: 28 },
      { book: "Philippians", chapter: 4, verse: 13 },
      { book: "Jeremiah", chapter: 29, verse: 11 },
      { book: "Proverbs", chapter: 3, verse: 5 }
    ]
    
    # Check each verse
    verses_to_check.each do |v|
      verse = BibleVerse.find_verse(v[:book], v[:chapter], v[:verse])
      
      if verse
        puts "✓ #{verse.reference}"
        puts "  \"#{verse.content}\""
      else
        puts "✗ #{v[:book]} #{v[:chapter]}:#{v[:verse]} - Not found!"
      end
      puts ""
    end
    
    # Check a full chapter
    puts "Checking Genesis chapter 1..."
    genesis_1 = BibleVerse.find_chapter("Genesis", 1)
    if genesis_1.any?
      puts "✓ Genesis 1 has #{genesis_1.count} verses"
      puts "  First verse: \"#{genesis_1.first.content}\""
      puts "  Last verse: \"#{genesis_1.last.content}\""
    else
      puts "✗ Genesis 1 - Not found or empty!"
    end
    
    # Check the last verse of the Bible
    puts "\nChecking the last verse of the Bible (Revelation 22:21)..."
    last_verse = BibleVerse.find_verse("Revelation", 22, 21)
    if last_verse
      puts "✓ Last verse: #{last_verse.reference}"
      puts "  \"#{last_verse.content}\""
    else
      puts "✗ Revelation 22:21 - Not found!"
    end
    
    # Check total count
    total = BibleVerse.count
    puts "\nTotal verses in database: #{total}"
    if total == 31103
      puts "✓ Count matches CSV file (31103 verses)"
    else
      puts "✗ Count mismatch! Database has #{total} verses, CSV has 31103 verses"
    end
  end
end