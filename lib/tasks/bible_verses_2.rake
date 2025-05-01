namespace :bible_verses_2 do
  desc "Import Bible verses from CSV files in lib/data directory"
  
  task import: :environment do
    require 'csv'
    
    data_dir = Rails.root.join('lib', 'data')
    
    # Load Bible version information
    bible_versions = {}
    CSV.foreach(data_dir.join('bible_version_key.csv'), headers: true) do |row|
      bible_versions[row['table']] = {
        abbreviation: row['abbreviation'],
        language: row['language'],
        version: row['version']
      }
    end
    
    # Load book information
    books = {}
    CSV.foreach(data_dir.join('key_english.csv'), headers: true) do |row|
      books[row['b']] = row['n']
    end
    
    # Process each Bible translation file
    Dir.glob(data_dir.join('*.csv')).each do |file_path|
      filename = File.basename(file_path)
      next if ['bible_version_key.csv', 'key_english.csv', 'key_genre_english.csv', 'key_abbreviations_english.csv'].include?(filename)
      
      # Process only a specific file if environment variable is set
      if ENV['BIBLE_TRANSLATION_FILE'].present? && filename != ENV['BIBLE_TRANSLATION_FILE']
        next
      end
      
      # Extract translation info - Improved matching logic
      translation_key = nil
      bible_versions.each do |table, info|
        table_key = table.sub('t_', '')
        version_name = info[:version].downcase.gsub(/[^a-z0-9]/, '')
        abbr = info[:abbreviation].downcase
        
        if filename.start_with?(table_key) ||
           filename.downcase.include?(abbr) ||
           filename.downcase.gsub(/[^a-z0-9]/, '').include?(version_name) ||
           (filename.downcase.include?("standard") && abbr == "ASV") ||
           (filename.downcase.include?("basic") && abbr == "BBE") ||
           (filename.downcase.include?("world") && abbr == "WEB") ||
           (filename.downcase.include?("young") && abbr == "YLT") ||
           (filename.downcase.include?("webster") && abbr == "WBT") # Add this condition
          translation_key = info[:abbreviation]
          break
        end
      end

      next unless translation_key
      
      puts "Importing #{filename} (#{translation_key})..."
      
      # Track progress
      total_verses = 0
      imported_verses = 0
      
      # Process the file - Add encoding options to handle invalid characters
      begin
        CSV.foreach(file_path, headers: true, encoding: 'bom|utf-8:utf-8', invalid: :replace, undef: :replace, replace: '') do |row|
          total_verses += 1
          
          # Skip if required fields are missing
          next unless row['b'] && row['c'] && row['v'] && row['t']
          
          book_id = row['b']
          book_name = books[book_id]
          next unless book_name
          
          # Create or update the verse
          verse = BibleVerse.find_or_initialize_by(
            book: book_name,
            chapter: row['c'],
            verse: row['v'],
            translation: translation_key
          )
          
          verse.content = row['t']
          verse.language = bible_versions.dig(translation_key, :language) || 'en'
          
          if verse.save
            imported_verses += 1
          else
            puts "Error importing verse: #{book_name} #{row['c']}:#{row['v']} - #{verse.errors.full_messages.join(', ')}"
          end
          
          # Print progress periodically
          if total_verses % 1000 == 0
            puts "Processed #{total_verses} verses, imported #{imported_verses}"
          end
        end
        
        puts "Completed importing #{filename}: processed #{total_verses} verses, imported #{imported_verses}"
      rescue CSV::MalformedCSVError => e
        puts "Error processing #{filename}: #{e.message}"
        puts "Trying alternative encoding..."
        
        # Try with a different encoding if the first attempt fails
        total_verses = 0
        imported_verses = 0
        
        CSV.foreach(file_path, headers: true, encoding: 'ISO-8859-1:UTF-8', invalid: :replace, undef: :replace, replace: '') do |row|
          # Same processing logic as above
          total_verses += 1
          
          # Skip if required fields are missing
          next unless row['b'] && row['c'] && row['v'] && row['t']
          
          book_id = row['b']
          book_name = books[book_id]
          next unless book_name
          
          # Create or update the verse
          verse = BibleVerse.find_or_initialize_by(
            book: book_name,
            chapter: row['c'],
            verse: row['v'],
            translation: translation_key
          )
          
          verse.content = row['t']
          verse.language = bible_versions.dig(translation_key, :language) || 'en'
          
          if verse.save
            imported_verses += 1
          else
            puts "Error importing verse: #{book_name} #{row['c']}:#{row['v']} - #{verse.errors.full_messages.join(', ')}"
          end
          
          # Print progress periodically
          if total_verses % 1000 == 0
            puts "Processed #{total_verses} verses, imported #{imported_verses}"
          end
        end
        
        puts "Completed importing #{filename} with alternative encoding: processed #{total_verses} verses, imported #{imported_verses}"
      end
    end
    
    puts "Bible verse import completed!"
  end
  
  desc "Clear all Bible verses from the database"
  task clear: :environment do
    count = BibleVerse.count
    BibleVerse.delete_all
    puts "Deleted #{count} Bible verses from the database"
  end
  
  desc "Import a specific Bible translation"
  task :import_translation, [:filename] => :environment do |t, args|
    if args[:filename].blank?
      puts "Usage: bin/rails bible_verses_2:import_translation[wbt.csv]"
      exit
    end
    
    file_path = Rails.root.join('lib', 'data', args[:filename])
    unless File.exist?(file_path)
      puts "File not found: #{file_path}"
      exit
    end
    
    # Set environment variable to process only this file
    ENV['BIBLE_TRANSLATION_FILE'] = args[:filename]
    Rake::Task['bible_verses_2:import'].invoke  # Changed from 'bible_verses:import'
  end
end