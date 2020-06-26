# frozen_string_literal: true

class Tattle < ReviewParser
  def self.dataset_path
    '../datasets/tattle_claims.json'
  end

  def get_claims(path = self.class.dataset_path)
    raw_set = JSON.parse(File.read(path)).sort_by { |c| c['Post URL'].to_s }.reverse
    raw_set.each_slice(100) do |claim_set|
      urls = claim_set.compact.collect { |claim| claim['Post URL'] }
      existing_urls = ClaimReview.existing_urls(urls, self.class.service)
      new_claims = claim_set.reject { |claim| existing_urls.include?(claim['Post URL']) }
      next if new_claims.empty?

      process_claims(new_claims.map { |raw_claim| parse_raw_claim(raw_claim) })
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
