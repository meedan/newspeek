# frozen_string_literal: true

describe API do
  describe 'class' do
    it 'has a load balancer endpoint' do
      expect(described_class.pong).to(eq({pong: true}))
    end

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
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything()).and_return({"took"=>21, "timed_out"=>false, "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0}, "hits"=>{"total"=>14055, "max_score"=>2.1063054, "hits"=>[{"_source" => {"created_at" => "2020-01-01", "_index"=>"claim_reviews", "_type"=>"claim_review", "id"=>"0f6a429f5a4e6d017b152665f9cdcadc"}}]}})
      expect(described_class.services.class).to(eq(Hash))
    end

    it 'lists subscriptions for a service' do
      Subscription.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      expect(described_class.get_subscriptions(service: 'blah')).to(eq(['http://blah.com/respond']))
    end

    it 'adds subscriptions for a service' do
      Subscription.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      expect(described_class.add_subscription(service: 'blah', url: 'http://blah.com/respond')).to(eq(['http://blah.com/respond']))
    end

    it 'removes subscriptions for a service' do
      Subscription.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      expect(described_class.remove_subscription(service: 'blah', url: 'http://blah.com/respond')).to(eq(['http://blah.com/respond']))
    end
  end
end
