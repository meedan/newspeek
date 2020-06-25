# frozen_string_literal: true

class IndiaToday < ReviewParser
  include PaginatedReviewClaims
  def hostname
    'https://www.indiatoday.in'
  end

  def fact_list_path(page = 1)
    # they start with 0-indexes, so push back internally
    "/fact-check?page=#{page - 1}"
  end

  def url_extraction_search
    'div.detail h2 a'
  end

  def url_extractor(atag)
    hostname + atag.attributes['href'].value
  end

  def parse_raw_claim(raw_claim)
    image_filename =
      begin
                            raw_claim['page'].search('div.factcheck-result-img img').first.attributes['src'].value.split('/').last
      rescue StandardError
        nil
                          end
    if image_filename == '1c.gif'
      claim_result = 'Partly True'
      claim_result_score = 0.66
    elsif image_filename == '2c.gif'
      claim_result = 'Partly False'
      claim_result_score = 0.33
    elsif image_filename == '3c.gif'
      claim_result = 'False'
      claim_result_score = 0
    elsif image_filename.nil?
      claim_result = 'Inconclusive'
      claim_result_score = 0.5
    end
    time =
      begin
                  Time.parse(raw_claim['page'].search('div.byline div.profile-detail dt.pubdata').text)
      rescue StandardError
        nil
                end
    if time.nil?
      time =
        begin
                      Time.parse(raw_claim['page'].search('p.upload-date span.date-display-single').first.attributes['content'].value)
        rescue StandardError
          nil
                    end
    end
    binding.pry if time.nil?
    {
      service_id: Digest::MD5.hexdigest(raw_claim['url']),
      created_at: time,
      author: raw_claim['page'].search('div.byline dl.profile-byline dt.title').text.strip,
      author_link: nil,
      claim_headline: raw_claim['page'].search('div.story-section h1').text.strip,
      claim_body: raw_claim['page'].search('div.story-right p').text.strip,
      claim_result: claim_result,
      claim_result_score: claim_result_score,
      claim_url: raw_claim['url'],
      raw_claim: { url: raw_claim['url'], page: raw_claim['page'].to_s }
    }
  end
end
