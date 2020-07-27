class NotifySubscriber
  include Sidekiq::Worker
  def perform(service, claim_review)
    Subscription.notify_subscribers(service, claim_review)
  end
end
