# frozen_string_literal: true

class Site < Sinatra::Base
  use Airbrake::Rack::Middleware unless Settings.blank?('airbrake_api_host')
  configure :production, :local, :test do
    enable :logging
  end

  get "/ping" do
    return API.pong.to_json
  end

  get '/claim_reviews' do
    return API.claim_reviews(params).to_json
  end

  get '/about' do
    return API.about.to_json
  end

  get '/services' do
    return API.services.to_json
  end

  get '/subscribe' do
    return API.get_subscriptions(params).to_json
  end

  post '/subscribe' do
    return API.add_subscription(QuietHashie[JSON.parse(request.body.read)]).to_json
  end

  delete '/subscribe' do
    return API.remove_subscription(QuietHashie[JSON.parse(request.body.read)]).to_json
  end
end
