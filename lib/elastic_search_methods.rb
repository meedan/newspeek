# frozen_string_literal: true

module ElasticSearchMethods
  def repository
    ClaimReviewRepository.new(client: client)
  end

  def es_hostname
    Settings.get('es_host')
  end

  def client
    Elasticsearch::Client.new(url: es_hostname)
  end

  def es_index_name
    Settings.get(es_index_key)
  end
end