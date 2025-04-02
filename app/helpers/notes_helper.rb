module NotesHelper
  def process_bible_verses(text, translation = "KJV")
    return text if text.blank?
    ChatConversation::BibleVerseProcessor.process_response(text, translation)
  end
end
