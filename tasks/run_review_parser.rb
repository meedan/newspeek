# frozen_string_literal: true

class RunReviewParser
  include Sidekiq::Worker
  def perform(service, cursor_back_to_date = nil)
    cursor_back_to_date = Time.parse(cursor_back_to_date) unless cursor_back_to_date.nil?
    ReviewParser.run(service, cursor_back_to_date)
    RunReviewParser.perform_in(60 * 60, service)
  end
end
