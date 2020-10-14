# frozen_string_literal: true

class IndiaToday < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.indiatoday.in'
  end

  def fact_list_path(page = 1)
    # they start with 0-indexes, so push back internally
    "/fact-check?page=#{page - 1}"
  end

  def url_extraction_search
    'div.detail h2 a'
  end

  def headline_search
    'div.story-section h1'
  end
  
  def body_search
    'div.story-right p'
  end

  def url_extractor(atag)
    hostname + atag.attributes['href'].value
  end

  def claim_review_from_raw_claim_review(raw_claim_review)
    ld_json_blocks = raw_claim_review["page"].search("script").select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}
    JSON.parse(ld_json_blocks.select{|x| b = JSON.parse(x.text); b.class == Hash && b["@type"] == "ClaimReview"}.first.text)
  rescue JSON::ParserError, NoMethodError
    #send back stubbed claim_review when there's a parse error or no verifiable ClaimReview object in the document
    {}
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = claim_review_from_raw_claim_review(raw_claim_review)
    if !claim_review.empty?
      {
        id: raw_claim_review['url'],
        created_at: Time.parse(claim_review["datePublished"]),
        author: claim_review["author"]["name"],
        author_link: nil,
        claim_review_headline: raw_claim_review['page'].search(headline_search).text.strip,
        claim_review_body: raw_claim_review['page'].search(body_search).text.strip,
        claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
        claim_review_reviewed: claim_review["claimReviewed"],
        claim_review_result: claim_review["reviewRating"]["alternateName"],
        claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
        claim_review_url: raw_claim_review['url'],
        raw_claim_review: claim_review
      }
    else
      {
        id: raw_claim_review['url'],
      }
    end
  end
end