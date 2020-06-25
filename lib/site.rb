# frozen_string_literal: true

class Site < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  get '/claim_reviews.json' do
    return API.claim_reviews(params).to_json
  end

  get '/about' do
    return API.about.to_json
  end
end
