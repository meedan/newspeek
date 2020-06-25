# frozen_string_literal: true

class DataCommons < ReviewParser
  def get_claims
    raw_set = JSON.parse(File.read('../datasets/datacommons_claims.json'))['dataFeedElement'].sort_by do |c|
      begin
                                                                                                  c['item'][0]['url'].to_s
      rescue StandardError
        ''
                                                                                                end
    end .reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.collect do |claim|
        begin
                                  claim['item'][0]['url']
        rescue StandardError
          nil
                                end
      end .compact
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims = claim_set.reject do |claim|
        existing_urls.include?((begin
                                                          claim['item'][0]['url']
                                rescue StandardError
                                  nil
                                                        end))
      end
      next if new_claims.empty?

      process_claims(new_claims.collect { |raw_claim| parse_raw_claim(raw_claim) })
    end
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest((begin
                                           raw_claim['item'][0]['url']
                                         rescue StandardError
                                           ''
                                         end)),
      created_at: (begin
                     Time.parse(raw_claim['item'][0]['datePublished'])
                   rescue StandardError
                     nil
                   end),
      author: (begin
                 raw_claim['item'][0]['author']['name']
               rescue StandardError
                 nil
               end),
      author_link: (begin
                      raw_claim['item'][0]['author']['url']
                    rescue StandardError
                      nil
                    end),
      claim_headline: (begin
                         raw_claim['item'][0]['claimReviewed']
                       rescue StandardError
                         nil
                       end),
      claim_body: nil,
      claim_result: (begin
                       raw_claim['item'][0]['reviewRating']['alternateName']
                     rescue StandardError
                       nil
                     end),
      claim_result_score: parse_datacommons_rating(raw_claim),
      claim_url: (begin
                    raw_claim['item'][0]['url']
                  rescue StandardError
                    nil
                  end),
      raw_claim: raw_claim
    }
  end

  def parse_datacommons_rating(item)
    review_rating = item['reviewRating'] || {}
    best = review_rating['bestRating']
    worst = review_rating['worstRating']
    value = review_rating['ratingValue']
    if !best.nil? && !worst.nil? && !value.nil?
      (value.to_i - worst.to_i) / (best.to_i - worst.to_i).to_f if best.to_i - worst.to_i > 0
    elsif ([best, worst, value].count(nil) > 0) && ([best, worst, value].count(nil) != 3)
      value.to_i if best.nil? && worst.nil? && !value.nil?
    end
  end
end
