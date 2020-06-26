# frozen_string_literal: true

class TheQuint < ReviewParser
  def hostname
    'https://www.thequint.com'
  end

  def fact_list_path(page = 1)
    "/news/webqoof/#{page}"
  end

  def get_claims_for_page(page = 1)
    JSON.parse(Nokogiri.parse(RestClient.get(hostname + fact_list_path(page))).search('script').find { |x| x.text.include?('app.render') }.text.split('app.render(')[1].split(");\n      });\n    ")[0])['args']['collection']['items']
  end

  def get_new_claims_for_page(page = 1)
    claims = get_claims_for_page(page)
    existing_urls = ClaimReview.existing_urls(claims.map { |claim| claim['url'] }.compact, self.class.service)
    claims.reject { |claim| existing_urls.include?(claim['url']) }
  end

  def get_claims
    page = 1
    raw_claims = get_new_claims_for_page(page)
    until finished_iterating?(raw_claims)
      page += 1
      raw_claims = get_new_claims_for_page(page)
    end
  end

  def author_from_raw_claim(raw_claim)
    begin
      raw_claim['authors'][0]['name']
    rescue StandardError
      nil
    end
  end

  def author_link_from_raw_claim(raw_claim)
    begin
      raw_claim['authors'][0]['avatar-url']
    rescue StandardError
      nil
    end
  end

  def claim_result_from_raw_claim(raw_claim)
    begin
      raw_claim['metadata']['story-attributes']['factcheck'].first
    rescue StandardError
      nil
    end
  end

  def claim_result_score_from_raw_claim(raw_claim)
    begin
      Integer(raw_claim['metadata']['story-attributes']['claimreviewrating'].first, 10)
    rescue StandardError
      nil
    end
  end


  def parse_raw_claim(raw_claim)
    {
      service_id: raw_claim['story-content-id'],
      created_at: Time.at(raw_claim['first-published-at'] / 1000.0),
      author: author_from_raw_claim(raw_claim),
      author_link: author_link_from_raw_claim(raw_claim),
      claim_headline: raw_claim['headline'],
      claim_body: Nokogiri.parse('<html>' + raw_claim['cards'].map { |x| x['story-elements'] }.flatten.map { |x| x['text'] }.join('') + '</html>').text,
      claim_result: claim_result_from_raw_claim(raw_claim),
      claim_result_score: claim_result_score_from_raw_claim(raw_claim),
      claim_url: raw_claim['url'],
      raw_claim: raw_claim
    }
  end
end
