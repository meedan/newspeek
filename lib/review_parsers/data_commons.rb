# frozen_string_literal: true

class DataCommons < ReviewParser
  def get_claims
    raw_set = JSON.parse(File.read('../datasets/datacommons_claims.json'))['dataFeedElement'].sort_by do |c|
      c['item'][0]['url'].to_s
              rescue StandardError
                ''
    end.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.map do |claim|
        claim['item'][0]['url']
             rescue StandardError
               nil
      end.compact
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims =
        claim_set.reject do |claim|
          existing_urls.include?((begin
                                                            claim['item'][0]['url']
                                  rescue StandardError
                                    nil
                                                          end))
        end
      next if new_claims.empty?

      process_claims(new_claims.map { |raw_claim| parse_raw_claim(raw_claim) })
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
      if Integer(best, 10) - Integer(worst, 10) > 0
        (Integer(value, 10) - Integer(worst, 10)) / Float((Integer(best, 10) - Integer(worst, 10)))
      end
    elsif ([best, worst, value].count(nil) > 0) && ([best, worst, value].count(nil) != 3)
      Integer(value, 10) if best.nil? && worst.nil? && !value.nil?
    end
  end
end
