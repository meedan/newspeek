# frozen_string_literal: true

# Parser for https://factcheck.afp.com
class TFCTaiwan < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://tfc-taiwan.org.tw'
  end

  def fact_list_path(page = 1)
    # appears to be zero-indexed
    "/articles/report?page=#{page - 1}"
  end

  def url_extraction_search
    'article.post-body h3.article-title a'
  end

  def url_extractor(atag)
    hostname + atag.attributes['href'].value
  end

  def claim_review_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("article.blog-post h3.article-title").text
  end
  
  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("article.blog-post div.field-type-text-with-summary p").text
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    image = raw_claim_review["page"].search("article.blog-post div.field-type-text-with-summary p img").first
    if image
      hostname+image.attributes["src"].value
    end
  end
  
  def created_at_from_claim_review(claim_review)
    claim_review &&
    claim_review["datePublished"] &&
    Time.parse(claim_review["datePublished"])
  end

  def author_from_claim_review(claim_review)
    claim_review &&
    claim_review["author"] &&
    claim_review["author"]["name"] ||
    "TFC Taiwan"
  end

  def author_link_from_claim_review(claim_review)
    claim_review &&
    claim_review["author"] &&
    claim_review["author"]["url"] ||
    hostname
  end
  
  def parse_raw_claim_review(raw_claim_review)
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0)
    {
      id: raw_claim_review['url'],
      created_at: created_at_from_claim_review(claim_review),
      author: author_from_claim_review(claim_review),
      author_link: author_link_from_claim_review(claim_review),
      claim_review_headline: claim_review_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: claim_review_body_from_raw_claim_review(raw_claim_review),
      claim_review_reviewed: claim_review["claimReviewed"],
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_review["reviewRating"]["alternateName"],
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end
