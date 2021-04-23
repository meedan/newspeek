# frozen_string_literal: true

# Parser for http://boomlive.in/ - does not follow standard Pagination scheme from PaginatedReviewClaims!
class BoomLive < ClaimReviewParser
  def hostname
    'http://boomlive.in/'
  end

  def service_key
    'boom_live_api_key'
  end

  def api_params
    { "s-id": Settings.get(service_key) }
  end

  def get_path(path)
    JSON.parse(
      RestClient.get(
        hostname + path,
        api_params
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
    existing_urls = get_existing_urls(stories.map { |s| s['url'] })
    Hash[stories.reject { |s| existing_urls.include?(s['url']) }.map { |s| [s['url'], s] }].values
  end

  def store_claim_reviews_for_category_id_and_page(category_id, page)
    process_claim_reviews(
      parse_raw_claim_reviews(
        get_new_stories_by_category(
          category_id, page
        )
      )
    )
  end

  def get_all_stories_by_category(category_id)
    page = 1
    stories = store_claim_reviews_for_category_id_and_page(category_id, page)
    until finished_iterating?(stories)
      page += 1
      stories = store_claim_reviews_for_category_id_and_page(category_id, page)
    end
  end

  def get_claim_reviews
    return false if service_key_is_needed?
    fact_categories.each do |_category_path, category_id|
      get_all_stories_by_category(category_id)
    end
  end

  def get_claim_result_for_raw_claim_review(raw_claim_review)
    found_text = Nokogiri.parse(
      get_url(raw_claim_review['url'])
    ).search('div.claim-review-block div.claim-value').find do |x|
      x.text.downcase.include?('fact check')
    end
    if found_text
      found_text.search('span.value').first.text
    end
  rescue StandardError => e
    Error.log(e)
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_result = get_claim_result_for_raw_claim_review(raw_claim_review)
    {
      id: raw_claim_review['newsId'].to_s,
      created_at: Time.parse(raw_claim_review['date_created']),
      author: raw_claim_review['source'],
      author_link: nil,
      claim_review_headline: raw_claim_review['heading'],
      claim_review_body: Nokogiri.parse('<html>' + raw_claim_review['story'] + '</html>').css('p > text()').collect(&:text).join("\n"),
      claim_review_image_url: raw_claim_review["mediaId"],
      claim_review_result: claim_result,
      claim_review_result_score: claim_result.to_s.downcase.include?('false') ? 0 : 1,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: raw_claim_review
    }
  end
end
