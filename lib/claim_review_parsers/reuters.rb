# frozen_string_literal: true

class Reuters < ClaimReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.reuters.com'
  end

  def fact_list_path(page = 1)
    "/news/archive/reuterscomservice?view=page&page=#{page}&pageSize=10"
  end

  def url_extraction_search
    'div.column1 section.module-content article.story div.story-content a'
  end

  def url_extractor(atag)
    hostname + atag.attributes['href'].value
  end

  def claim_result_from_headline(page)
    begin
      header = page.search('div.StandardArticleBody_body h3').first
      if header
        header.next_sibling.text.split('.').first
      end
    rescue StandardError => e
      Error.log(e)
    end
  end

  def claim_result_from_body_lead(page)
    found_text = page.search('div.StandardArticleBody_body p').find { |x| x.text.split(/[: ]/).first.casecmp('verdict').zero? }
    if found_text
      found_text.text.split(/[: ]/).reject(&:empty?)[1].split('.')[0].strip
    end
  end

  def claim_result_from_body_inline(page)
    words = page.search('div.StandardArticleBody_body p').text.downcase.split(/\W/).map(&:strip).reject(&:empty?)
    if words.index('verdict')
      words[words.index('verdict') + 1]
    end
  end

  def claim_result_from_page(page)
    claim_result_from_headline(page) ||
    claim_result_from_body_lead(page) ||
    claim_result_from_body_inline(page)
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_result = claim_result_from_page(raw_claim_review['page'])
    news_article = extract_ld_json_script_block(raw_claim_review["page"], 0)
    {
      id: raw_claim_review['url'],
      created_at: Time.parse(news_article["dateCreated"]),
      author: news_article["author"]["name"],
      author_link: nil,
      claim_review_headline: news_article["headline"],
      claim_review_body: raw_claim_review['page'].search('div.StandardArticleBody_body p').text,
      claim_review_image_url: news_article["image"]["url"],
      claim_review_result: claim_result,
      claim_review_result_score: claim_result.to_s.downcase.include?('true') ? 0 : 1,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: news_article
    }
  end
end
