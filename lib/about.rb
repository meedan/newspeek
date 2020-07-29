class About
  def self.claim_reviews
    [
      {
        method: 'GET',
        params: {
          query: 'string (default none)',
          service: 'string (default none)',
          start_time: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
          end_time: "time-parseable string (e.g. '2020-01-01' or 'Sept 20 2019', default none)",
          per_page: 'integer (default 20)',
          offset: 'integer (default 0)'
        }
      }
    ]
  end

  def self.services
    [
      {
        method: 'GET',
        params: {
        }
      }
    ]
  end
  
  def self.subscribe
    [
      {
        method: 'GET',
        params: self.subscribe_params(false)
      },
      {
        method: 'POST',
        params: self.subscribe_params
      },
      {
        method: 'DELETE',
        params: self.subscribe_params
      },
    ]
  end
  
  def self.subscribe_params(include_url=true)
    params = {
      service: 'string or list of strings (list all service strings via /services.json)',
    }
    params[:url] = '(url-safe) string or list of (url-safe) strings' if include_url
    params
  end
end