class Settings
  def self.airbrake_specified?
    Settings.blank?('airbrake_api_host')
  end

  def self.airbrake_unspecified?
    Settings.blank?('airbrake_api_host') && Settings.get('RACK_ENV') != 'test'
  end

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
