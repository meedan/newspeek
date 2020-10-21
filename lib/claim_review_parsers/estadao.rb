# frozen_string_literal: true

# Parser for https://politica.estadao.com.br
class Estadao < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://politica.estadao.com.br'
  end

  def fact_list_path(page = 1)
    "/blogs/estadao-verifica/page/#{page}/"
  end

  def url_extraction_search
    'div.paged-content section.custom-news div.box h3.third'
  end

  def url_extractor(atag)
    atag.parent.attributes["href"].value
  end
  
  def claim_review_image_url_from_claim_review_and_raw_page(claim_review, raw_page)
    claim_review &&
    claim_review["image"] &&
    claim_review["image"]["url"] &&
    claim_review["image"]["url"][0] ||
    raw_page.search("section.col-content img.size-full").first && 
    raw_page.search("section.col-content img.size-full").first.attributes["src"] &&
    raw_page.search("section.col-content img.size-full").first.attributes["src"].value
  end

  def claim_review_result_from_claim_review(claim_review)
    claim_review &&
    claim_review["reviewRating"] &&
    claim_review["reviewRating"]["alternateName"]
  end
  
  def claim_review_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("article.n--noticia__header h1.n--noticia__title").text
  end

  def claim_review_body_from_raw_claim_review(raw_claim_review)
    raw_claim_review["page"].search("div.n--noticia__content p").text
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], 0) || {}
    {
      id: raw_claim_review['url'],
      created_at: claim_review["datePublished"] && Time.parse(claim_review["datePublished"]),
      author: claim_review["author"] && claim_review["author"]["name"],
      author_link: claim_review["author"] && claim_review["author"]["url"],
      claim_review_headline: claim_review_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: claim_review_body_from_raw_claim_review(raw_claim_review),
      claim_review_reviewed: claim_review["claimReviewed"],
      claim_review_image_url: claim_review_image_url_from_claim_review_and_raw_page(claim_review, raw_claim_review["page"]),
      claim_review_result: claim_review_result_from_claim_review(claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end

