# frozen_string_literal: true

class ClaimReviewRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  client Elasticsearch::Client.new(url: Settings.get('es_host'))
  index_name Settings.get_es_index_name
  klass ClaimReview

  settings number_of_shards: 1 do
    mapping do
      indexes :claim_review_headline, analyzer: 'snowball'
      indexes :service, type: 'keyword'
      indexes :created_at, type: 'date'
    end
  end

  def self.init_index
    ClaimReviewRepository.new.create_index!(force: true)
  end

  def self.safe_init_index
    if !ClaimReview.client.indices.exists(index: Settings.get_es_index_name)
      self.init_index
      return true
    end
    return false
  end
end
