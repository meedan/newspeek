class AfricaCheck < ReviewParser
  include PaginatedReviewClaims
  def hostname
    "https://africacheck.org"
  end

  def fact_list_path(page=1)
    "/latest-reports/page/#{page}/"
  end

  def url_extraction_search
    "div#main div.article-content h2 a"
  end

  def url_extractor(atag)
    atag.attributes["href"].value
  end

  def claim_result_text_map
    {
      "correct" => 1,
      "mostly-correct" => 0.75,
      "unproven" => 0.5,
      "misleading" => 0.5,
      "exaggerated" => 0.5,
      "downplayed" => 0.5,
      "incorrect" => 0,
      "checked" => 0.5
    }
  end

  def parse_raw_claim(raw_claim)
    claim_result = raw_claim["page"].search("div#content div.verdict-stamp").text
    {
      service_id: Digest::MD5.hexdigest(raw_claim["url"]),
      created_at: Time.parse(raw_claim["page"].search("div#content div.time-subscribe-wrapper time").first.attributes["datetime"].value),
      author: raw_claim["page"].search("div#content div.entry-meta p.editor-name").text.split(" by ")[1],
      author_link: nil,
      claim_headline: raw_claim["page"].search("div#content h1.single-title").text,
      claim_body: raw_claim["page"].search("div#content article section.entry-content").text,
      claim_result: claim_result,
      claim_result_score: claim_result_text_map[claim_result],
      claim_url: raw_claim["url"],
      raw_claim: {page: raw_claim["page"].to_s, url: raw_claim["url"]}
    }
  end
end
