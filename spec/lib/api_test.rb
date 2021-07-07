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

    it 'gets the export file' do
      end_time = Time.parse(Time.now.strftime("%Y-%m-%d"))
      time_clause = ElasticSearchQuery.start_end_date_range_query('created_at', (end_time-60*60*24).to_s, end_time.to_s)
      end_time -= 60*60*24
      time_clause2 = ElasticSearchQuery.start_end_date_range_query('created_at', (end_time-60*60*24).to_s, end_time.to_s)
      ClaimReview.stub(:get_hits).with({size: 10000, body: {query: {bool: {filter: time_clause}}}}).and_return([{ '_source' => { 'claim_review_url' => 1 } }])
      ClaimReview.stub(:get_hits).with({size: 10000, body: {query: {bool: {filter: time_clause2}}}}).and_return([])
      filename = API.export_to_file((end_time).to_s, (end_time+60*60*24).to_s, "blah.json")
      result = File.read(filename).split("\n").collect{|x| JSON.parse(x)}
      expect(result).to(eq([{ '_source' => { 'claim_review_url' => 1 } }]))
    end
  end
end
