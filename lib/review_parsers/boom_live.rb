# frozen_string_literal: true

class BoomLive < ReviewParser
  def hostname
    'http://boomlive.in/'
  end

  def get_path(path)
    JSON.parse(
      RestClient.get(
        hostname + path,
        { "s-id": SETTINGS['boom_live_api_key'] }
      )
    )
  end

  def fact_categories
    {
      "/fact-file": 15,
      "/factcheck": 16,
      "/fake-news": 17,
      "/fast-check": 18
    }
  end

  def get_stories_by_category(category_id, page = 1, count = 20)
    get_path("/dev/h-api/news?catId=#{category_id}&startIndex=#{(page - 1) * count}&count=#{count}")
  end

  def get_new_stories_by_category(category_id, page)
    stories = get_stories_by_category(category_id, page)['news']
    existing_urls = ClaimReview.existing_urls(stories.map { |s| s['url'] }, self.class.service)
    Hash[stories.reject { |s| existing_urls.include?(s['url']) }.map { |s| [s['url'], s] }].values
  end

  def store_claims_for_category_id_and_page(category_id, page)
    process_claims(
      get_new_stories_by_category(
        category_id, page
      )
    )
  end

  def get_all_stories_by_category(category_id)
    page = 1
    stories = store_claims_for_category_id_and_page(category_id, page)
    until finished_iterating?(processed_claims)
      page += 1
      stories = store_claims_for_category_id_and_page(category_id, page)
    end
  end

  def get_claims
    fact_categories.each do |_category_path, category_id|
      get_all_stories_by_category(category_id) do |category_stories|
        parse_raw_claims(category_stories.values)
      end
    end
  end

  def get_claim_result_for_raw_claim(raw_claim)
    Nokogiri.parse(
      RestClient.get(raw_claim['url'])
    ).search('div.claim-review-block div.claim-value').find do |x|
      x.text.downcase.include?('fact check')
    end.search('span.value').first.text
  rescue StandardError
    nil
  end

  def parse_raw_claim(raw_claim)
    claim_result = get_claim_result_for_raw_claim(raw_claim)
    {
      service_id: raw_claim['newsId'],
      created_at: Time.parse(raw_claim['date_created']),
      author: raw_claim['source'],
      author_link: nil,
      claim_headline: raw_claim['heading'],
      claim_body: Nokogiri.parse('<html>' + raw_claim['story'] + '</html>').text,
      claim_result: claim_result,
      claim_result_score: claim_result.to_s.downcase.include?('false') ? 0 : 1,
      claim_url: raw_claim['url'],
      raw_claim: raw_claim
    }
  end
end
