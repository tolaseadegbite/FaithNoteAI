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
  
  # Add this method to your NotesHelper
  # Update the format_transcription_with_breaks method
  def format_transcription_with_breaks(transcription)
    return "" if transcription.blank?
    
    # Convert ActionText::RichText to string if needed
    text = transcription.is_a?(ActionText::RichText) ? transcription.to_s : transcription.to_s
    
    # Split the text by speaker labels
    segments = text.split(/(?=Speaker [A-Z]:)/)
    
    # Handle the [END] marker separately
    segments = segments.map do |segment|
      if segment.include?("[END]")
        parts = segment.split("[END]")
        if parts.length > 1
          [parts[0], "<p>[END]</p>"]
        else
          segment
        end
      else
        segment
      end
    end.flatten
    
    # Wrap each segment in a paragraph tag
    formatted_html = segments.map do |segment|
      segment.strip.empty? ? "" : "<p>#{segment.strip}</p>"
    end.join("\n")
    
    formatted_html.html_safe
  end
end
