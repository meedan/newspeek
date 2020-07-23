# frozen_string_literal: true

class API
  def self.claim_reviews(opts = {})
    opts[:per_page] ||= 20
    opts[:offset] ||= 0
    ClaimReview.search(
      opts
    )
  end

  def self.about
    {
      live_urls: {
        "/claim_reviews.json": [
          {
            method: 'GET',
            params: {
              query: 'string (default none)',
              service: 'string (default none)',
              created_at_start: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              created_at_end: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              per_page: 'integer (default 20)',
              offset: 'integer (default 0)'
            }
          }
        ]
      }
    }
  end

  def self.services
    {
      services: ClaimReviewParser.parsers.collect{|k,v| 
        {service: k, count: ClaimReview.get_count_for_service(k), earliest: ClaimReview.get_earliest_date_for_service(k), latest: ClaimReview.get_latest_date_for_service(k)}
      }
    }
  end
end
