# frozen_string_literal: true

# Parser for https://www.factcrescendo.com/
class FactCrescendo < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.factcrescendo.com/'
  end

  def fact_list_path(page = 1)
    "/archives/page/#{page}/"
  end

  def url_extraction_search
    'article.post div.np-article-thumb a'
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    Time.parse(raw_claim_review["page"].search("time.entry-date").first.attributes["datetime"].value)
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("span.byline span.author").collect(&:text).collect(&:strip).first
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("span.byline span.author a").collect{|x| x.attributes["href"].value}.first
  end

  def claim_review_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#main h1.entry-title").text
  end

  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.entry-content p").text
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("figure.wp-block-image img")[0].attributes["src"].value
  end

  def claim_review_reviewed_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.container p").first.text.gsub("Title:", "")
  end

  def claim_review_result_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.container p").last.text.gsub("Result:", "").strip
  end

  def claim_review_result_score_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.container p").last.text.gsub("Result:", "").strip.include?("True") ? 1 : 0
  end

  def parse_raw_claim_review(raw_claim_review)
    {
      id: raw_claim_review['url'],
      created_at: created_at_from_raw_claim_review(raw_claim_review),
      author: author_from_raw_claim_review(raw_claim_review),
      author_link: author_link_from_raw_claim_review(raw_claim_review),
      claim_review_headline: claim_review_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: claim_review_body_from_raw_claim_review(raw_claim_review),
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_reviewed: claim_review_reviewed_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_review_result_from_raw_claim_review(raw_claim_review),
      claim_review_result_score: claim_review_result_score_from_raw_claim_review(raw_claim_review),
      claim_review_url: raw_claim_review['url']
    }
  end
end
