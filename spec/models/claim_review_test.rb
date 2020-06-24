describe ClaimReview do
  describe "class" do
    it "has mandatory fields" do
      expect(ClaimReview.mandatory_fields).to eq(["claim_headline", "claim_url", "created_at", "service_id"])
    end

    it "fails validation on nil fields" do
      expect(ClaimReview.validate_claim({})).to eq(nil)
    end

    it "validates MVP claim" do
      validated = ClaimReview.validate_claim(Hashie::Mash[{_id: 1, raw_claim: {}, claim_headline: "wow", claim_url: "http://example.com", created_at: Time.parse("2020-01-01"), service_id: 123}])
      expect(validated).to eq({"claim_headline"=>"wow", "claim_url"=>"http://example.com", "created_at"=>"2020-01-01T00:00:00Z", "service_id"=>123})
    end

    it "saves MVP claim" do
      claim = Hashie::Mash[{claim_headline: "wow", claim_url: "http://example.com", created_at: Time.parse("2020-01-01").strftime("%Y-%m-%dT%H:%M:%SZ"), service_id: 123}]
      ClaimReviewRepository.any_instance.stub(:save).with(claim.merge(service: "google")).and_return({"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"vhV84XIBOGf2XeyOAD12", "_version"=>1, "result"=>"created", "_shards"=>{"total"=>2, "successful"=>1, "failed"=>0}, "_seq_no"=>130821, "_primary_term"=>2})
      expect(ClaimReview.save_claim(claim, "google")).to eq({"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"vhV84XIBOGf2XeyOAD12", "_version"=>1, "result"=>"created", "_shards"=>{"total"=>2, "successful"=>1, "failed"=>0}, "_seq_no"=>130821, "_primary_term"=>2})
    end

    it "expects repository instance" do
      expect(ClaimReview.repository.class).to eq(ClaimReviewRepository)
    end

    it "expects client instance" do
      expect(ClaimReview.client.class).to eq(Elasticsearch::Transport::Client)
    end

    it "expects non-empty get hits" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"claim_url" => 1}}]}})
      expect(ClaimReview.get_hits({})).to eq([{"claim_url"=>1}])
    end

    it "expects empty get hits" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
      expect(ClaimReview.get_hits({})).to eq([])
    end

    it "expects non-empty extract_matches" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"service" => "google", "claim_url" => 1}}]}})
      expect(ClaimReview.extract_matches([1], "claim_url", "google")).to eq([1])
    end

    it "expects empty get extract_matches" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
      expect(ClaimReview.extract_matches([1], "claim_url", "google")).to eq([])
    end

    it "expects non-empty existing_ids" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"service" => "google", "service_id" => 1}}]}})
      expect(ClaimReview.existing_ids([1], "google")).to eq([1])
    end

    it "expects empty get existing_ids" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
      expect(ClaimReview.existing_ids([1], "google")).to eq([])
    end

    it "expects non-empty existing_urls" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"service" => "google", "claim_url" => 1}}]}})
      expect(ClaimReview.existing_urls([1], "google")).to eq([1])
    end

    it "expects empty get existing_urls" do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
      expect(ClaimReview.existing_urls([1], "google")).to eq([])
    end
  end

  it "fails to store MVP claim" do
    claim = Hashie::Mash[{_id: 1, raw_claim: {}, claim_headline: "wow", claim_url: "http://example.com", created_at: Time.parse("2020-01-01"), service_id: 123}]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"service" => "google", "service_id" => 123}}]}})
    ClaimReviewRepository.any_instance.stub(:save).with(claim.merge(service: "google")).and_return({"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"vhV84XIBOGf2XeyOAD12", "_version"=>1, "result"=>"created", "_shards"=>{"total"=>2, "successful"=>1, "failed"=>0}, "_seq_no"=>130821, "_primary_term"=>2})
    expect(ClaimReview.store_claim(claim, "google")).to eq(nil)
  end

  it "stores MVP claim" do
    claim = Hashie::Mash[{_id: 1, raw_claim: {}, claim_headline: "wow", claim_url: "http://example.com", created_at: Time.parse("2020-01-01"), service_id: 123}]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
    ClaimReviewRepository.any_instance.stub(:save).with({"claim_headline"=>"wow", "claim_url"=>"http://example.com", "created_at"=>"2020-01-01T00:00:00Z", "service"=>"google", "service_id"=>123}).and_return({"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"vhV84XIBOGf2XeyOAD12", "_version"=>1, "result"=>"created", "_shards"=>{"total"=>2, "successful"=>1, "failed"=>0}, "_seq_no"=>130821, "_primary_term"=>2})
    expect(ClaimReview.store_claim(claim, "google")).to eq({"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"vhV84XIBOGf2XeyOAD12", "_version"=>1, "result"=>"created", "_shards"=>{"total"=>2, "successful"=>1, "failed"=>0}, "_seq_no"=>130821, "_primary_term"=>2})
  end

  it "runs a search" do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => [{"_source" => {"created_at" => Time.now.to_s, "claim_url" => 1}}]}})
    expect(ClaimReview.search("", "nil", Time.now.to_s, Time.now.to_s, 20, 0)).to eq([{:@context=>"http://schema.org", :@type=>"ClaimReview", :datePublished=>Time.now.strftime("%Y-%m-%d"), :url=>1, :author=>{:name=>nil, :url=>nil}, :claimReviewed=>nil, :text=>nil, :reviewRating=>{:@type=>"Rating", :ratingValue=>nil, :bestRating=>1, :alternateName=>nil}}])
  end

  it "runs an empty search" do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"hits" => {"hits" => []}})
    expect(ClaimReview.search("", "nil", Time.now.to_s, Time.now.to_s, 20, 0)).to eq([])
  end

  it "converts a claim review" do
    ClaimReview.convert_to_claim_review(Hashie::Mash[{_id: 1, raw_claim: {}, claim_headline: "wow", claim_url: "http://example.com", created_at: Time.now.to_s, service_id: 123}])
    {:@context=>"http://schema.org", :@type=>"ClaimReview", :datePublished=>"2020-06-23", :url=>"http://example.com", :author=>{:name=>nil, :url=>nil}, :claimReviewed=>"wow", :text=>nil, :reviewRating=>{:@type=>"Rating", :ratingValue=>nil, :bestRating=>1, :alternateName=>nil}}
  end
end