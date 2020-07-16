class Settings
  def self.get(var_name)
    ENV[var_name] || self.defaults[var_name]
  end
  
  def self.defaults
    {
      'es_index_name' => 'claim_reviews',
      'ENV' => 'test',
      'es_host' => 'http://localhost:9200',
      'redis_host' => 'redis',
      'es_host' => 'http://elasticsearch:9200',
      'es_index_name' => 'claim_reviews',
    }
  end
end