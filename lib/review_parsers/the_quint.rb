class TheQuint < ReviewParser
  def hostname
    "https://www.thequint.com"
  end

  def fact_list_path(page=1)
    "/news/webqoof/#{page}"
  end

  def get_claims_for_page(page=1)
    JSON.parse(Nokogiri.parse(RestClient.get(hostname+fact_list_path(page))).search("script").select{|x| x.text.include?("app.render")}.first.text.split("app.render(")[1].split(");\n      });\n    ")[0])["args"]["collection"]["items"]
  end

  def get_new_claims_for_page(page=1)
    claims = get_claims_for_page(page)
    existing_urls = ClaimReview.existing_urls(claims.collect{|claim| claim["url"]}.compact, self.class.service)
    claims.select{|claim| !existing_urls.include?(claim["url"])}
  end

  def get_claims
    page = 1
    raw_claims = get_new_claims_for_page(page)
    all_raw_claims = raw_claims
    while !raw_claims.empty?
      page += 1
      yield raw_claims
      raw_claims = get_new_claims_for_page(page)
    end
    yield raw_claims
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: raw_claim["story-content-id"],
      created_at: Time.at(raw_claim["first-published-at"]/1000.0),
      author: (raw_claim["authors"][0]["name"] rescue nil),
      author_link: (raw_claim["authors"][0]["avatar-url"] rescue nil),
      claim_headline: raw_claim["headline"],
      claim_body:  Nokogiri.parse("<html>"+raw_claim["cards"].collect{|x| x["story-elements"]}.flatten.collect{|x| x["text"]}.join("")+"</html>").text,
      claim_result: (raw_claim["metadata"]["story-attributes"]["factcheck"].first rescue nil),
      claim_result_score: (raw_claim["metadata"]["story-attributes"]["claimreviewrating"].first.to_i rescue nil),
      claim_url: raw_claim["url"],
      raw_claim: raw_claim
    }
  end
end
