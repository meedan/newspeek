# frozen_string_literal: true

describe API do
  describe 'class' do
    it 'has a claim review endpoint' do
      ClaimReview.stub(:search).with({:offset=>0, :per_page=>20}).and_return([])
      expect(described_class.claim_reviews({})).to(eq([]))
    end

    it 'has a nonempty claim review endpoint' do
      ClaimReview.stub(:search).with({:offset=>0, :per_page=>20}).and_return([{ bloop: 1 }])
      expect(described_class.claim_reviews({})).to(eq([{ bloop: 1 }]))
    end

    it 'has an about page' do
      expect(described_class.about.class).to(eq(Hash))
    end

    it 'lists available services' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"took"=>21, "timed_out"=>false, "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0}, "hits"=>{"total"=>14055, "max_score"=>2.1063054, "hits"=>[{"_index"=>"claim_reviews", "_type"=>"claim_review", "_id"=>"0f6a429f5a4e6d017b152665f9cdcadc"}]}})
      expect(described_class.services.class).to(eq(Hash))
    end
  end
end
