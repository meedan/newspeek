# frozen_string_literal: true

class AajtakIndiaToday < ReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://aajtak.intoday.in'
  end

  def fact_list_path(page = 1)
    # they start with 0-indexes, so push back internally
    "/fact-check.html/#{page*30}"
  end

  def url_extraction_search
    'div.content-article'
  end

  def url_extractor(article)
    hostname + article.search("a").first.attributes['href'].value
  end

  def claim_review_from_raw_claim_review(raw_claim_review)
    JSON.parse(raw_claim_review["page"].search("script").select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}.select{|x| JSON.parse(x.text)["@type"] == "ClaimReview"}.first.text)
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
        claim_review_headline: raw_claim_review['page'].search('h1.secArticleTitle').text.strip,
        claim_review_body: raw_claim_review['page'].search('div.storyBody p').text.strip,
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
