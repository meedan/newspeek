# frozen_string_literal: true

# Parser for DataCommons dataset. This is not a live dataset, is sourced
# from https://www.datacommons.org/factcheck/download#fcmt-data, and
# appears to end around June 2019. Almost solely included for research purposes.
class DataCommons < ReviewParser
  def self.dataset_path
    'datasets/datacommons_claims.json'
  end

  def get_claims(path = self.class.dataset_path)
    raw_set = JSON.parse(File.read(path))['dataFeedElement'].sort_by do |c|
      claim_url_from_raw_claim(c, '')
    end.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.map do |claim|
        claim_url_from_raw_claim(claim)
      end.compact
      existing_urls = get_existing_urls(urls)
      new_claims =
        claim_set.reject do |claim|
          existing_urls.include?(claim_url_from_raw_claim(claim))
        end
      next if new_claims.empty?

      process_claims(new_claims.map { |raw_claim| parse_raw_claim(raw_claim) })
    end
  end

  def id_from_raw_claim(raw_claim)
    Digest::MD5.hexdigest(raw_claim['item'][0]['url'])
  rescue StandardError
    Digest::MD5.hexdigest('')
  end

  def created_at_from_raw_claim(raw_claim)
    Time.parse(raw_claim['item'][0]['datePublished'] || raw_claim['dateCreated'])
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
      id: id_from_raw_claim(raw_claim),
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

  def get_rating(item, rating_key)
    review_rating = item['reviewRating'] || {}
    Float(String(review_rating[rating_key])) if review_rating[rating_key]
  end

  def parse_datacommons_rating(item)
    best = get_rating(item, 'bestRating')
    worst = get_rating(item, 'worstRating')
    value = get_rating(item, 'ratingValue')
    if !best.nil? && !worst.nil? && !value.nil? && best - worst > 0
      return (value - worst) / (best - worst)
    end
    return value
  end
end
