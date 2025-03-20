# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create test user if it doesn't exist
user = User.find_or_create_by!(email_address: "tolase@test.com") do |u|
  u.password = "foofoofoo"
  u.password_confirmation = "foofoofoo"
end

puts "Created user: #{user.email_address}"

# Sample titles for faith-based notes
note_titles = [
  "The Power of Prayer in Daily Life",
  "Understanding the Beatitudes",
  "Faith in Times of Uncertainty",
  "The Parables of Jesus: Modern Interpretations",
  "Spiritual Disciplines for Growth",
  "Finding Peace in God's Presence",
  "The Armor of God: Spiritual Warfare",
  "Walking in Faith: Practical Steps",
  "The Fruit of the Spirit in Relationships",
  "Worship as a Lifestyle",
  "Biblical Leadership Principles",
  "The Names of God and Their Significance",
  "Healing and Restoration in Scripture",
  "The Trinity: Understanding God's Nature",
  "Stewardship and Generosity",
  "Prayer and Fasting: Spiritual Power",
  "Grace and Forgiveness in Practice",
  "The Psalms: Ancient Songs for Modern Hearts",
  "Wisdom from Proverbs for Today",
  "The Gospel Message Explained"
]

# Sample transcription content
transcription_samples = [
  "Today we're going to explore the importance of daily prayer and how it transforms our relationship with God. Prayer is not just about asking for things, but about communion with our Creator.",
  "The Beatitudes provide a framework for Christian living that challenges our worldly values. When Jesus said 'Blessed are the poor in spirit,' he was inviting us into a new way of seeing ourselves.",
  "Faith becomes most real when we face uncertainty. In these moments, we learn to trust God's character rather than our circumstances.",
  "Jesus used parables to make spiritual truths accessible. These stories continue to speak to us today if we have ears to hear.",
  "Spiritual disciplines are practices that help us grow in our faith. They include prayer, Bible study, fasting, and service to others."
]

# Sample summary content
summary_samples = [
  "• Prayer builds relationship with God\n• Consistency matters more than length\n• Both speaking and listening are important\n• Prayer changes us more than our circumstances",
  "• The Beatitudes invert worldly values\n• Spiritual poverty leads to kingdom riches\n• Meekness and mercy are Christian virtues\n• Living the Beatitudes is countercultural",
  "• Faith is tested in uncertainty\n• God's character remains constant\n• Biblical examples show faith during trials\n• Community supports faith in difficult times",
  "• Parables use everyday examples to teach spiritual truths\n• They often have surprising twists\n• Understanding requires spiritual discernment\n• Application matters more than interpretation",
  "• Disciplines are means of grace, not merit\n• Regular practice leads to spiritual growth\n• Balance different disciplines for wholeness\n• Community accountability helps consistency"
]

# Create 100 notes
puts "Creating 100 sample notes..."

100.times do |i|
  title_index = i % note_titles.length
  content_index = i % transcription_samples.length
  summary_index = i % summary_samples.length
  
  note = Note.new(
    user: user,
    title: "#{note_titles[title_index]} #{i+1}",
    language: ["en", "fr", "es"].sample,
    created_at: rand(1..365).days.ago
  )
  
  # Add rich text content
  note.transcription = transcription_samples[content_index]
  note.summary = summary_samples[summary_index]
  
  note.save!
  
  # Create some note chats for each note (between 0-5 chats)
  rand(0..5).times do
    note.note_chats.create!(
      user: user,
      role: ["user", "assistant"].sample,
      content: "This is a sample chat message for note #{i+1}.",
      created_at: note.created_at + rand(1..30).days
    )
  end
  
  print "." if i % 10 == 0
end

puts "\nSeeding completed successfully!"