# frozen_string_literal: true

class ClaimReviewRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  client Elasticsearch::Client.new(url: Settings.get('es_host'))
  index_name Settings.get('es_index_name')
  document_type 'claim_review'
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
end
