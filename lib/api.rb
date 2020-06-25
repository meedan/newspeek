class API
  def self.claim_reviews(opts={})
    ClaimReview.search(
      opts[:query],
      opts[:service],
      opts[:created_at_start],
      opts[:created_at_end],
      opts[:page]||20,
      opts[:per_page]||0
    )
  end

  def self.about
    {
      live_urls: {
        "/claim_reviews.json": [
          {
            method: "GET",
            params: {
              query: "string (default none)",
              service: "string (default none)",
              created_at_start: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              created_at_end: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
              page: "integer (default 0)",
              per_page: "integer (default 20)"
            }
          }
        ]
      }
    }
  end
end