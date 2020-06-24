class GoogleFactCheck < ReviewParser
  def host
    "https://factchecktools.googleapis.com"
  end
  
  def path
    "/v1alpha1/claims:search"
  end

  def get(path, params)
    retry_count = 0
    begin
      url = host+path+"?"+URI.encode_www_form(params.merge(key: SETTINGS["google_api_key"]))
      JSON.parse(
        RestClient.get(
          url
        ).body
      )
    rescue RestClient::ServiceUnavailable
      retry_count += 1
      sleep(1)
      retry if retry_count < 10
    end
  end

  def get_query(query, offset=0)
    get(path, {query: query, pageSize: 100, offset: offset})
  end


  def get_publisher(publisher, offset=0)
    get(path, {reviewPublisherSiteFilter: publisher, pageSize: 100, offset: offset})
  end

  def get_all_for_query(query)
    results_page = get_query(query)["claims"]
    results = results_page||[]
    offset = 0
    while results_page && !results_page.empty?
      offset += 100
      results_page = get_query(query, offset)["claims"]||[]
      results_page.each do |r|
        results << r
      end
    end
    results
  end
  
  def get_new_from_publisher(publisher, offset)
    claims = get_publisher(publisher, offset)["claims"]||[]
    existing_urls = ClaimReview.existing_urls(claims.collect{|claim| claim["claimReview"].first["url"] rescue nil}.compact, self.class.service)
    claims.select{|claim| claim["claimReview"] && claim["claimReview"].first && !existing_urls.include?(claim["claimReview"].first["url"])}
  end

  def get_all_for_publisher(publisher)
    offset = 0
    results_page = get_new_from_publisher(publisher, offset)
    results = results_page
    while !results_page.empty?
      offset += 100
      results_page = get_new_from_publisher(publisher, offset)
      results_page.each do |r|
        results << r
      end
    end
    results
  end

  def snowball_publishers_from_queries(queries)
    queries.collect do |query|
      snowball_publishers_from_query(query)
    end.flatten.uniq
  end

  def snowball_publishers_from_query(query="election")
    claims = Hash[get_all_for_query(query).collect{|r| [r["claimReview"].first["url"], r]}]
    claims.values.collect{|r| r["claimReview"].collect{|cr| cr["publisher"]["site"]}}.flatten.uniq
  end
  
  def snowball_claims_from_publishers(publishers)
    publisher_results = Parallel.map(publishers, in_processes: 2, progress: "Downloading data from all publishers") { |publisher| 
      Hash[publisher, Hash[get_all_for_publisher(publisher).collect { |claim|
        [claim["claimReview"].first["url"], claim] rescue nil
      }.compact]]
    }
    claims = {}
    publisher_results.collect(&:values).each do |results|
      results.each do |resultset|
        claims = claims.merge(resultset)
      end
    end
    return claims
  end

  def default_queries
    ["选举", "elección", "election", "انتخاب", "चुनाव", "নির্বাচন", "eleição", "выборы", "選挙", "ਚੋਣ", "निवडणूक", "ఎన్నికల", "seçim", "선거", "élection", "Wahl", "cuộc bầu cử", "தேர்தல்", "انتخابات"]
  end

  def get_claims(seed_queries=default_queries)
    claims = snowball_claims_from_publishers(
      snowball_publishers_from_queries(
        seed_queries
      )
    )
    claims.values.collect{|raw_claim| parse_raw_claim(raw_claim)}
  end
  
  def parse_raw_claim(raw_claim)
    time = Time.parse(raw_claim["claimReview"][0]["reviewDate"] || raw_claim["claimDate"]) rescue nil
    {
      service_id: Digest::MD5.hexdigest(raw_claim["claimReview"][0]["url"]),
      created_at: time,
      author: raw_claim["claimReview"][0]["publisher"]["name"],
      author_link: raw_claim["claimReview"][0]["publisher"]["site"],
      claim_headline: raw_claim["claimReview"][0]["title"],
      claim_body: raw_claim["text"],
      claim_result: raw_claim["claimReview"][0]["textualRating"],
      claim_result_score: nil,
      claim_url: raw_claim["claimReview"][0]["url"],
      raw_claim: raw_claim
    }
  end
end