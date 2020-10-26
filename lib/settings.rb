class Settings
  
  def self.get_es_index_name
    Settings.get('es_index_name')
  end
  
  def self.airbrake_specified?
    Settings.blank?('airbrake_api_host')
  end

  def self.airbrake_unspecified?
    Settings.blank?('airbrake_api_host') && !Settings.in_test_mode?
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
      'redis_port' => 6379,
      'redis_database' => 1,
      'env' => 'test',
    }
  end

  def self.redis_url
    "redis://#{Settings.get('redis_host')}:#{Settings.get('redis_port')}/#{Settings.get('redis_database')}"
  end

  def self.in_test_mode?
    Settings.get('env') == 'test'
  end

  def self.in_qa_mode?
    Settings.get('env') == 'qa'
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
    res = nil
    begin
      res = Settings.attempt_elasticsearch_connect
    rescue Errno::ECONNREFUSED, SocketError
      sleep(1)
      retry if start+timeout > Time.now
    end
    return res
  end

  def self.check_into_elasticsearch(timeout=60, bypass=Settings.in_test_mode?)
    if !bypass
      res = Settings.safe_attempt_elasticsearch_connect(timeout)
      raise Settings.elastic_search_error if res.nil?
    end
  end

  def self.elastic_search_error
    StandardError.new("Could not connect to elasticsearch host located at #{Settings.get('es_host')}!")
  end

  def self.task_interevent_time
    self.in_qa_mode? ? 60 * 60 * 2 : 60 * 60
  end
  
  def self.default_task_count(task)
    {
      snowball_claim_reviews_from_publishers: 1,
      get_claim_reviews: 10,
      get_parsed_fact_pages_from_urls: 5,
      parse_raw_claim_reviews: 5
    }[task] || 1
  end

  def self.parallelism_for_task(task)
    Settings.in_test_mode? ? 0 : Settings.default_task_count(task)
  end
end
