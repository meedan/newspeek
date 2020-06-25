# frozen_string_literal: true

class ClaimReviewRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name SETTINGS['es_index_name'] || 'claim_reviews'
  document_type 'claim_review'
  klass ClaimReview

  settings number_of_shards: 1 do
    mapping do
      indexes :claim_headline, analyzer: 'snowball'
      indexes :service, type: 'keyword'
      indexes :created_at, type: 'date'
    end
  end
end
