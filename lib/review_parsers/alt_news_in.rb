class AltNewsIn < ReviewParser
  include PaginatedReviewClaims
  def hostname
    "https://www.altnews.in/"
  end

  def fact_list_path(page=1)
    "/page/#{page}/"
  end
  
  def url_extraction_search
    "div.herald-main-content h2.entry-title a"
  end

  def url_extractor(atag)
    atag.attributes["href"].value
  end
  
  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest(raw_claim["url"]),
      created_at: Time.parse(raw_claim["page"].search("div.herald-date").text),
      author: raw_claim["page"].search("span.vcard.author a").first.text,
      author_link: raw_claim["page"].search("span.vcard.author a").first.attributes["href"].value,
      claim_headline: raw_claim["page"].search("h1.entry-title").text,
      claim_body: raw_claim["page"].search("div.herald-entry-content p").text,
      claim_result: nil,
      claim_result_score: nil,
      claim_url: raw_claim["url"],
      raw_claim: {page: raw_claim["page"].to_s, url: raw_claim["url"]}
    }
  end
end