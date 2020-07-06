# frozen_string_literal: true

class TheQuint < ReviewParser
  def hostname
    'https://www.thequint.com'
  end

  def fact_list_path(page = 1, limit = 100)
    "/api/v1/collections/webqoof?item-type=story&offset=#{(page - 1) * limit}&limit=#{limit}"
  end

  def get_claims_for_page(page = 1)
    JSON.parse(RestClient.get(hostname + fact_list_path(page)))['items']
  end

  def get_new_claims_for_page(page = 1)
    claims = parse_raw_claims(get_claims_for_page(page))
    existing_urls = get_existing_urls(claims.map { |claim| claim['url'] }.compact)
    process_claims(claims.reject { |claim| existing_urls.include?(claim['url']) })
  end

  def get_claims
    page = 1
    raw_claims = get_new_claims_for_page(page)
    until finished_iterating?(raw_claims)
      page += 1
      raw_claims = get_new_claims_for_page(page)
    end
  end

  def created_at_from_raw_claim(raw_claim)
    Time.at(raw_claim['story']['published-at'] / 1000.0)
  rescue StandardError
    nil
  end

  def author_from_raw_claim(raw_claim)
    raw_claim['story']['authors'][0]['name']
  rescue StandardError
    nil
  end

  def author_link_from_raw_claim(raw_claim)
    raw_claim['story']['authors'][0]['avatar-url']
  rescue StandardError
    nil
  end

  def claim_result_from_raw_claim(raw_claim)
    raw_claim['story']['metadata']['story-attributes']['factcheck'].first
  rescue StandardError
    nil
  end

  def claim_result_score_from_raw_claim(raw_claim)
    Integer(raw_claim['story']['metadata']['story-attributes']['claimreviewrating'].first, 10)
  rescue StandardError
    nil
  end

  def claim_headline_from_raw_claim(raw_claim)
    raw_claim['story']['headline']
  rescue StandardError
    nil
  end

  def claim_body_from_raw_claim(raw_claim)
    raw_claim['story']['seo']['meta-description']
  rescue StandardError
    nil
  end

  def claim_url_from_raw_claim(raw_claim)
    raw_claim['story']['url']
  rescue StandardError
    nil
  end

  def parse_raw_claim(raw_claim)
    # delete unnecessary key that flags Hashie key-name warnings later
    raw_claim["story"].delete("cards")
    {
      id: Digest::MD5.hexdigest(raw_claim['id']),
      created_at: created_at_from_raw_claim(raw_claim),
      author: author_from_raw_claim(raw_claim),
      author_link: author_link_from_raw_claim(raw_claim),
      claim_headline: claim_headline_from_raw_claim(raw_claim),
      claim_body: claim_body_from_raw_claim(raw_claim),
      claim_result: claim_result_from_raw_claim(raw_claim),
      claim_result_score: claim_result_score_from_raw_claim(raw_claim),
      claim_url: claim_url_from_raw_claim(raw_claim),
      raw_claim: raw_claim
    }
  end
end
