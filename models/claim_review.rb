# frozen_string_literal: true

class ClaimReview
  include Elasticsearch::DSL
  attr_reader :attributes
  def self.persistable_raw_claims
    %w[data_commons]
  end
  def initialize(attributes = {})
    @attributes = attributes
  end

  def to_hash
    @attributes
  end

  def self.mandatory_fields
    %w[claim_headline claim_url created_at id]
  end

  def self.parse_created_at(parsed_claim)
    Time.parse(parsed_claim['created_at'].to_s).strftime('%Y-%m-%dT%H:%M:%SZ')
  end

  def self.validate_claim(parsed_claim)
    mandatory_fields.each do |field|
      return nil if parsed_claim[field].nil?
    end
    parsed_claim.delete('raw_claim') if !self.persistable_raw_claims.include?(parsed_claim['service'])
    parsed_claim['created_at'] = self.parse_created_at(parsed_claim)
    parsed_claim
  end

  def self.save_claim(parsed_claim, service)
    validated_claim = validate_claim(Hashie::Mash[parsed_claim.merge(service: service)])
    repository.save(ClaimReview.new(validated_claim)) if validated_claim
  end

  def self.repository
    ClaimReviewRepository.new(client: client)
  end

  def self.es_hostname
    SETTINGS['es_host'] || 'http://localhost:9200'
  end

  def self.client
    Elasticsearch::Client.new(url: es_hostname)
  end

  def self.get_hits(search_params)
    ClaimReview.client.search(
      { index: SETTINGS['es_index_name'] }.merge(search_params)
    )['hits']['hits'].map { |x| x['_source'] }
  end

  def self.extract_matches(matches, match_type, service)
    matched_set = []
    matches.each_slice(100) do |match_set|
      matched_set << ClaimReview.get_hits(
        body: ElasticSearchQuery.multi_match_against_service(match_set, match_type, service)
      ).map { |x| x[match_type] }
    end
    matched_set.flatten.uniq
  end

  def self.existing_ids(ids, service)
    extract_matches(ids, 'id', service)
  end

  def self.existing_urls(urls, service)
    extract_matches(urls, 'claim_url', service)
  end

  def self.store_claim(parsed_claim, service)
    save_claim(parsed_claim, service) if existing_ids([parsed_claim[:id]], service).empty?
  end

  def self.search(opts)
    ClaimReview.get_hits(
      body: ElasticSearchQuery.claim_review_search_query(opts)
    ).map { |r| ClaimReview.convert_to_claim_review(r) }
  end

  def self.convert_to_claim_review(claim_review)
    {
      "@context": 'http://schema.org',
      "@type": 'ClaimReview',
      "datePublished": Time.parse(claim_review['created_at']).strftime('%Y-%m-%d'),
      "url": claim_review['claim_url'],
      "author": {
        "name": claim_review['author'],
        "url": claim_review['author_link']
      },
      "claimReviewed": claim_review['claim_headline'],
      "text": claim_review['claim_body'],
      "reviewRating": {
        "@type": 'Rating',
        "ratingValue": claim_review['claim_result_score'],
        "bestRating": 1,
        "alternateName": claim_review['claim_result']
      }
    }
  end
end
