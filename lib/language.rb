class Language
  def self.get_language(text, reliable=false)
    response = CLD.detect_language(text)
    if reliable
      return response[:code] if response[:reliable]
    else
      return response[:code]
    end
  end
  
  def self.get_reliable_language(text)
    self.get_language(text, true)
  end
end
