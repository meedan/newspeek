# frozen_string_literal: true

# Parser for DataCommons dataset. This is not a live dataset, is sourced
# from https://www.datacommons.org/factcheck/download#fcmt-data, and
# appears to end around June 2019. Almost solely included for research purposes.
class DataCommons < ReviewParser
  include GenericRawClaimParser
  include ReviewRatingParser
  def self.dataset_path
    'datasets/datacommons_claims.json'
  end

  def get_claim_reviews(path = self.class.dataset_path)
    raw_set = JSON.parse(File.read(path))['dataFeedElement'].sort_by do |c|
      claim_url_from_raw_claim_review(c, '')
    end.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.map do |claim|
        claim_url_from_raw_claim_review(claim)
      end.compact
      existing_urls = get_existing_urls(urls)
      new_claims =
        claim_set.reject do |claim|
          existing_urls.include?(claim_url_from_raw_claim_review(claim))
        end
      next if new_claims.empty?
      process_claim_reviews(new_claims.map { |raw_claim_review| parse_raw_claim_review(raw_claim_review) })
    end
  end

  def id_from_raw_claim_review(raw_claim_review)
    raw_claim_review['item'] &&
    raw_claim_review['item'][0] &&
    raw_claim_review['item'][0]['url'] &&
    Digest::MD5.hexdigest(raw_claim_review['item'][0]['url']||"") || 
    Digest::MD5.hexdigest('')
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    time_text = raw_claim_review['item'] && raw_claim_review['item'][0] && raw_claim_review['item'][0]['datePublished'] || raw_claim_review['dateCreated']
    if time_text && !time_text.empty?
      Time.parse(time_text)
    end
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review['item'] &&
    raw_claim_review['item'][0] &&
    raw_claim_review['item'][0]['author'] &&
    raw_claim_review['item'][0]['author']['name']
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review['item'] &&
    raw_claim_review['item'][0] &&
    raw_claim_review['item'][0]['author'] &&
    raw_claim_review['item'][0]['author']['url']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review &&
    raw_claim_review['item'] &&
    raw_claim_review['item'][0] &&
    raw_claim_review['item'][0]['claimReviewed']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_from_raw_claim_review(raw_claim_review)
    raw_claim_review &&
    raw_claim_review['item'] &&
    raw_claim_review['item'][0] &&
    raw_claim_review['item'][0]['reviewRating'] &&
    raw_claim_review['item'][0]['reviewRating']['alternateName']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_url_from_raw_claim_review(raw_claim_review, default = nil)
    raw_claim_review['item'] && 
    raw_claim_review['item'][0] && 
    raw_claim_review['item'][0]['url'] ||
    default
  rescue StandardError => e
    Error.log(e)
    default
  end
end
