class DataCommons < ReviewParser
  def get_claims
    raw_set = JSON.parse(File.read("../datasets/datacommons_claims.json"))["dataFeedElement"].sort_by{|c| c["item"][0]["url"].to_s rescue ""}.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.collect{|claim| claim["item"][0]["url"] rescue nil}.compact
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims = claim_set.select{|claim| !existing_urls.include?((claim["item"][0]["url"] rescue nil))}
      next if new_claims.empty?
      process_claims(new_claims.collect{|raw_claim| parse_raw_claim(raw_claim)})
    end
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest((raw_claim["item"][0]["url"] rescue "")),
      created_at: (Time.parse(raw_claim["item"][0]["datePublished"]) rescue nil),
      author: (raw_claim["item"][0]["author"]["name"] rescue nil),
      author_link: (raw_claim["item"][0]["author"]["url"] rescue nil),
      claim_headline: (raw_claim["item"][0]["claimReviewed"] rescue nil),
      claim_body: nil,
      claim_result: (raw_claim["item"][0]["reviewRating"]["alternateName"] rescue nil),
      claim_result_score: parse_datacommons_rating(raw_claim),
      claim_url: (raw_claim["item"][0]["url"] rescue nil),
      raw_claim: raw_claim
    }
  end
  
  def parse_datacommons_rating(item)
    review_rating = item["reviewRating"]||{}
    best = review_rating["bestRating"]
    worst = review_rating["worstRating"]
    value = review_rating["ratingValue"]
    if !best.nil? && !worst.nil? && !value.nil?
      if best.to_i - worst.to_i > 0
        return (value.to_i - worst.to_i) / (best.to_i - worst.to_i).to_f
      else
        return nil
      end
    elsif [best, worst, value].count(nil) > 0 and [best, worst, value].count(nil) != 3
      if best.nil? and worst.nil? and !value.nil?
        return value.to_i
      end
    else
      return nil
    end
  end
end