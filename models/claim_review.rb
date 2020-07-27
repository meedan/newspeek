# frozen_string_literal: true

require_relative('../lib/claim_review_export')
require_relative('../lib/elastic_search_accessors')
require_relative('../lib/elastic_search_methods')
class ClaimReview
  include Elasticsearch::DSL
  extend ClaimReviewExport
  include ElasticSearchAccessors
  extend ElasticSearchMethods
  def self.mandatory_fields
    %w[claim_review_headline claim_review_url created_at id]
  end

  def self.parse_created_at(parsed_claim_review)
    Time.parse(parsed_claim_review['created_at'].to_s).strftime('%Y-%m-%dT%H:%M:%SZ')
  end

  def self.validate_claim_review(parsed_claim_review)
    mandatory_fields.each do |field|
      return nil if parsed_claim_review[field].nil?
    end
    if ClaimReviewParser.persistable_raw_claim_reviews.include?(parsed_claim_review['service'].to_s)
      parsed_claim_review['raw_claim_review'] = parsed_claim_review['raw_claim_review'].to_json
    else
      parsed_claim_review.delete('raw_claim_review')
    end
    parsed_claim_review['id'] = self.convert_id(parsed_claim_review['id'], parsed_claim_review['service'])
    parsed_claim_review['created_at'] = self.parse_created_at(parsed_claim_review)
    parsed_claim_review
  end

  def self.save_claim_review(parsed_claim_review, service)
    validated_claim_review = validate_claim_review(Hashie::Mash[parsed_claim_review.merge(service: service)])
    if validated_claim_review
      repository.save(ClaimReview.new(validated_claim_review))
      NotifySubscriber.perform_async(self.convert_to_claim_review(validated_claim_review), service)
    end
  rescue StandardError => e
    Error.log(e, {validated_claim_review: validated_claim_review})
  end
  
  def self.es_index_key
    'es_index_name'
  end

  def self.service_query(service)
    { index: self.es_index_name }.merge(body: ElasticSearchQuery.service_query(service))
  end

  def self.delete_by_service(service)
    ClaimReview.client.delete_by_query(self.service_query(service))["deleted"]
  end

  def self.get_count_for_service(service)
    self.get_hits(self.service_query(service), "total")
  end

  def self.get_hits(search_params, return_type="hits")
    response = ClaimReview.client.search(
      { index: self.es_index_name }.merge(search_params)
    )['hits']
    if return_type == "hits"
      response['hits'].map { |x| x['_source'] }
    elsif return_type == "total"
      response['total']
    end
  end

  def self.extract_matches(matches, match_type, service, sort=ElasticSearchQuery.created_at_desc)
    matched_set = []
    matches.each_slice(100) do |match_set|
      matched_set << ClaimReview.get_hits(
        body: ElasticSearchQuery.multi_match_against_service(match_set, match_type, service, sort)
      ).map { |x| x[match_type] }
    end
    matched_set.flatten.uniq
  end

  def self.convert_id(id, service)
    Digest::MD5.hexdigest("#{service}_#{id}")
  end

  def self.existing_ids(ids, service)
    extract_matches(ids.collect{|id| self.convert_id(id, service)}, 'id', service)
  end

  def self.existing_urls(urls, service)
    extract_matches(urls, 'claim_url', service)
  end

  def self.store_claim_review(parsed_claim_review, service)
    self.save_claim_review(parsed_claim_review, service) if existing_ids([parsed_claim_review[:id]], service).empty?
  end

  def self.search(opts, sort=ElasticSearchQuery.created_at_desc)
    ClaimReview.get_hits(
      body: ElasticSearchQuery.claim_review_search_query(opts, sort)
    ).map { |r| ClaimReview.convert_to_claim_review(r) }
  end

  def self.get_first_date_for_service_by_sort(service, sort)
    (self.search({per_page: 1, offset: 0, service: service}, sort)[0]||{})[:datePublished]
  end

  def self.get_earliest_date_for_service(service)
    self.get_first_date_for_service_by_sort(service, ElasticSearchQuery.created_at_asc)
  end

  def self.get_latest_date_for_service(service)
    self.get_first_date_for_service_by_sort(service, ElasticSearchQuery.created_at_desc)
  end

end
