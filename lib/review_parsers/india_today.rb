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

  def image_filename_from_page(page)
    page.search('div.factcheck-result-img img').first.attributes['src'].value.split('/').last
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_and_score_from_page(page)
    image_filename = image_filename_from_page(page)
    {
      "1c.gif": ['Partly True', 0.66],
      "2c.gif": ['Partly False', 0.33],
      "3c.gif": ['False', 0.0]
    }[image_filename] || ['Inconclusive', 0.5]
  end

  def time_from_page_meta_tag(page, att_name, att_value)
    begin
      Time.parse(page.search('meta').select { |x| x.attributes[att_name] && x.attributes[att_name].value == att_value }.first.attributes['content'].value)
    rescue StandardError => e
      Error.log(e)
    end
  end

  def time_from_pubdata_text(page)
    begin
      time = Time.parse(page.search('div.byline div.profile-detail dt.pubdata').text)
    rescue StandardError => e
      Error.log(e)
    end
  end
  
  def time_from_upload_date(page)
    begin
      time = Time.parse(page.search('p.upload-date span.date-display-single').first.attributes['content'].value)
    rescue StandardError => e
      Error.log(e)
    end
  end

  def time_from_page(page)
    time_from_page_meta_tag(page, 'itemprop', 'datePublished') ||
    time_from_page_meta_tag(page, 'itemprop', 'dateModified') ||
    time_from_page_meta_tag(page, 'property', 'og:updated_time') ||
    time_from_pubdata_text(page) ||
    time_from_upload_date(page)
  end

  def claim_review_from_raw_claim_review(raw_claim_review)
    JSON.parse(raw_claim_review["page"].search("script").select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}.select{|x| JSON.parse(x.text)["@type"] == "ClaimReview"}.first.text)
  rescue JSON::ParserError, NoMethodError
    #send back stubbed claim_review when there's a parse error or no verifiable ClaimReview object in the document
    {}
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_review = claim_review_from_raw_claim_review(raw_claim_review)
    if !claim_review.empty?
      {
        id: Digest::MD5.hexdigest(raw_claim_review['url']),
        created_at: Time.parse(claim_review["datePublished"]),
        author: claim_review["author"]["name"],
        author_link: nil,
        claim_review_headline: raw_claim_review['page'].search('div.story-section h1').text.strip,
        claim_review_body: raw_claim_review['page'].search('div.story-right p').text.strip,
        claim_review_image_url: claim_review_image_url_from_raw_claim_review(raw_claim_review),
        claim_review_reviewed: claim_review["claimReviewed"],
        claim_review_result: claim_review["reviewRating"]["alternateName"],
        claim_review_result_score: claim_result_score_from_raw_claim_review(claim_review),
        claim_review_url: raw_claim_review['url'],
        raw_claim: { url: claim_review, page: raw_claim_review['page'].to_s }
      }
    else
      {
        id: Digest::MD5.hexdigest(raw_claim_review['url']),
      }
    end
  end
end
