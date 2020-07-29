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
        "/claim_reviews.json": About.claim_reviews,
        "/services.json": About.services,
        "/subscribe.json": About.subscribe
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
