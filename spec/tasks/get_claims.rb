class GetClaims
  include Sidekiq::Worker
  def perform(service)
    ReviewParser.run(service)
  end
end