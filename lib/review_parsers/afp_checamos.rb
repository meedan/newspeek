class AFPChecamos < ReviewParser
  include PaginatedReviewClaims
  def hostname
    "https://checamos.afp.com"
  end

  def fact_list_path(page=1)
    #appears to be zero-indexed
    "/?page=#{page-1}"
  end
  
  def url_extraction_search
    "div.view-content div.content-teaser h2.content-title a"
  end

  def url_extractor(atag)
    hostname+atag.attributes["href"].value
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest(raw_claim["url"]),
      created_at: Time.at(raw_claim["page"].search("div.main-post div.content-meta span.meta-date span").first.attributes["timestamp"].value.to_i),
      author: raw_claim["page"].search("div.main-post div.content-meta span.meta-author").text.strip,
      author_link: (raw_claim["page"].search("div.main-post div.content-meta span.meta-author a").first.attributes["href"].value rescue nil),
      claim_headline: raw_claim["page"].search("div.main-post h1.content-title").text.strip,
      claim_body: raw_claim["page"].search("div.main-post div.article-entry").text.strip,
      claim_result: nil,
      claim_result_score: nil,
      claim_url: raw_claim["url"],
      raw_claim: {page: raw_claim["page"].to_s, url: raw_claim["url"]}
    }
  end
end