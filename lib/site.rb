# frozen_string_literal: true

class Site < Sinatra::Base
  use Airbrake::Rack::Middleware unless Settings.blank?('airbrake_api_host')
  configure :production, :development do
    enable :logging
  end

  get '/claim_reviews.json' do
    return API.claim_reviews(params).to_json
  end

  get '/about' do
    return API.about.to_json
  end

  get '/services' do
    return API.services.to_json
  end

  get '/subscribe.json' do
    return API.get_subscriptions(params).to_json
  end

  post '/subscribe.json' do
    return API.add_subscription(Hashie::Mash[JSON.parse(request.body.read)]).to_json
  end

  delete '/subscribe.json' do
    return API.remove_subscription(Hashie::Mash[JSON.parse(request.body.read)]).to_json
  end
end
