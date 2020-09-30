# frozen_string_literal: true

describe Site do
  include Rack::Test::Methods

  def app
    Site
  end

  describe 'endpoints' do
    it 'returns an empty GET claim_reviews response' do
      response = get "/ping"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)).to(eq({"pong" => true}))
    end

    it 'returns an empty GET claim_reviews response' do
      ClaimReview.stub(:search).with({:offset=>0, :per_page=>20}).and_return([])
      response = get "/claim_reviews"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)).to(eq([]))
    end

    it 'returns a non-empty GET claim_reviews response' do
      ClaimReview.stub(:search).with({:offset=>0, :per_page=>20}).and_return([{ bloop: 1 }])
      response = get "/claim_reviews"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)).to(eq([{ 'bloop' => 1 }]))
    end

    it 'returns an about page' do
      response = get "/about"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body).class).to(eq(Hash))
    end

    it 'returns a services page' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"took"=>21, "timed_out"=>false, "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0}, "hits"=>{"total"=>14055, "max_score"=>2.1063054, "hits"=>[{"_source" => {"created_at" => "2020-01-01", "_index"=>"claim_reviews", "_type"=>"claim_review", "id"=>"0f6a429f5a4e6d017b152665f9cdcadc"}}]}})
      response = get "/services"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body).class).to(eq(Hash))
    end

    it 'gets subscriptions' do
      response = get "/subscribe", "service=blah"
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body).class).to(eq(Array))
    end

    it 'adds subscriptions' do
      response = post "/subscribe", {service: 'blah', url: 'http://blah.com/respond'}.to_json
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)).to(eq(["http://blah.com/respond"]))
    end

    it 'removes subscriptions' do
      response = delete "/subscribe", {service: 'blah', url: 'http://blah.com/respond'}.to_json
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)).to(eq([]))
    end
  end
end
