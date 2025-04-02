module NotesHelper
  def process_bible_verses(text, translation = "KJV")
    return text if text.blank?
    
    # For ActionText content, convert to HTML string but preserve formatting
    if text.is_a?(ActionText::RichText)
      html_content = text.to_s
      ChatConversation::BibleVerseProcessor.process_html_content(html_content, translation)
    else
      ChatConversation::BibleVerseProcessor.process_response(text, translation)
    end
  end
end
