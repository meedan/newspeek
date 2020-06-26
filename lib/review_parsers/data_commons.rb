# frozen_string_literal: true

class DataCommons < ReviewParser
  def self.dataset_path
    '../datasets/datacommons_claims.json'
  end

  def get_claims(path = self.class.dataset_path)
    raw_set = JSON.parse(File.read(path))['dataFeedElement'].sort_by do |c|
      claim_url_from_raw_claim(c, '')
    end.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.map do |claim|
        claim_url_from_raw_claim(claim)
      end.compact
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims =
        claim_set.reject do |claim|
          existing_urls.include?(claim_url_from_raw_claim(claim))
        end
      next if new_claims.empty?

      process_claims(new_claims.map { |raw_claim| parse_raw_claim(raw_claim) })
    end
  end

  def service_id_from_raw_claim(raw_claim)
    raw_claim['item'][0]['url']
  rescue StandardError
    ''
  end

  def created_at_from_raw_claim(raw_claim)
    Time.parse(raw_claim['item'][0]['datePublished'])
  rescue StandardError
    nil
  end

  def author_from_raw_claim(raw_claim)
    raw_claim['item'][0]['author']['name']
  rescue StandardError
    nil
  end

  def author_link_from_raw_claim(raw_claim)
    raw_claim['item'][0]['author']['url']
  rescue StandardError
    nil
  end

  def claim_headline_from_raw_claim(raw_claim)
    raw_claim['item'][0]['claimReviewed']
  rescue StandardError
    nil
  end

  def claim_result_from_raw_claim(raw_claim)
    raw_claim['item'][0]['reviewRating']['alternateName']
  rescue StandardError
    nil
  end

  def claim_url_from_raw_claim(raw_claim, default = nil)
    raw_claim['item'][0]['url']
  rescue StandardError
    default
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest(service_id_from_raw_claim(raw_claim)),
      created_at: created_at_from_raw_claim(raw_claim),
      author: author_from_raw_claim(raw_claim),
      author_link: author_link_from_raw_claim(raw_claim),
      claim_headline: claim_headline_from_raw_claim(raw_claim),
      claim_body: nil,
      claim_result: claim_result_from_raw_claim(raw_claim),
      claim_result_score: parse_datacommons_rating(raw_claim),
      claim_url: claim_url_from_raw_claim(raw_claim),
      raw_claim: raw_claim
    }
  end

  def parse_datacommons_rating(item)
    review_rating = item['reviewRating'] || {}
    best = String(review_rating['bestRating']) if review_rating['bestRating']
    worst = String(review_rating['worstRating']) if review_rating['worstRating']
    value = String(review_rating['ratingValue']) if review_rating['ratingValue']
    if !best.nil? && !worst.nil? && !value.nil?
      if Integer(best, 10) - Integer(worst, 10) > 0
        (Integer(value, 10) - Integer(worst, 10)) / Float((Integer(best, 10) - Integer(worst, 10)))
      end
    elsif ([best, worst, value].count(nil) > 0) && ([best, worst, value].count(nil) != 3)
      return Integer(value, 10) if best.nil? && worst.nil? && !value.nil?
    end
  end
end
