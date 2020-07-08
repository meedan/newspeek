# frozen_string_literal: true

# Parser for https://africacheck.org
class AfricaCheck < ReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://africacheck.org'
  end

  def fact_list_path(page = 1)
    "/latest-reports/page/#{page}/"
  end

  def url_extraction_search
    'div#main div.article-content h2 a'
  end

  def url_extractor(atag)
    atag.attributes['href'].value
  end

  def claim_result_text_map
    {
      'correct' => 1,
      'mostly-correct' => 0.75,
      'unproven' => 0.5,
      'misleading' => 0.5,
      'exaggerated' => 0.5,
      'downplayed' => 0.5,
      'incorrect' => 0,
      'checked' => 0.5
    }
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("img.attachment-articleMain").first.attributes["src"].value
  rescue StandardError => e
    Error.log(e)
  end

  def get_claim_review_from_raw_claim_review(raw_claim_review)
    raw_text = raw_claim_review["page"].search("script").select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}.first
    if raw_text
      JSON.parse(raw_text.text)
    end
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = get_claim_review_from_raw_claim_review(raw_claim_review)
    if claim_review
      {
        id: raw_claim_review['url'],
        created_at: Time.parse(claim_review["datePublished"]),
        author: claim_review["author"]["name"],
        author_link: claim_review["author"]["url"],
        claim_review_headline: raw_claim_review['page'].search('div#content h1.single-title').text,
        claim_review_body: claim_review["description"],
        claim_review_reviewed: claim_review["claimReviewed"],
        claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
        claim_review_result: claim_review["reviewRating"]["alternateName"].strip,
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
