class BibleReferenceParser
  REFERENCE_REGEX = /^([1-3]?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$/i

  def self.parse(reference)
    return nil unless reference.match?(REFERENCE_REGEX)
    
    match_data = reference.match(REFERENCE_REGEX)
    
    {
      book: match_data[1].strip,
      chapter: match_data[2].to_i,
      verse: match_data[3] ? match_data[3].to_i : nil
    }
  end

  def self.valid_reference?(reference)
    reference.match?(REFERENCE_REGEX)
  end
end