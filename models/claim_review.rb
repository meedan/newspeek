# frozen_string_literal: true

class ClaimReview
  include Elasticsearch::DSL
  def self.mandatory_fields
    %w[claim_headline claim_url created_at service_id]
  end

  def self.validate_claim(parsed_claim)
    parsed_claim.delete('_id')
    parsed_claim.delete('raw_claim')
    mandatory_fields.each do |field|
      return nil if parsed_claim[field].nil?
    end
    parsed_claim['created_at'] = Time.parse(parsed_claim['created_at'].to_s).strftime('%Y-%m-%dT%H:%M:%SZ')
    parsed_claim
  end

  def self.save_claim(parsed_claim, service)
    f = File.open("#{service}_raw.json", 'w')
    f.write(parsed_claim['raw_claim'].to_json)
    f.close
    validated_claim = validate_claim(parsed_claim)
    repository.save(validated_claim.merge(service: service)) if validated_claim
  end

  def self.repository
    ClaimReviewRepository.new(client: client)
  end

  def self.client
    Elasticsearch::Client.new(url: SETTINGS['es_host'] || 'http://localhost:9200')
  end

  def self.get_hits(search_params)
    ClaimReview.client.search(
      { index: SETTINGS['es_index_name'] }.merge(search_params)
    )['hits']['hits'].collect { |x| x['_source'] }
  end

  def self.extract_matches(matches, match_type, service)
    matched_set = []
    matches.each_slice(100) do |match_set|
      matched_set << ClaimReview.get_hits(
        body: ElasticSearchQuery.multi_match_against_service(match_set, match_type, service)
      ).collect { |x| x[match_type] }
    end
    matched_set.flatten.uniq
  end

  def self.existing_ids(ids, service)
    extract_matches(ids, 'service_id', service)
  end

  def self.existing_urls(urls, service)
    extract_matches(urls, 'claim_url', service)
  end

  def self.store_claim(parsed_claim, service)
    save_claim(parsed_claim, service) if existing_ids([parsed_claim[:service_id]], service).empty?
  rescue StandardError
    binding.pry
  end

  def self.search(search_query = nil, service = nil, created_at_start = nil, created_at_end = nil, limit = 20, offset = 0)
    ClaimReview.get_hits(
      body: ElasticSearchQuery.claim_review_search_query(search_query, service, created_at_start, created_at_end, limit, offset)
    ).collect { |r| ClaimReview.convert_to_claim_review(r) }
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
