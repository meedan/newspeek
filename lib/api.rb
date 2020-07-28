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
              start_time: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              end_time: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              per_page: 'integer (default 20)',
              offset: 'integer (default 0)'
            }
          }
        ],
        "/services.json": [
          {
            method: 'GET',
            params: {
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

  def self.get_subscriptions(params)
    Subscription.get_subscriptions(params[:service])
  end

  def self.add_subscription(params)
    Subscription.add_subscription(params[:service], params[:url])
    Subscription.get_subscriptions(params[:service])
  end

  def self.remove_subscription(params)
    Subscription.remove_subscription(params[:service], params[:url])
    Subscription.get_subscriptions(params[:service])
  end
end
