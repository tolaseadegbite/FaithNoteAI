module CacheMonitoringHelper
  def track_cache_hit
    @_view_cache_hits ||= 0
    @_view_cache_hits += 1
  end
  
  def track_cache_miss
    @_view_cache_misses ||= 0
    @_view_cache_misses += 1
  end
  
  def cache_with_tracking(*args, &block)
    cache_key = args.first
    fragment_exist = controller.fragment_exist?(cache_key)
    
    if fragment_exist
      track_cache_hit
      Rails.logger.info "CACHE HIT: #{cache_key.inspect}"
    else
      track_cache_miss
      Rails.logger.info "CACHE MISS: #{cache_key.inspect}"
    end
    
    cache(*args, &block)
  end
  
  def cache_stats
    hits = @_view_cache_hits || 0
    misses = @_view_cache_misses || 0
    total = hits + misses
    hit_rate = total > 0 ? (hits.to_f / total * 100).round(1) : 0
    
    {
      hits: hits,
      misses: misses,
      total: total,
      hit_rate: hit_rate
    }
  end
end