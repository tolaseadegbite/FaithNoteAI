namespace :bible do
  desc "Test the Bible verse processor with a sample verse"
  task test_processor: :environment do
    sample_text = "As Jesus said in **John 3:16**, we should love one another. Also, **Romans 8:28** reminds us that all things work together for good."
    
    puts "Original text:"
    puts sample_text
    puts "\nProcessed text (KJV):"
    puts ChatConversation::BibleVerseProcessor.process_response(sample_text, "KJV")
    
    if ENV['TRANSLATION']
      puts "\nProcessed text (#{ENV['TRANSLATION']}):"
      puts ChatConversation::BibleVerseProcessor.process_response(sample_text, ENV['TRANSLATION'])
    end
  end
end