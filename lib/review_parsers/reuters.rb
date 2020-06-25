class Reuters < ReviewParser
  include PaginatedReviewClaims
  def hostname
    "https://www.reuters.com"
  end

  def fact_list_path(page=1)
    "/news/archive/reuterscomservice?view=page&page=#{page}&pageSize=10"
  end
  
  def url_extraction_search
    "div.column1 section.module-content article.story div.story-content a"
  end

  def url_extractor(atag)
    hostname+atag.attributes["href"].value
  end

  def parse_raw_claim(raw_claim)
    claim_result = raw_claim["page"].search("div.StandardArticleBody_body h3").first.next_sibling.text.split(".").first rescue nil
    claim_result = raw_claim["page"].search("div.StandardArticleBody_body p").select{|x| x.text.split(/[: ]/).first.downcase == "verdict"}.first.text.split(/[: ]/).reject(&:empty?)[1].split(".")[0].strip rescue nil if claim_result.nil?
    if claim_result.nil?
      words = raw_claim["page"].search("div.StandardArticleBody_body p").text.downcase.split(/\W/).collect(&:strip).reject(&:empty?)
      claim_result = words[words.index("verdict")+1] rescue nil
    end
    {
      service_id: Digest::MD5.hexdigest(raw_claim["url"]),
      created_at: Time.parse(raw_claim["page"].search("div.ArticleHeader_date").text.split("/")[0..1].join("")),
      author: "Reuters Fact Check",
      author_link: nil,
      claim_headline: raw_claim["page"].search(".ArticleHeader_headline").text,
      claim_body: raw_claim["page"].search("div.StandardArticleBody_body p").text,
      claim_result: claim_result,
      claim_result_score: claim_result.to_s.downcase.include?("true") ? 0 : 1,
      claim_url: raw_claim["url"],
      raw_claim: {page: raw_claim["page"].to_s, url: raw_claim["url"]}
    }
  end
end
