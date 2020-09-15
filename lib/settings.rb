class Settings
  
  def self.get_es_index_name
    Settings.get('es_index_name')
  end
  
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
      'es_host' => 'http://0.0.0.0:9200',
      'es_index_name' => 'claim_reviews',
      'redis_host' => 'redis',
      'redis_port' => 6379,
      'redis_database' => 1,
      'env' => 'test',
    }
  end

  def self.redis_url
    "redis://#{Settings.get('redis_host')}:#{Settings.get('redis_port')}/#{Settings.get('redis_database')}"
  end

  def self.in_test_mode?
    Settings.get('env') != 'test'
  end

  def self.attempt_elasticsearch_connect
    url = URI.parse(Settings.get('es_host'))
    Net::HTTP.start(
      url.host,
      url.port,
      use_ssl: url.scheme == 'https',
      open_timeout: 5,
      read_timeout: 5,
      ssl_timeout: 5
    ) { |http| http.request(Net::HTTP::Get.new(url)) }
  end

  def self.safe_attempt_elasticsearch_connect(timeout)
    start = Time.now
    begin
      res = Settings.attempt_elasticsearch_connect
    rescue Errno::ECONNREFUSED, SocketError
      sleep(1)
      retry if start+timeout > Time.now
    end
    return res
  end

  def self.check_into_elasticsearch(timeout=60, bypass=!Settings.in_test_mode?)
    unless bypass
      res = Settings.safe_attempt_elasticsearch_connect(timeout)
      raise Settings.elastic_search_error if res.nil?
    end
  end

  def self.elastic_search_error
    StandardError.new("Could not connect to elasticsearch host located at #{Settings.get('es_host')}!")
  end
end
