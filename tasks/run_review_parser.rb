# frozen_string_literal: true

class RunReviewParser
  include Sidekiq::Worker
  def perform(service)
    ReviewParser.run(service)
    RunReviewParser.perform_async(service)
  end
end
