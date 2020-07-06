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

  def claim_result_and_score_from_page(page)
    image_filename =
      begin
                            page.search('div.factcheck-result-img img').first.attributes['src'].value.split('/').last
      rescue StandardError
        nil
                          end
    {
      "1c.gif": ['Partly True', 0.66],
      "2c.gif": ['Partly False', 0.33],
      "3c.gif": ['False', 0.0]
    }[image_filename] || ['Inconclusive', 0.5]
  end

  def time_from_page_meta_tag(page, att_name, att_value)
    begin
      Time.parse(page.search('meta').select { |x| x.attributes[att_name] && x.attributes[att_name].value == att_value }.first.attributes['content'].value)
    rescue StandardError
      nil
    end
  end

  def time_from_pubdata_text(page)
    begin
      time = Time.parse(page.search('div.byline div.profile-detail dt.pubdata').text)
    rescue StandardError
      nil
    end
  end
  
  def time_from_upload_date(page)
    begin
      time = Time.parse(page.search('p.upload-date span.date-display-single').first.attributes['content'].value)
    rescue StandardError
      nil
    end
  end

  def time_from_page(page)
    time_from_page_meta_tag(page, 'itemprop', 'datePublished') ||
    time_from_page_meta_tag(page, 'itemprop', 'dateModified') ||
    time_from_page_meta_tag(page, 'property', 'og:updated_time') ||
    time_from_pubdata_text(page) ||
    time_from_upload_date(page)
  end

  def parse_raw_claim(raw_claim)
    claim_result, claim_result_score = IndiaToday.new.claim_result_and_score_from_page(raw_claim['page'])
    {
      id: Digest::MD5.hexdigest(raw_claim['url']),
      created_at: IndiaToday.new.time_from_page(raw_claim['page']),
      author: raw_claim['page'].search('div.byline dl.profile-byline dt.title').text.strip,
      author_link: nil,
      claim_headline: raw_claim['page'].search('div.story-section h1').text.strip,
      claim_body: raw_claim['page'].search('div.story-right p').text.strip,
      claim_result: claim_result,
      claim_result_score: claim_result_score,
      claim_url: raw_claim['url'],
      rarw_claim: { url: raw_claim['url'], page: raw_claim['page'].to_s }
    }
  end
end
