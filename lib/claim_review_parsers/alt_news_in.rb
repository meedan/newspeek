# frozen_string_literal: true

# Parser for https://www.altnews.in
class AltNewsIn < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.altnews.in/'
  end

  def fact_list_path(page = 1)
    "/page/#{page}/"
  end

  def url_extraction_search
    'div.herald-main-content h2.entry-title a'
  end

  def url_extractor(atag)
    atag.attributes['href'].value
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0, "script.yoast-schema-graph")
    claim_review_graph_article = claim_review["@graph"].select{|x| x["@type"] == "Article"}[0]
    claim_review_graph_author = claim_review["@graph"].select{|x| x["@type"] == ["Person"]}[0]
    {
      id: raw_claim_review['url'],
      created_at: Time.parse(claim_review_graph_article["datePublished"]),
      author: claim_review_graph_author["name"],
      author_link: claim_review_graph_author["url"],
      claim_review_headline: claim_review_graph_article["headline"],
      claim_review_body: raw_claim_review['page'].search('div.herald-entry-content p').text,
      claim_review_reviewed: nil,
      claim_review_result: nil,
      claim_review_result_score: nil,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end
