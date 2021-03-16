# frozen_string_literal: true

class TheQuint < ClaimReviewParser
  def hostname
    'https://www.thequint.com'
  end

  def fact_list_path(page = 1, limit = 100)
    "/api/v1/collections/webqoof?item-type=story&offset=#{(page - 1) * limit}&limit=#{limit}"
  end

  def get_claim_reviews_for_page(page = 1)
    JSON.parse(RestClient.get(hostname + fact_list_path(page)))['items']
  end

  def get_new_claim_reviews_for_page(page = 1)
    claims = parse_raw_claim_reviews(get_claim_reviews_for_page(page))
    existing_urls = get_existing_urls(claims.map { |claim| claim['url'] }.compact)
    process_claim_reviews(claims.reject { |claim| existing_urls.include?(claim['url']) })
  end

  def get_claim_reviews
    page = 1
    raw_claims = get_new_claim_reviews_for_page(page)
    until finished_iterating?(raw_claims)
      page += 1
      raw_claims = get_new_claim_reviews_for_page(page)
    end
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    Time.at(raw_claim_review['story']['published-at'] / 1000.0)
  rescue StandardError => e
    Error.log(e)
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story']['authors'][0]['name']
  rescue StandardError => e
    Error.log(e)
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story']['authors'][0]['avatar-url']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story'] &&
    raw_claim_review['story']['metadata'] &&
    raw_claim_review['story']['metadata']['story-attributes'] &&
    raw_claim_review['story']['metadata']['story-attributes']['factcheck'] &&
    raw_claim_review['story']['metadata']['story-attributes']['factcheck'].first
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_score_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story'] &&
    raw_claim_review['story']['metadata'] &&
    raw_claim_review['story']['metadata']['story-attributes'] &&
    raw_claim_review['story']['metadata']['story-attributes']['claimreviewrating'] &&
    Integer(raw_claim_review['story']['metadata']['story-attributes']['claimreviewrating'].first.to_s, 10)
  rescue StandardError => e
    Error.log(e)
  end

  def claim_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story']['headline']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story']['seo']['meta-description']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review['story']['url']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_image_url_from_raw_claim_review(raw_claim_review)
    "https://images.thequint.com/"+raw_claim_review['story']['hero-image-s3-key']
  rescue StandardError => e
    Error.log(e)
  end
  

  def parse_raw_claim_review(raw_claim_review)
    # delete unnecessary key that flags Hashie key-name warnings later
    raw_claim_review["story"].delete("cards")
    {
      id: raw_claim_review['id'],
      created_at: created_at_from_raw_claim_review(raw_claim_review),
      author: author_from_raw_claim_review(raw_claim_review),
      author_link: author_link_from_raw_claim_review(raw_claim_review),
      claim_review_headline: claim_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: claim_body_from_raw_claim_review(raw_claim_review),
      claim_review_image_url: claim_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_result_from_raw_claim_review(raw_claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(raw_claim_review),
      claim_review_url: claim_url_from_raw_claim_review(raw_claim_review),
      raw_claim_review: raw_claim_review
    }
  end
end
