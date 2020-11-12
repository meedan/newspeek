# frozen_string_literal: true

# Parser for https://www.globo.com
class Globo < ClaimReviewParser
  attr_accessor :raw_response
  include PaginatedReviewClaims
  def initialize(cursor_back_to_date = nil, overwrite_existing_claims=false)
    super(cursor_back_to_date, overwrite_existing_claims)
    @fact_list_page_parser = 'json'
    @raw_response = {}
  end

  def get_new_fact_page_urls(page)
    response = get_fact_page_urls(page)
    existing_urls = get_existing_urls(response.collect{|d| d["content"]["url"]})
    response.select{|d| !existing_urls.include?(d["content"]["url"])}
  end

  def parsed_fact_page(fact_page_response)
    [fact_page_response["content"]["url"], parse_raw_claim_review(QuietHashie[{ raw_response: fact_page_response, url: fact_page_response["content"]["url"] }])]
  end

  def hostname
    'https://falkor-cda.bastian.globo.com'
  end

  def fact_list_path(page = nil)
    "/tenants/g1/instances/9a0574d8-bc61-4d35-9488-7733f754f881/posts/page/#{page}"
  end

  def url_extractor(response)
    response["items"]
  end

  def claim_review_image_url_from_api_response(api_response)
    api_response["content"]["image"]["sizes"]["L"]["url"] rescue nil
  end

  def claim_review_result_from_api_response(api_response)
    title_lead = api_response["content"] && api_response["content"]["title"] && api_response["content"]["title"][0..6]
    if title_lead == "É #FAKE"
      return [0, "false"]
    elsif title_lead == "É #FATO"
      return [1, "true"]
    else
    end
  end

  def parse_raw_claim_review(raw_claim_review)
    api_response = raw_claim_review["raw_response"]
    score, result = claim_review_result_from_api_response(api_response)
    {
      id: api_response["id"].to_s,
      created_at: Time.parse(api_response["created"]),
      author: "Globo",
      author_link: "http://globo.com",
      claim_review_headline: api_response["content"]["title"],
      claim_review_body: api_response["content"]["summary"],
      claim_review_reviewed: nil,
      claim_review_image_url: claim_review_image_url_from_api_response(api_response),
      claim_review_result: result,
      claim_review_result_score: score,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: raw_claim_review
    }
  end
end