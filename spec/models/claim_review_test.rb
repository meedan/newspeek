# frozen_string_literal: true

describe ClaimReview do
  describe 'instance' do
    it 'responds to to_hash' do
      expect(ClaimReview.new({}).to_hash).to(eq({}))
    end
  end
  describe 'class' do
    it 'returns get_count_for_service with Hash version in ES 7' do
      described_class.stub(:get_hits).with(ClaimReview.service_query("blah"), "total").and_return({"value" => 10})
      expect(ClaimReview.get_count_for_service("blah")).to(eq(10))
    end

    it 'returns get_count_for_service with Hash version in ES 6' do
      described_class.stub(:get_hits).with(ClaimReview.service_query("blah"), "total").and_return(10)
      expect(ClaimReview.get_count_for_service("blah")).to(eq(10))
    end
    it 'has mandatory fields' do
      expect(described_class.mandatory_fields).to(eq(%w[claim_review_headline claim_review_url created_at id]))
    end

    it 'fails validation on nil fields' do
      expect(described_class.validate_claim_review({})).to(eq(nil))
    end

    it 'validates MVP claim' do
      validated = described_class.validate_claim_review(QuietHashie[{ raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }])
      expect(validated).to(eq({"claim_review_headline"=>"wow", "claim_review_url"=>"http://example.com", "created_at"=>"2020-01-01T00:00:00Z", "id"=>"a4d3900c63395cbfef47eb3650427af8", "language" => nil}))
    end

    it 'logs errors on storage failure' do
      claim = QuietHashie[{ service: 'google', raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }]
      validated = described_class.validate_claim_review(QuietHashie[{ service: 'google', raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }])
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_raise(StandardError)
      expect(Error).to receive(:log).with(anything(), {validated_claim_review: validated})
      expect(described_class.save_claim_review(claim, 'google')).to(eq(nil))
    end

    it 'saves MVP claim' do
      claim = QuietHashie[{ claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01').strftime('%Y-%m-%dT%H:%M:%SZ'), id: 123 }]
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      response = described_class.save_claim_review(claim, 'google')
      expect(response.length).to(eq(24))
      expect(response.class).to(eq(String))
    end

    it 'expects repository instance' do
      expect(described_class.repository.class).to(eq(ClaimReviewRepository))
    end

    it 'expects client instance' do
      expect(described_class.client.class).to(eq(Elasticsearch::Transport::Client))
    end

    it 'expects non-empty get hits' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'claim_review_url' => 1 } }] } })
      expect(described_class.get_hits({})).to(eq([{ 'claim_review_url' => 1 }]))
    end

    it 'expects empty get hits' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.get_hits({})).to(eq([]))
    end

    it 'expects empty get hits' do
      Elasticsearch::Transport::Client.any_instance.stub(:delete_by_query).with(anything).and_return({"took"=>5, "timed_out"=>false, "total"=>0, "deleted"=>0, "batches"=>0, "version_conflicts"=>0, "noops"=>0, "retries"=>{"bulk"=>0, "search"=>0}, "throttled_millis"=>0, "requests_per_second"=>-1.0, "throttled_until_millis"=>0, "failures"=>[]})
      expect(described_class.delete_by_service("foo")).to(eq(0))
    end


    it 'expects non-empty extract_matches' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'claim_review_url' => 1 } }] } })
      expect(described_class.extract_matches([1], 'claim_review_url', 'google')).to(eq([1]))
    end

    it 'expects empty get extract_matches' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.extract_matches([1], 'claim_review_url', 'google')).to(eq([]))
    end

    it 'expects non-empty existing_ids' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'id' => 1 } }] } })
      expect(described_class.existing_ids([1], 'google')).to(eq([1]))
    end

    it 'expects empty get existing_ids' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.existing_ids([1], 'google')).to(eq([]))
    end

    it 'expects false response for params to should_save_claim_review' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.should_save_claim_review([1], 'google', false)).to(eq(true))
    end

    it 'expects true response for params to should_save_claim_review' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.should_save_claim_review([1], 'google', true)).to(eq(true))
    end

    it 'expects false response for params to should_save_claim_review' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{"_source" => {"id" => 1}}] } })
      expect(described_class.should_save_claim_review([1], 'google', false)).to(eq(false))
    end

    it 'expects true response for params to should_save_claim_review' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{"_source" => {"id" => 1}}] } })
      expect(described_class.should_save_claim_review([1], 'google', true)).to(eq(true))
    end

    it 'expects non-empty existing_urls' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'claim_review_url' => 1 } }] } })
      expect(described_class.existing_urls([1], 'google')).to(eq([1]))
    end

    it 'expects empty get existing_urls' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.existing_urls([1], 'google')).to(eq([]))
    end
  end

  it 'fails to store MVP claim' do
    claim_review = QuietHashie[{ raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'id' => 123 } }] } })
    ClaimReviewRepository.any_instance.stub(:save).with(claim_review.merge(service: 'google')).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
    expect(described_class.store_claim_review(claim_review, 'google', false)).to(eq(nil))
  end

  it 'stores MVP claim' do
    claim_review = QuietHashie[{ raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
    ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
    response = described_class.store_claim_review(claim_review, 'google', false)
    expect(response.length).to(eq(24))
    expect(response.class).to(eq(String))
  end

  it 'runs a search' do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'id' => 123, 'created_at' => Time.now.to_s, 'claim_review_url' => 1 } }] } })
    query = {search_query: '', service: 'nil', start_time: Time.now.to_s, end_time: Time.now.to_s, per_page: 20, offset: 0}
    expect(described_class.search(query)).to(eq([{ :@context => 'http://schema.org', :@type => 'ClaimReview', :datePublished => Time.now.strftime('%Y-%m-%d'), :identifier => 123, :url => 1, :author => { name: nil, url: nil }, :image => nil, :claimReviewed => nil, :text => nil, :reviewRating => { :@type => 'Rating', :ratingValue => nil, :bestRating => 1, :alternateName => nil } }]))
  end

  it 'runs an empty search' do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
    query = {search_query: '', service: 'nil', start_time: Time.now.to_s, end_time: Time.now.to_s, per_page: 20, offset: 0}
    expect(described_class.search(query)).to(eq([]))
  end

  it 'converts a claim review' do
    expect(
      described_class.convert_to_claim_review(
        QuietHashie[{ raw_claim_review: {}, claim_review_headline: 'wow', claim_review_url: 'http://example.com', created_at: Time.now.to_s, id: 123 }]
      )
    ).to(eq(
        { :@context => 'http://schema.org', :@type => 'ClaimReview', :datePublished => Time.now.strftime('%Y-%m-%d'), :identifier => 123, :url => 'http://example.com', :author => { name: nil, url: nil }, :image => nil, :claimReviewed => 'wow', :text => nil, :reviewRating => { :@type => 'Rating', :ratingValue => nil, :bestRating => 1, :alternateName => nil } }
      )
    )
  end
end
