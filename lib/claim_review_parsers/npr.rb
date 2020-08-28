# frozen_string_literal: true

# Parser for https://www.npr.org
class NPR < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.npr.org'
  end

  def fact_list_path(page = 1)
    "/sections/politics-fact-check/archive?start=#{(page-1)*15}"
  end

  def url_extraction_search
    'div.item-info h2.title a'
  end

  def url_extractor(atag)
    hostname + atag.attributes['href'].value
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    Time.parse(raw_claim_review["page"].search("time").first.attributes["datetime"].value)
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search(".byline__name").collect(&:text).collect(&:strip).first
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search(".byline__name a").collect{|x| x.attributes["href"].value}.first
  end

  def claim_review_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.storytitle h1").text
  end

  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div#storytext p").text
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.imagewrap img")[0].attributes["src"].value
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
      claim_review_url: raw_claim_review['url']
    }
  end
end