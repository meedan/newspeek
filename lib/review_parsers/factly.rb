# frozen_string_literal: true

# Parser for https://factly.in
class Factly < ReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://factly.in'
  end

  def fact_list_path(page = 1)
    "/category/fact-check/page/#{page}/"
  end

  def url_extraction_search
    'div.main-content div.column h2.post-title a'
  end

  def url_extractor(atag)
    atag.attributes['href'].value
  end

  def get_fact_index_from_page(page)
    bold_blockquotes = page.search('div.post-content blockquote p strong')
    found = bold_blockquotes.each_with_index.to_a.reverse.find { |x, _i| x.text.downcase.include?('fact:') }
    [found && found.last, bold_blockquotes]
  end

  def get_claim_result_from_page(page)
    fact_result = nil
    fact_index, bold_blockquotes = get_fact_index_from_page(page)
    fact_result = bold_blockquotes[fact_index + 1].text if fact_index
    return fact_result
  end

  def parse_raw_claim_review(raw_claim_review)
    article = extract_ld_json_script_block(raw_claim_review["page"], -1)
    {
      id: raw_claim_review['url'],
      created_at: Time.parse(article["datePublished"]),
      author: article["author"]["name"],
      author_link: raw_claim_review['page'].search('span.posted-by span.reviewer a').first.attributes['href'].value,
      claim_review_headline: article["headline"],
      claim_review_body: raw_claim_review['page'].search('div.post-content p').text,
      claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
      claim_review_result: get_claim_result_from_page(raw_claim_review['page']),
      claim_review_result_score: nil,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: article
    }
  end
end
