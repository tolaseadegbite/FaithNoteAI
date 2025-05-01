require 'csv'

namespace :import do
  desc "Import Webster Bible verses from CSV"
  task webster: :environment do
    csv_file_path = Rails.root.join('lib', 'data', 'webster.csv')
    translation_code = "WBT" # Use the abbreviation for Webster's Bible
    language_code = "en"     # Assuming English

    # Load book information
    books = {}
    key_file_path = Rails.root.join('lib', 'data', 'key_english.csv')
    CSV.foreach(key_file_path, headers: true) do |row|
      books[row['b']] = row['n'] # Map book ID (string) to book name
    end

    puts "Starting import for Webster Bible (#{translation_code})..."
    start_time = Time.now

    # Pre-fetch existing verses for this version to potentially speed up checks, though find_or_create_by handles uniqueness.
    # existing_verses = BibleVerse.where(bible_version_id: bible_version_id)
    #                         .pluck(:book, :chapter, :verse)
    #                         .map { |b, c, v| "#{b}-#{c}-#{v}" }
    #                         .to_set

    count = 0
    created_count = 0
    skipped_count = 0

    CSV.foreach(csv_file_path, headers: true) do |row|
      count += 1
      book_id = row['b'] # Keep as string for lookup
      chapter = row['c'].to_i
      verse = row['v'].to_i
      text = row['t']&.strip

      book_name = books[book_id]
      unless book_name
        puts "Warning: Unknown book ID #{book_id} found in row #{count + 1}. Skipping."
        next
      end

      # Optional: Check against pre-fetched set if performance is critical
      # verse_key = "#{book}-#{chapter}-#{verse}"
      # if existing_verses.include?(verse_key)
      #   skipped_count += 1
      #   next
      # end

      begin
        # Use translation and language instead of bible_version_id
        # Use book_name (string) instead of book (integer)
        # Assign to content instead of text
        verse_record = BibleVerse.find_or_create_by!(
          translation: translation_code,
          language: language_code,
          book: book_name,
          chapter: chapter,
          verse: verse
        ) do |bv|
          bv.content = text # Correct attribute name
        end

        if verse_record.previously_new_record?
          created_count += 1
          # Optional: Add to pre-fetched set if using that optimization
          # existing_verses.add(verse_key)
        else
          # Optionally update content if it differs, or just skip
          # if verse_record.content != text
          #   verse_record.update!(content: text)
          #   # Handle update count if needed
          # end
          skipped_count += 1
        end

      rescue ActiveRecord::RecordInvalid => e
        puts "Error saving verse #{book_name}:#{chapter}:#{verse} - #{e.message}"
      rescue => e
        puts "General error processing row #{count + 1}: #{row.inspect} - #{e.message}"
      end

      # Progress indicator
      print "\rProcessed: #{count}, Created: #{created_count}, Skipped/Existing: #{skipped_count}" if count % 100 == 0
    end

    end_time = Time.now
    duration = end_time - start_time
    puts "\nFinished importing Webster Bible."
    puts "Total rows processed: #{count}"
    puts "New verses created: #{created_count}"
    puts "Verses skipped (already existed): #{skipped_count}"
    puts "Duration: #{duration.round(2)} seconds"
  end
end