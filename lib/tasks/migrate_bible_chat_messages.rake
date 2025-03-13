namespace :bible_chat do
  desc "Migrate existing Bible chat messages to conversations"
  task migrate_messages: :environment do
    # Group messages by user
    User.find_each do |user|
      messages = user.bible_chat_messages.where(bible_chat_conversation_id: nil).ordered
      
      next if messages.empty?
      
      # Create a default conversation for each user
      conversation = user.bible_chat_conversations.create!(
        title: "Previous Conversation"
      )
      
      # Associate messages with the conversation
      messages.update_all(bible_chat_conversation_id: conversation.id)
      
      puts "Migrated #{messages.count} messages for user #{user.id} to conversation #{conversation.id}"
    end
    
    puts "Migration complete!"
  end
end