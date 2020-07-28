class Subscription
  def self.keyname(service)
    "claim_review_webhooks_#{service}"
  end

  def self.add_subscription(services, urls)
    [services].flatten.collect do |service|
      [urls].flatten.collect do |url|
        REDIS_CLIENT.sadd(self.keyname(service), url)
      end
    end.flatten
  end
  
  def self.remove_subscription(services, urls)
    [services].flatten.collect do |service|
      [urls].flatten.collect do |url|
        REDIS_CLIENT.srem(self.keyname(service), url)
      end
    end.flatten
  end

  def self.get_subscriptions(services)
    [services].flatten.collect do |service|
      REDIS_CLIENT.smembers(self.keyname(service)) || []
    end.flatten
  end

  def self.notify_subscribers(services, claim_review)
    self.get_subscriptions(services).each do |webhook_url|
      RestClient.post(webhook_url, {claim_review: claim_review}.to_json)
    end
  end
end