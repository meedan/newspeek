# frozen_string_literal: true

# Parser for https://www.vishvasnews.com
class VishvasNews < ClaimReviewParser
  attr_accessor :raw_response
  include PaginatedReviewClaims
  def initialize(cursor_back_to_date = nil)
    @fact_list_page_parser = 'json'
    @raw_response = {}
    super(cursor_back_to_date)
  end

  def get_new_fact_page_urls(page)
    response = get_fact_page_urls(page)
    existing_urls = get_existing_urls(response.collect{|d| d["link"]})
    response.select{|d| !existing_urls.include?(d["link"])}
  end

  def parsed_fact_page(fact_page_response)
    parsed_page = parsed_page_from_url(fact_page_response["link"])
    return if parsed_page.nil?
    [fact_page_response["link"], parse_raw_claim_review(Hashie::Mash[{ raw_response: fact_page_response, page: parsed_page, url: fact_page_response["link"] }])]
  end

  def hostname
    'https://www.vishvasnews.com'
  end

  def fact_list_path(page = nil)
    "/jsonfeeds/?task=whatsapplatest&page=#{page}&limit=50"
  end

  def url_extractor(response)
    response["response"]["docs"]
  end

  def get_claim_review_rating_from_claim_review(claim_review)
    claim_review &&
    claim_review["reviewRating"] &&
    claim_review["reviewRating"]["alternateName"] &&
    claim_review["reviewRating"]["alternateName"].strip
  end

  def parse_raw_claim_review(raw_claim_review)
    api_response = raw_claim_review["raw_response"]
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0)
    {
      id: api_response["id"].to_s,
      created_at: Time.parse(claim_review["datePublished"]),
      author: claim_review["author"]["name"],
      author_link: claim_review["author"]["url"],
      claim_review_headline: api_response["title"],
      claim_review_body: raw_claim_review["page"].search("div.lhs-area p").text.strip,
      claim_review_reviewed: claim_review["claimReviewed"],
      claim_review_image_url: api_response["image"],
      claim_review_result: get_claim_review_rating_from_claim_review(claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end