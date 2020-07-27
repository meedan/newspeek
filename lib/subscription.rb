class Subscription
  def self.keyname(service)
    "claim_review_webhooks_#{service}"
  end

  def self.add_subscription(service, url)
    REDIS_CLIENT.sadd(self.keyname(service), url)
  end
  
  def self.remove_subscription(service, url)
    REDIS_CLIENT.srem(self.keyname(service), url)
  end

  def self.get_subscriptions(service)
    REDIS_CLIENT.smembers(self.keyname(service)) || []
  end

  def self.notify_subscribers(service, claim_review)
    self.get_subscriptions(service).each do |webhook_url|
      RestClient.post(webhook_url, {claim_review: claim_review}.to_json)
    end
  end
end