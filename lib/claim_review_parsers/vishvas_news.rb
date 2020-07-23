# frozen_string_literal: true

# Parser for https://www.vishvasnews.com
class VishvasNews < ClaimReviewParser
  include PaginatedReviewClaims
  def initialize
    @get_url_request_method = "post"
    super
  end

  def hostname
    'https://www.vishvasnews.com'
  end

  def fact_list_path(page = nil)
    "/wp-admin/admin-ajax.php"
  end

  def fact_list_body(page = 1)
    "action=ajax_pagination&query_vars=%7B%22tag%22%3A%22fact-check%22%2C%22lang%22%3A%22hi%22%7D&page=#{page}&loadPage=file-archive-posts-part"
  end

  def url_extraction_search
    'li.come-in h3 a'
  end

  def url_extractor(atag)
    atag.attributes['href'].value
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0)
    {
      id: raw_claim_review['url'],
      created_at: Time.parse(claim_review["datePublished"]),
      author: claim_review["author"]["name"],
      author_link: claim_review["author"]["url"],
      claim_review_headline: raw_claim_review["page"].search("h1.article-heading").text.strip,
      claim_review_body: raw_claim_review["page"].search("div.lhs-area p").text.strip,
      claim_review_reviewed: claim_review["claimReviewed"],
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_review["reviewRating"]["alternateName"].strip,
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end