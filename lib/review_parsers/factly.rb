# frozen_string_literal: true

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

  def parse_raw_claim(raw_claim)
    bold_blockquotes = raw_claim['page'].search('div.post-content blockquote p strong')
    fact_index = begin
                   bold_blockquotes.each_with_index.select { |x, _i| x.text.downcase.include?('fact:') }.last.last
                 rescue StandardError
                   nil
                 end
    fact_result = nil
    fact_result = bold_blockquotes[fact_index + 1].text if fact_index
    {
      service_id: Digest::MD5.hexdigest(raw_claim['url']),
      created_at: Time.parse(raw_claim['page'].search('span.posted-on span.dtreviewed time').text),
      author: raw_claim['page'].search('span.posted-by span.reviewer').text,
      author_link: raw_claim['page'].search('span.posted-by span.reviewer a').first.attributes['href'].value,
      claim_headline: raw_claim['page'].search('h1.post-title').text,
      claim_body: raw_claim['page'].search('div.post-content p').text,
      claim_result: fact_result,
      claim_result_score: nil,
      claim_url: raw_claim['url'],
      raw_claim: { page: raw_claim['page'].to_s, url: raw_claim['url'] }
    }
  end
end
