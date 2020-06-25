# frozen_string_literal: true

class Tattle < ReviewParser
  def get_claims
    raw_set = JSON.parse(File.read('../datasets/tattle_claims.json')).sort_by { |c| c['Post URL'].to_s }.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.collect do |claim|
        begin
                                  claim['Post URL']
        rescue StandardError
          nil
                                end
      end .compact
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims = claim_set.reject { |claim| existing_urls.include?(claim['Post URL']) }
      next if new_claims.empty?

      process_claims(new_claims.collect { |raw_claim| parse_raw_claim(raw_claim) })
    end
  end

  def parse_raw_claim(raw_claim)
    {
      service_id: Digest::MD5.hexdigest(raw_claim['Post URL']),
      created_at: Time.parse(raw_claim['Date Updated']),
      author: raw_claim['Author']['name'],
      author_link: raw_claim['Author']['link'],
      claim_headline: raw_claim['Headline'],
      claim_body: (begin
                     raw_claim['Docs'][0]['content']
                   rescue StandardError
                     nil
                   end),
      claim_result: nil,
      claim_result_score: nil,
      claim_url: raw_claim['Post URL'],
      raw_claim: raw_claim
    }
  end
end
