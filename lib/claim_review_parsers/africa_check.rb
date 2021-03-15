# frozen_string_literal: true

# Parser for https://africacheck.org
class AfricaCheck < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://africacheck.org'
  end

  def fact_list_path(page = 1)
    "/fact-checks?field_article_type_value=reports&field_rated_value=All&field_country_value=All&sort_bef_combine=created_DESC&sort_by=created&sort_order=DESC&page=#{page}"
  end

  def url_extraction_search
    'article'
  end

  def url_extractor(atag)
    atag.attributes['about'] && atag.attributes['about'].value && hostname+atag.attributes['about'].value
  end

  def claim_review_image_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("img.attachment-articleMain").first.attributes["src"].value
  rescue StandardError => e
    Error.log(e)
  end

  def claim_review_reviewed_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.article-details__claims div").text
  end

  def rating_map
    {
      'correct' => 1.0,
      'mostly-correct' => 0.75,
      'unproven' => 0.5,
      'misleading' => 0.5,
      'exaggerated' => 0.5,
      'downplayed' => 0.5,
      'incorrect' => 0,
      'checked' => 0.5
    }
  end

  def rating_from_raw_claim_review(raw_claim_review)
    if raw_claim_review && raw_claim_review["page"]
      rating_text = raw_claim_review["page"].search('div.article-details__verdict div').first&.attributes["class"].value.split(" ").select{|x| x.include?("rating--")}.first.split("--").last
      [rating_text, rating_map[rating_text]]
    else
      [nil, nil]
    end
  end

  def extract_news_article_from_ld_json_script_block(ld_json_script_block)
    ld_json_script_block &&
    ld_json_script_block["@graph"] &&
    ld_json_script_block["@graph"].select{|x| x["@type"] == "NewsArticle"}[0]
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = extract_news_article_from_ld_json_script_block(extract_ld_json_script_block(raw_claim_review["page"], 0))
    claim_review_result, claim_review_result_score = rating_from_raw_claim_review(raw_claim_review)
    if claim_review
      {
        id: raw_claim_review['url'],
        created_at: Time.parse(claim_review["datePublished"]||claim_review["dateModified"]),
        author: claim_review["author"]["name"],
        author_link: claim_review["author"]["url"],
        claim_review_headline: claim_review["headline"],
        claim_review_body: claim_review["description"],
        claim_review_reviewed: claim_review_reviewed_from_raw_claim_review(raw_claim_review),
        claim_review_image_url: claim_review["image"]["url"],
        claim_review_result: claim_review_result,
        claim_review_result_score: claim_review_result_score,
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