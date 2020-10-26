# frozen_string_literal: true

class RunClaimReviewParser
  include Sidekiq::Worker
  def perform(service, cursor_back_to_date = nil, overwrite_existing_claims=false)
    cursor_back_to_date = Time.parse(cursor_back_to_date) unless cursor_back_to_date.nil?
    ClaimReviewParser.run(service, cursor_back_to_date, overwrite_existing_claims)
    RunClaimReviewParser.perform_in(Settings.task_interevent_time, service)
  end
end
