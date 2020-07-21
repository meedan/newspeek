class Settings
  def self.get(var_name)
    ENV[var_name] || self.defaults[var_name]
  end

  def self.blank?(var_name)
    v = self.get(var_name)
    v.nil? || v.empty?
  end

  def self.defaults
    {
      'es_host' => 'http://elasticsearch:9200',
      'es_index_name' => 'claim_reviews',
      'redis_host' => 'redis',
      'redis_database' => 1,
    }
  end
end
