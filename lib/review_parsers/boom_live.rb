class BoomLive < ReviewParser
  def hostname
    "http://boomlive.in/"
  end

  def get_path(path)
    JSON.parse(
      RestClient.get(
        hostname+path,
        {"s-id": SETTINGS["boom_live_api_key"]}
      )
    )
  end

  def fact_categories
    {
      "/fact-file" => 15,
      "/factcheck" => 16,
      "/fake-news" => 17,
      "/fast-check" => 18,
    }
  end
  
  def get_stories_by_category(category_id, page=1, count=20)
    get_path("/dev/h-api/news?catId=#{category_id}&startIndex=#{(page-1)*count}&count=#{count}")
  end

  def get_new_stories_by_category(category_id, page)
    stories = get_stories_by_category(category_id, page)["news"]
    existing_urls = ClaimReview.existing_urls(stories.collect{|s| s["url"]}, self.class.service)
    stories.select{|s| !existing_urls.include?(s["url"])}
  end

  def get_all_stories_by_category(category_id)
    page = 1
    stories = get_new_stories_by_category(category_id, page)
    all_stories = stories
    while !stories.empty?
      page += 1
      stories = get_new_stories_by_category(category_id, page)
      stories.collect{|s| all_stories << s}
    end
    Hash[all_stories.collect{|s| [s["url"], s]}]
  end

  def get_claims
    story_map = {}
    fact_categories.each do |category_path, category_id|
      story_map = story_map.merge(get_all_stories_by_category(category_id))
    end
    Parallel.map(story_map.values, in_processes: 5, progress: "Downloading #{self.class} Corpus") { |raw_claim|
      parse_raw_claim(raw_claim)
    }.compact
  end
  
  def get_claim_result_for_raw_claim(raw_claim)
    Nokogiri.parse(
      RestClient.get(raw_claim["url"])
    ).search("div.claim-review-block div.claim-value").select{|x| 
      x.text.downcase.include?("fact check")
    }.first.search("span.value").first.text rescue nil
  end

  def parse_raw_claim(raw_claim)
    claim_result = get_claim_result_for_raw_claim(raw_claim)
    {
      service_id: raw_claim["newsId"],
      created_at: Time.parse(raw_claim["date_created"]),
      author: raw_claim["source"],
      author_link: nil,
      claim_headline: raw_claim["heading"],
      claim_body: Nokogiri.parse("<html>"+raw_claim["story"]+"</html>").text,
      claim_result: claim_result,
      claim_result_score: claim_result.to_s.downcase.include?("false") ? 0 : 1,
      claim_url: raw_claim["url"],
      raw_claim: raw_claim
    }
  end
end