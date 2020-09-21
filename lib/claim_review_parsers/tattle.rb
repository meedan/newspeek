# frozen_string_literal: true

class Tattle < ClaimReviewParser
  def self.dataset_path
    'datasets/tattle_claims.json'
  end

  def get_claim_reviews(path = self.class.dataset_path)
    raw_set = JSON.parse(File.read(path)).sort_by { |c| c['Post URL'].to_s }.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.compact.collect { |claim| claim['Post URL'] }
      existing_urls = get_existing_urls(urls)
      new_claims = claim_set.reject { |claim| existing_urls.include?(claim['Post URL']) }
      next if new_claims.empty?
      process_claim_reviews(new_claims.map { |raw_claim_review| parse_raw_claim_review(raw_claim_review) })
    end
  end

  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review && 
    raw_claim_review['Docs'] &&
    raw_claim_review['Docs'][0] &&
    raw_claim_review['Docs'][0]['content']
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    return nil if raw_claim_review.nil?
    image = raw_claim_review["Docs"].select{|d| d && d["mediaType"] == "image"}.first
    if image
      image["origURL"]
    end
  end

  def parse_raw_claim_review(raw_claim_review)
    {
      id: raw_claim_review['Post URL'],
      created_at: Time.parse(raw_claim_review['Date Updated']),
      author: raw_claim_review['Author']['name'],
      author_link: raw_claim_review['Author']['link'],
      claim_review_headline: raw_claim_review['Headline'],
      claim_review_body: claim_review_body_from_raw_claim_review(raw_claim_review),
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: nil,
      claim_review_result_score: nil,
      claim_review_url: raw_claim_review['Post URL'],
      raw_claim_review: raw_claim_review
    }
  end
end
