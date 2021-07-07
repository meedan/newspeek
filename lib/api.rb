# frozen_string_literal: true

class API
  def self.pong
    {pong: true}
  end

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
        "/about": About.about,
        "/claim_reviews": About.claim_reviews,
        "/services": About.services,
        "/subscribe": About.subscribe
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
    Subscription.add_subscription(params[:service], params[:url], params[:language])
    Subscription.get_subscriptions(params[:service])
  end

  def self.remove_subscription(params)
    Subscription.remove_subscription(params[:service], params[:url])
    Subscription.get_subscriptions(params[:service])
  end

  def self.export_to_file(start_time, end_time, filename=nil)
    filename ||= "claim_review_exports_#{Time.parse(start_time).strftime("%Y-%m-%d")}_#{Time.parse(end_time).strftime("%Y-%m-%d")}.json"
    ClaimReview.export_to_file(start_time, end_time, filename)
  end
end
