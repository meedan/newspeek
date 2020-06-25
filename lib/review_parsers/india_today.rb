class IndiaToday < ReviewParser
  include PaginatedReviewClaims
  def hostname
    "https://www.indiatoday.in"
  end

  def fact_list_path(page=1)
    #they start with 0-indexes, so push back internally
    "/fact-check?page=#{page-1}"
  end

  def url_extraction_search
    "div.detail h2 a"
  end

  def url_extractor(atag)
    hostname+atag.attributes["href"].value
  end

  def claim_result_and_score_from_page(page)
    image_filename = page.search("div.factcheck-result-img img").first.attributes["src"].value.split("/").last rescue nil
    {
      "1c.gif" => ["Partly True", 0.66], 
      "2c.gif" => ["Partly False", 0.33], 
      "3c.gif" => ["False", 0.0], 
    }[image_filename] || ["Inconclusive", 0.5]
  end

  def time_from_page(page)
    time = Time.parse(.search("div.byline div.profile-detail dt.pubdata").text) rescue nil
    time = Time.parse(raw_claim["page"].search("p.upload-date span.date-display-single").first.attributes["content"].value) rescue nil if time.nil?
    time
  end

  def parse_raw_claim(raw_claim)
    claim_result, claim_result_score = claim_result_and_score_from_page(raw_claim["page"])
    {
      service_id: Digest::MD5.hexdigest(raw_claim["url"]),
      created_at: time_from_page(raw_claim["page"]),
      author: raw_claim["page"].search("div.byline dl.profile-byline dt.title").text.strip,
      author_link: nil,
      claim_headline: raw_claim["page"].search("div.story-section h1").text.strip,
      claim_body: raw_claim["page"].search("div.story-right p").text.strip,
      claim_result: claim_result,
      claim_result_score: claim_result_score,
      claim_url: raw_claim["url"],
      raw_claim: {url: raw_claim["url"], page: raw_claim["page"].to_s}
    }
  end
end
