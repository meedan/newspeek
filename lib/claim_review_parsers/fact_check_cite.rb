# frozen_string_literal: true

class FactCheckCite < ClaimReviewParser
  include PaginatedReviewClaims
  def initialize(cursor_back_to_date = nil, overwrite_existing_claims=false)
    super(cursor_back_to_date, overwrite_existing_claims)
    @fact_list_page_parser = 'json'
    @raw_response = {}
  end

  def hostname
    'https://factcheck.cite.org.zw/wp-json/csco/v1/more-posts'
  end

  def request_fact_page(page, limit)
    RestClient::Request.execute(
      method: :post,
      url: self.hostname,
      payload: {page: page, posts_per_page: limit, action: "csco_ajax_load_more"},
    )
  end

  def url_from_raw_article(raw_article)
    raw_article.search("a").first.attributes["href"].value
  end

  def get_page_urls(page, limit=10)
    Nokogiri.parse("<html><body>"+JSON.parse(
      request_fact_page(page, limit)
    )["data"]["content"]+"</body></html>").search("article").collect{|a| url_from_raw_article(a)}
  end

  def get_new_fact_page_urls(page)
    urls = get_page_urls(page)
    urls-get_existing_urls(urls)
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary span.cs-author").text rescue nil
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary div.cs-meta-date").text rescue nil
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary a.cs-meta-author-inner").first.attributes["href"].value rescue nil
  end

  def claim_review_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary h1.cs-entry__title").text rescue nil
  end

  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary div.entry-content p").collect(&:text).join("\n") rescue nil
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("figure.cs-entry__post-media img").first.attributes["data-pk-src"].value rescue nil
  end

  def claim_review_result_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#primary div.verdict img").first.attributes["src"].value.split("/").last.gsub(".png", "").capitalize rescue nil
  end

  def created_at_from_claim_review_or_raw_claim_review(claim_review, raw_claim_review)
    Time.parse(claim_review['datePublished'] || created_at_from_raw_claim_review(raw_claim_review)) rescue nil
  end
  def parse_raw_claim_review(raw_claim_review)
    return {} if raw_claim_review["url"].include?("https://factcheck.cite.org.zw/category/")
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0)[0] rescue {}
    {
      id: raw_claim_review['url'],
      created_at: created_at_from_claim_review_or_raw_claim_review(claim_review, raw_claim_review),
      author: author_from_raw_claim_review(raw_claim_review),
      author_link: author_link_from_raw_claim_review(raw_claim_review),
      claim_review_headline: claim_review_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: claim_review_body_from_raw_claim_review(raw_claim_review),
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_review_result_from_raw_claim_review(raw_claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
    
  end
end