module BibleVersesHelper
  def translations_cache_key(version = 1)
    CacheKeys.bible_translations_key(version)
  end
  
  def cached_bible_translations
    cache_key = translations_cache_key
    cached = Rails.cache.exist?(cache_key)
    
    translations = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      Rails.logger.info "CACHE MISS: Bible translations cache being generated"
      BibleConstants::TRANSLATIONS
    end
    
    Rails.logger.info "CACHE #{cached ? 'HIT' : 'MISS'}: Bible translations (#{translations.count} items)"
    translations
  end
end