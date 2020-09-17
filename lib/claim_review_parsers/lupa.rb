# frozen_string_literal: true

# Parser for https://piaui.folha.uol.com.br
class Lupa < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://piaui.folha.uol.com.br'
  end

  def fact_list_path(page = 1)
    "/lupa/tag/fake-news/page/#{page}/"
  end

  def url_extraction_search
    'div.main-content div.blocos-column div.lista-noticias div.bloco h2.bloco-title a'
  end

  def url_extractor(atag)
    atag.attributes['href'].value
  end

  def created_at_from_news_article_or_claim_review(claim_review, reportage_news_article)
    article_time = Time.parse(reportage_news_article["datePublished"]) rescue nil
    review_time = Time.parse(claim_review["datePublished"]) rescue nil
    article_time || review_time
  end

  def author_from_news_article_or_claim_review(claim_review, reportage_news_article)
    reportage_news_article["author"] &&
    reportage_news_article["author"][0] &&
    reportage_news_article["author"][0]["name"] ||
    claim_review["author"] &&
    claim_review["author"]["name"]
  end

  def author_link_from_news_article_or_claim_review(claim_review, reportage_news_article)
    reportage_news_article["author"] &&
    reportage_news_article["author"][0] &&
    reportage_news_article["author"][0]["sameAs"] ||
    claim_review["author"] &&
    claim_review["author"]["url"]
  end
  
  def claim_review_result_from_claim_review(claim_review)
    claim_review["reviewRating"] &&
    claim_review["reviewRating"]["alternateName"] &&
    claim_review["reviewRating"]["alternateName"].strip
  end

  def parse_raw_claim_review(raw_claim_review)
    reportage_news_article = extract_ld_json_script_block(raw_claim_review["page"], 1)
    claim_review = extract_ld_json_script_block(raw_claim_review["page"], -1)
    {
      id: raw_claim_review['url'],
      created_at: created_at_from_news_article_or_claim_review(claim_review, reportage_news_article),
      author: author_from_news_article_or_claim_review(claim_review, reportage_news_article),
      author_link: author_link_from_news_article_or_claim_review(claim_review, reportage_news_article),
      claim_review_headline: reportage_news_article["headline"],
      claim_review_body: raw_claim_review['page'].search('div.wrapper div.post-inner p').text,
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: claim_review_result_from_claim_review(claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
      claim_review_reviewed: claim_review["claimReviewed"],
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: claim_review
    }
  end
end
